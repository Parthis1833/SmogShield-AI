import asyncio
import copy
import logging
import math
import os
import time
from datetime import datetime, timedelta, timezone
from typing import Any, Optional, Protocol

import httpx


logger = logging.getLogger(__name__)
OPENAQ_BASE_URL = "https://api.openaq.org/v3"


def _configured_minutes(name: str, default: int) -> int:
    try:
        value = int(os.getenv(name, str(default)))
        if value > 0:
            return value
    except ValueError:
        pass
    logger.warning("Invalid %s setting; using the default.", name)
    return default


SUPPORTED_PARAMETERS = {
    "pm25": "pm25",
    "pm2.5": "pm25",
    "pm10": "pm10",
    "no2": "no2",
    "nitrogendioxide": "no2",
    "so2": "so2",
    "sulfurdioxide": "so2",
    "o3": "o3",
    "ozone": "o3",
    "co": "co",
    "carbonmonoxide": "co",
}
DISPLAY_NAMES = {
    "pm25": "PM2.5",
    "pm10": "PM10",
    "no2": "NO2",
    "so2": "SO2",
    "o3": "O3",
    "co": "CO",
}
FRESHNESS_FRESH_MINUTES = _configured_minutes("AIR_QUALITY_FRESH_MINUTES", 60)
FRESHNESS_DELAYED_MINUTES = max(
    FRESHNESS_FRESH_MINUTES,
    _configured_minutes("AIR_QUALITY_DELAYED_MINUTES", 360),
)
MAX_MEASUREMENT_AGE_MINUTES = max(
    FRESHNESS_DELAYED_MINUTES,
    _configured_minutes("AIR_QUALITY_MAX_AGE_MINUTES", 1440),
)
MAX_MEASUREMENT_AGE = timedelta(minutes=MAX_MEASUREMENT_AGE_MINUTES)
CACHE_TTL_SECONDS = 600
SEARCH_RADII_METERS = (5000, 10000, 15000, 20000, 25000)
MAX_SEARCH_RADIUS_METERS = 30000
OPENAQ_MAX_RADIUS_METERS = 25000
THIRTY_KM_SEARCH_OFFSET_METERS = 6000
THIRTY_KM_SEARCH_BEARINGS = tuple(range(0, 360, 45))
MAX_LATEST_REQUESTS = 100


class AirQualityProvider(Protocol):
    async def nearby(self, latitude: float, longitude: float) -> dict[str, Any]:
        ...


class OpenAQError(Exception):
    def __init__(
        self,
        message: str,
        status_code: int = 502,
        retry_after: Optional[str] = None,
    ):
        super().__init__(message)
        self.status_code = status_code
        self.retry_after = retry_after


class OpenAQNotConfigured(OpenAQError):
    def __init__(self):
        super().__init__("Live air-quality monitoring is not configured.", 503)


class SecondaryProvider:
    """Adapter for a configured endpoint that returns normalized station data."""

    def __init__(
        self,
        endpoint: Optional[str] = None,
        api_key: Optional[str] = None,
        client: Optional[httpx.AsyncClient] = None,
    ):
        self.endpoint = (endpoint or os.getenv("SECONDARY_AIR_QUALITY_URL", "")).strip()
        self.api_key = (
            api_key or os.getenv("SECONDARY_AIR_QUALITY_API_KEY", "")
        ).strip()
        self._client = client

    @property
    def is_configured(self) -> bool:
        return bool(self.endpoint)

    async def nearby(self, latitude: float, longitude: float) -> dict[str, Any]:
        if not self.is_configured:
            raise OpenAQError("No secondary air-quality provider is configured.", 503)
        try:
            if self._client is not None:
                response = await self._client.get(
                    self.endpoint,
                    params={"lat": latitude, "lon": longitude},
                    headers=(
                        {"X-API-Key": self.api_key, "Accept": "application/json"}
                        if self.api_key
                        else {"Accept": "application/json"}
                    ),
                )
            else:
                async with httpx.AsyncClient(timeout=12) as client:
                    response = await client.get(
                        self.endpoint,
                        params={"lat": latitude, "lon": longitude},
                        headers=(
                            {"X-API-Key": self.api_key, "Accept": "application/json"}
                            if self.api_key
                            else {"Accept": "application/json"}
                        ),
                    )
        except httpx.TimeoutException as error:
            raise OpenAQError("Secondary air-quality provider timed out.", 504) from error
        except httpx.RequestError as error:
            raise OpenAQError(
                "Unable to reach the secondary air-quality provider.", 502
            ) from error
        if response.status_code == 429:
            raise OpenAQError(
                "Secondary air-quality provider rate limit reached.",
                503,
                response.headers.get("Retry-After"),
            )
        if response.status_code >= 400:
            logger.warning(
                "Secondary air-quality provider returned HTTP %s.",
                response.status_code,
            )
            raise OpenAQError(
                "Secondary air-quality provider returned an error.", 503
            )
        try:
            result = response.json()
        except ValueError as error:
            raise OpenAQError(
                "Secondary air-quality provider returned invalid JSON."
            ) from error
        return OpenAQProvider._normalize_secondary_response(
            result, latitude, longitude
        )


class CachedDataProvider:
    def __init__(self):
        self._entries: dict[str, tuple[float, dict[str, Any]]] = {}
        self._lock = asyncio.Lock()

    async def store(self, key: str, result: dict[str, Any]) -> None:
        async with self._lock:
            self._entries[key] = (time.monotonic(), copy.deepcopy(result))

    async def get(
        self, key: str, *, fresh_only: bool = False
    ) -> Optional[dict[str, Any]]:
        async with self._lock:
            entry = self._entries.get(key)
            if entry is None:
                return None
            created_at, result = entry
            cache_age = time.monotonic() - created_at
            if fresh_only and cache_age >= CACHE_TTL_SECONDS:
                return None
            cached = self._mark_cached(result, cache_age)
            if cached is None:
                self._entries.pop(key, None)
                return None
            return cached

    @staticmethod
    def _mark_cached(
        result: dict[str, Any], age_seconds: float
    ) -> Optional[dict[str, Any]]:
        cached = copy.deepcopy(result)
        now = datetime.now(timezone.utc)
        pollutants = cached.get("pollutants")
        if not isinstance(pollutants, dict):
            return None
        ages = []
        valid_timestamps = []
        for pollutant in pollutants.values():
            if not isinstance(pollutant, dict):
                continue
            timestamp = OpenAQProvider._measurement_time(
                {"datetime": pollutant.get("observed_at")}
            )
            value = pollutant.get("value")
            unit = pollutant.get("unit")
            age_minutes = (
                (now - timestamp).total_seconds() / 60 if timestamp is not None else None
            )
            if (
                timestamp is None
                or age_minutes is None
                or age_minutes < -5
                or age_minutes > MAX_MEASUREMENT_AGE_MINUTES
                or not isinstance(value, (int, float))
                or not math.isfinite(value)
                or value < 0
                or not isinstance(unit, str)
                or not unit.strip()
            ):
                pollutant.update(value=None, unit=None, observed_at=None)
                continue
            ages.append(max(age_minutes, 0))
            valid_timestamps.append(timestamp)
        if not ages:
            return None
        cached["observed_at"] = max(valid_timestamps).isoformat()
        cached["freshest_age_minutes"] = min(ages)
        cached["freshness"] = OpenAQProvider._freshness_label(min(ages))
        cached["is_cached"] = True
        cached["cache_age_seconds"] = round(age_seconds, 1)
        return cached


class OpenAQProvider:
    def __init__(self, client: Optional[httpx.AsyncClient] = None):
        self._client = client

    async def nearby(self, latitude: float, longitude: float) -> dict[str, Any]:
        return await self._search_radii(latitude, longitude)

    async def _search_radii(self, latitude: float, longitude: float) -> dict[str, Any]:
        seen_location_ids: set[str] = set()
        for radius_meters in SEARCH_RADII_METERS:
            locations = await self._locations_in_radius(
                latitude, longitude, radius_meters, seen_location_ids
            )
            response = await self._select_station(
                locations, latitude=latitude, longitude=longitude
            )
            if response["found"]:
                response.update(
                    requested_location={
                        "latitude": latitude,
                        "longitude": longitude,
                    },
                    source="OpenAQ",
                    data_status=(
                        "nearest_station"
                        if radius_meters == SEARCH_RADII_METERS[0]
                        else f"nearest_station_fallback_{radius_meters // 1000}km"
                    ),
                    search_radius_km=radius_meters // 1000,
                    is_cached=False,
                    cache_age_seconds=0.0,
                    provider_error=None,
                )
                return response

        thirty_km_candidates = []
        for bearing in THIRTY_KM_SEARCH_BEARINGS:
            offset_latitude, offset_longitude = self._offset_coordinates(
                latitude,
                longitude,
                THIRTY_KM_SEARCH_OFFSET_METERS,
                bearing,
            )
            locations = await self._locations_in_radius(
                offset_latitude,
                offset_longitude,
                OPENAQ_MAX_RADIUS_METERS,
                seen_location_ids,
                requested_latitude=latitude,
                requested_longitude=longitude,
                max_distance_meters=MAX_SEARCH_RADIUS_METERS,
            )
            thirty_km_candidates.extend(locations)
        response = await self._select_station(
            thirty_km_candidates, latitude=latitude, longitude=longitude
        )
        if response["found"]:
            response.update(
                requested_location={"latitude": latitude, "longitude": longitude},
                source="OpenAQ",
                data_status="nearest_station_fallback_30km",
                search_radius_km=30,
                is_cached=False,
                cache_age_seconds=0.0,
                provider_error=None,
            )
            return response
        result = self._not_found()
        result.update(
            requested_location={"latitude": latitude, "longitude": longitude},
            source="OpenAQ",
            data_status="no_station",
            search_radius_km=MAX_SEARCH_RADIUS_METERS // 1000,
            is_cached=False,
            cache_age_seconds=0.0,
            provider_error=None,
        )
        return result

    async def _locations_in_radius(
        self,
        latitude: float,
        longitude: float,
        radius_meters: int,
        seen_location_ids: set[str],
        *,
        requested_latitude: Optional[float] = None,
        requested_longitude: Optional[float] = None,
        max_distance_meters: Optional[int] = None,
    ) -> list[dict[str, Any]]:
        locations = await self._locations(
            coordinates=f"{latitude},{longitude}",
            radius=min(radius_meters, OPENAQ_MAX_RADIUS_METERS),
            limit=100,
        )
        original_latitude = (
            latitude if requested_latitude is None else requested_latitude
        )
        original_longitude = (
            longitude if requested_longitude is None else requested_longitude
        )
        maximum_distance_km = (
            radius_meters / 1000
            if max_distance_meters is None
            else max_distance_meters / 1000
        )
        new_locations = []
        for location in locations:
            location_id = location.get("id")
            if location_id is None or str(location_id) in seen_location_ids:
                continue
            distance_km = self._distance_km(
                location, original_latitude, original_longitude
            )
            if not math.isfinite(distance_km) or distance_km > maximum_distance_km:
                continue
            seen_location_ids.add(str(location_id))
            new_locations.append(location)
        return new_locations

    @staticmethod
    def _offset_coordinates(
        latitude: float, longitude: float, distance_meters: int, bearing_degrees: int
    ) -> tuple[float, float]:
        earth_radius_meters = 6_371_008.8
        angular_distance = distance_meters / earth_radius_meters
        bearing = math.radians(bearing_degrees)
        latitude_radians = math.radians(latitude)
        longitude_radians = math.radians(longitude)
        offset_latitude = math.asin(
            math.sin(latitude_radians) * math.cos(angular_distance)
            + math.cos(latitude_radians)
            * math.sin(angular_distance)
            * math.cos(bearing)
        )
        offset_longitude = longitude_radians + math.atan2(
            math.sin(bearing)
            * math.sin(angular_distance)
            * math.cos(latitude_radians),
            math.cos(angular_distance)
            - math.sin(latitude_radians) * math.sin(offset_latitude),
        )
        return math.degrees(offset_latitude), (
            math.degrees(offset_longitude) + 540
        ) % 360 - 180

    async def search(self, query: str) -> dict[str, Any]:
        normalized_query = " ".join(query.split())
        locations = await self._locations(name=normalized_query, limit=100)
        response = await self._select_station(locations)
        response.update(
            requested_location=None,
            source="OpenAQ",
            data_status="manual_search" if response["found"] else "no_station",
            search_radius_km=None,
            is_cached=False,
            cache_age_seconds=0.0,
            provider_error=None,
        )
        return response

    async def _locations(self, **params: Any) -> list[dict[str, Any]]:
        payload = await self._get_json("/locations", params)
        results = payload.get("results")
        if not isinstance(results, list):
            raise OpenAQError("OpenAQ returned an invalid station list.")
        return [item for item in results if isinstance(item, dict)]

    async def _select_station(
        self,
        locations: list[dict[str, Any]],
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
    ) -> dict[str, Any]:
        candidates = [
            location
            for location in locations
            if any(
                self._pollutant_name(sensor) is not None
                for sensor in self._sensor_ids(location).values()
            )
        ]
        if latitude is not None and longitude is not None:
            candidates.sort(
                key=lambda location: self._distance_km(
                    location, latitude, longitude
                )
            )
        candidates = candidates[:MAX_LATEST_REQUESTS]
        if not candidates:
            return self._not_found()

        semaphore = asyncio.Semaphore(5)

        async def inspect(location: dict[str, Any]) -> Optional[dict[str, Any]]:
            async with semaphore:
                try:
                    return await self._station_observation(
                        location, latitude, longitude
                    )
                except OpenAQError as error:
                    if error.status_code == 404:
                        return None
                    raise

        results = await asyncio.gather(
            *(inspect(location) for location in candidates),
            return_exceptions=True,
        )
        valid = [item for item in results if isinstance(item, dict)]
        failures = [item for item in results if isinstance(item, Exception)]
        authentication_failure = next(
            (
                item
                for item in failures
                if isinstance(item, OpenAQError)
                and item.status_code == 502
                and (
                    "authentication failed" in str(item).lower()
                    or "denied access" in str(item).lower()
                )
            ),
            None,
        )
        if authentication_failure is not None:
            raise authentication_failure
        if not valid:
            if failures:
                raise failures[0]
            return self._not_found()

        def rank(item: dict[str, Any]) -> tuple[float, ...]:
            return (
                item["distance_km"] if item["distance_km"] is not None else math.inf,
                item["freshest_age_minutes"],
            )

        return min(valid, key=rank)

    async def _station_observation(
        self,
        location: dict[str, Any],
        latitude: Optional[float],
        longitude: Optional[float],
    ) -> Optional[dict[str, Any]]:
        location_id = location.get("id")
        if not isinstance(location_id, (int, str)):
            return None
        coordinates = location.get("coordinates") or {}
        station_latitude = coordinates.get("latitude")
        station_longitude = coordinates.get("longitude")
        if not (
            isinstance(station_latitude, (int, float))
            and not isinstance(station_latitude, bool)
            and isinstance(station_longitude, (int, float))
            and not isinstance(station_longitude, bool)
            and -90 <= station_latitude <= 90
            and -180 <= station_longitude <= 180
        ):
            return None

        payload = await self._get_json(f"/locations/{location_id}/latest")
        latest = payload.get("results")
        if not isinstance(latest, list):
            return None

        sensors = self._sensor_ids(location)
        now = datetime.now(timezone.utc)
        pollutants: dict[str, dict[str, Any]] = {
            key: {"value": None, "unit": None, "observed_at": None}
            for key in DISPLAY_NAMES
        }
        ages: list[float] = []
        for measurement in latest:
            if not isinstance(measurement, dict):
                continue
            sensor_id = self._measurement_sensor_id(measurement)
            sensor = sensors.get(str(sensor_id)) if sensor_id is not None else None
            if sensor is None:
                continue
            pollutant = self._pollutant_name(sensor)
            if pollutant is None:
                continue
            timestamp = self._measurement_time(measurement)
            if timestamp is None:
                continue
            age_minutes = (now - timestamp).total_seconds() / 60
            if age_minutes < -5 or timestamp < now - MAX_MEASUREMENT_AGE:
                continue
            raw_value = measurement.get("value")
            parameter = sensor.get("parameter")
            if not isinstance(parameter, dict):
                parameter = {}
            units = parameter.get("units")
            if (
                not isinstance(raw_value, (int, float))
                or isinstance(raw_value, bool)
                or not math.isfinite(raw_value)
                or raw_value < 0
                or not isinstance(units, str)
                or not units.strip()
            ):
                continue
            previous = pollutants[pollutant]["observed_at"]
            if previous is not None and timestamp <= previous:
                continue
            pollutants[pollutant] = {
                "value": float(raw_value),
                "unit": units,
                "observed_at": timestamp.isoformat(),
            }
            ages.append(max(age_minutes, 0))

        if not ages:
            return None

        freshest_age = min(ages)
        freshness = self._freshness_label(freshest_age)
        coordinates = location.get("coordinates") or {}
        station_lat = coordinates.get("latitude")
        station_lon = coordinates.get("longitude")
        distance = None
        if latitude is not None and longitude is not None:
            distance = self._haversine_km(
                latitude, longitude, float(station_lat), float(station_lon)
            )

        latest_timestamp = max(
            datetime.fromisoformat(value["observed_at"])
            for value in pollutants.values()
            if value["observed_at"] is not None
        )
        provider = location.get("provider") or location.get("owner") or {}
        return {
            "found": True,
            "location_id": str(location_id),
            "station_name": location.get("name") or "Monitoring station",
            "station_latitude": float(station_lat),
            "station_longitude": float(station_lon),
            "distance_km": round(distance, 2) if distance is not None else None,
            "provider": provider.get("name") if isinstance(provider, dict) else None,
            "observed_at": latest_timestamp.isoformat(),
            "freshness": freshness,
            "freshest_age_minutes": freshest_age,
            "pollutants": pollutants,
        }

    @staticmethod
    def _freshness_label(age_minutes: float) -> str:
        if age_minutes <= FRESHNESS_FRESH_MINUTES:
            return "Fresh"
        if age_minutes <= FRESHNESS_DELAYED_MINUTES:
            return "Delayed"
        return "Stale"

    @classmethod
    def _normalize_secondary_response(
        cls, payload: Any, latitude: float, longitude: float
    ) -> dict[str, Any]:
        if not isinstance(payload, dict):
            raise OpenAQError("Secondary provider returned an invalid response.")
        data = payload.get("data") if isinstance(payload.get("data"), dict) else payload
        station = data.get("station")
        raw_measurements = data.get("measurements")
        if not isinstance(station, dict) or not isinstance(raw_measurements, dict):
            raise OpenAQError(
                "Secondary provider must return normalized station and measurements."
            )
        station_latitude = station.get("latitude")
        station_longitude = station.get("longitude")
        if not (
            isinstance(station_latitude, (int, float))
            and math.isfinite(station_latitude)
            and not isinstance(station_latitude, bool)
            and -90 <= station_latitude <= 90
            and isinstance(station_longitude, (int, float))
            and not isinstance(station_longitude, bool)
            and math.isfinite(station_longitude)
            and -180 <= station_longitude <= 180
            and station.get("id") is not None
        ):
            raise OpenAQError("Secondary provider returned invalid station metadata.")

        pollutants: dict[str, dict[str, Any]] = {
            key: {"value": None, "unit": None, "observed_at": None}
            for key in DISPLAY_NAMES
        }
        ages = []
        now = datetime.now(timezone.utc)
        for key in DISPLAY_NAMES:
            observation = raw_measurements.get(key)
            if not isinstance(observation, dict):
                continue
            value = observation.get("value")
            unit = observation.get("unit")
            timestamp = cls._measurement_time(
                {"datetime": observation.get("observed_at")}
            )
            if (
                not isinstance(value, (int, float))
                or isinstance(value, bool)
                or not math.isfinite(value)
                or value < 0
                or not isinstance(unit, str)
                or not unit.strip()
                or timestamp is None
            ):
                continue
            age_minutes = (now - timestamp).total_seconds() / 60
            if age_minutes < -5 or age_minutes > MAX_MEASUREMENT_AGE_MINUTES:
                continue
            pollutants[key] = {
                "value": float(value),
                "unit": unit,
                "observed_at": timestamp.isoformat(),
            }
            ages.append(max(age_minutes, 0))
        if not ages:
            return cls._not_found() | {
                "requested_location": {"latitude": latitude, "longitude": longitude},
                "source": "Secondary",
                "data_status": "no_station",
                "search_radius_km": None,
                "is_cached": False,
                "cache_age_seconds": 0.0,
                "provider_error": None,
            }

        distance_km = cls._haversine_km(
            latitude,
            longitude,
            float(station_latitude),
            float(station_longitude),
        )
        freshest_age = min(ages)
        observed_at = max(
            value["observed_at"]
            for value in pollutants.values()
            if value["observed_at"] is not None
        )
        station_name = station.get("name") or "Monitoring station"
        result = {
            "found": True,
            "location_id": str(station["id"]),
            "station_name": station_name,
            "station_latitude": float(station_latitude),
            "station_longitude": float(station_longitude),
            "distance_km": round(distance_km, 2),
            "provider": payload.get("provider"),
            "observed_at": observed_at,
            "freshness": cls._freshness_label(freshest_age),
            "freshest_age_minutes": freshest_age,
            "pollutants": pollutants,
            "requested_location": {"latitude": latitude, "longitude": longitude},
            "source": str(payload.get("source") or "Secondary"),
            "data_status": "secondary_provider",
            "search_radius_km": None,
            "is_cached": False,
            "cache_age_seconds": 0.0,
            "provider_error": None,
        }
        return result

    @staticmethod
    def _sensor_ids(location: dict[str, Any]) -> dict[str, dict[str, Any]]:
        sensors = location.get("sensors")
        if not isinstance(sensors, list):
            return {}
        result = {}
        for sensor in sensors:
            if isinstance(sensor, dict) and sensor.get("id") is not None:
                result[str(sensor["id"])] = sensor
        return result

    @staticmethod
    def _measurement_sensor_id(measurement: dict[str, Any]) -> Any:
        for key in ("sensorsId", "sensorId", "sensor_id"):
            if measurement.get(key) is not None:
                return measurement[key]
        sensor = measurement.get("sensor")
        return sensor.get("id") if isinstance(sensor, dict) else None

    @staticmethod
    def _pollutant_name(sensor: dict[str, Any]) -> Optional[str]:
        parameter = sensor.get("parameter")
        if not isinstance(parameter, dict):
            parameter = {}
        raw_name = parameter.get("name") or parameter.get("displayName") or sensor.get("name")
        if not isinstance(raw_name, str):
            return None
        normalized = "".join(character for character in raw_name.casefold() if character.isalnum() or character == ".")
        return SUPPORTED_PARAMETERS.get(normalized)

    @staticmethod
    def _measurement_time(measurement: dict[str, Any]) -> Optional[datetime]:
        value = measurement.get("datetime")
        if isinstance(value, dict):
            value = value.get("utc") or value.get("local")
        if not isinstance(value, str):
            return None
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)

    @staticmethod
    def _distance_km(
        location: dict[str, Any], latitude: float, longitude: float
    ) -> float:
        coordinates = location.get("coordinates") or {}
        station_lat = coordinates.get("latitude")
        station_lon = coordinates.get("longitude")
        if (
            isinstance(station_lat, (int, float))
            and not isinstance(station_lat, bool)
            and isinstance(station_lon, (int, float))
            and not isinstance(station_lon, bool)
        ):
            return OpenAQProvider._haversine_km(
                latitude, longitude, float(station_lat), float(station_lon)
            )
        distance = location.get("distance")
        return float(distance) / 1000 if isinstance(distance, (int, float)) else math.inf

    @staticmethod
    def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        radius = 6371.0088
        phi1, phi2 = math.radians(lat1), math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)
        haversine = (
            math.sin(delta_phi / 2) ** 2
            + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
        )
        return 2 * radius * math.asin(math.sqrt(haversine))

    @staticmethod
    def _not_found() -> dict[str, Any]:
        return {
            "found": False,
            "location_id": None,
            "station_name": None,
            "station_latitude": None,
            "station_longitude": None,
            "distance_km": None,
            "provider": None,
            "observed_at": None,
            "freshness": None,
            "freshest_age_minutes": None,
            "no_data_reason": (
                "No monitoring station with valid recent pollutant measurements "
                "was found."
            ),
            "pollutants": {
                key: {"value": None, "unit": None, "observed_at": None}
                for key in DISPLAY_NAMES
            },
        }

    async def _get_json(
        self, path: str, params: Optional[dict[str, Any]] = None
    ) -> dict[str, Any]:
        api_key = os.getenv("OPENAQ_API_KEY", "").strip()
        if not api_key:
            raise OpenAQNotConfigured()

        try:
            if self._client is not None:
                response = await self._client.get(
                    f"{OPENAQ_BASE_URL}{path}",
                    params=params,
                    headers={"X-API-Key": api_key, "Accept": "application/json"},
                )
            else:
                async with httpx.AsyncClient(timeout=12) as client:
                    response = await client.get(
                        f"{OPENAQ_BASE_URL}{path}",
                        params=params,
                        headers={"X-API-Key": api_key, "Accept": "application/json"},
                    )
        except httpx.TimeoutException as error:
            raise OpenAQError("OpenAQ request timed out.", 504) from error
        except httpx.RequestError as error:
            raise OpenAQError("Unable to reach the OpenAQ service.", 502) from error

        if response.status_code >= 400:
            logger.warning("OpenAQ upstream returned HTTP %s.", response.status_code)
        if response.status_code == 401:
            raise OpenAQError(
                "OpenAQ authentication failed. Configure a valid OPENAQ_API_KEY on the backend.",
                502,
            )
        if response.status_code == 403:
            raise OpenAQError(
                "OpenAQ denied access for this API key. Verify its permissions.",
                502,
            )
        if response.status_code == 404:
            raise OpenAQError("OpenAQ station data is no longer available.", 404)
        if response.status_code == 429:
            raise OpenAQError(
                "OpenAQ rate limit reached. Try again after the indicated delay.",
                503,
                response.headers.get("Retry-After"),
            )
        if response.status_code == 500:
            raise OpenAQError(
                "OpenAQ encountered an internal error. Try again shortly.", 503
            )
        if response.status_code == 503:
            raise OpenAQError(
                "OpenAQ is temporarily unavailable. Try again shortly.", 503
            )
        if response.status_code >= 500:
            raise OpenAQError("OpenAQ service is temporarily unavailable.", 503)
        if response.status_code >= 400:
            raise OpenAQError("OpenAQ rejected the air-quality request.", 502)
        try:
            payload = response.json()
        except ValueError as error:
            raise OpenAQError("OpenAQ returned invalid JSON.") from error
        if not isinstance(payload, dict):
            raise OpenAQError("OpenAQ returned an invalid response.")
        return payload


class AirQualityService:
    def __init__(
        self,
        primary_provider: Optional[AirQualityProvider] = None,
        secondary_provider: Optional[SecondaryProvider] = None,
        cache_provider: Optional[CachedDataProvider] = None,
    ):
        self.primary_provider = primary_provider or OpenAQProvider()
        self.secondary_provider = secondary_provider or SecondaryProvider()
        self.cache_provider = cache_provider or CachedDataProvider()

    async def nearby(self, latitude: float, longitude: float) -> dict[str, Any]:
        cache_key = f"nearby:{latitude:.4f}:{longitude:.4f}"
        cached = await self.cache_provider.get(cache_key, fresh_only=True)
        if cached is not None:
            return cached

        try:
            result = await self.primary_provider.nearby(latitude, longitude)
        except OpenAQError as error:
            secondary = await self._try_secondary(latitude, longitude, cache_key)
            if secondary is not None:
                secondary["provider_error"] = str(error)
                return secondary
            cached = await self.cache_provider.get(cache_key)
            if cached is not None:
                cached["provider_error"] = str(error)
                return cached
            raise

        if result["found"]:
            await self.cache_provider.store(cache_key, result)
            return result
        secondary = await self._try_secondary(latitude, longitude, cache_key)
        if secondary is not None:
            return secondary
        cached = await self.cache_provider.get(cache_key)
        if cached is not None:
            cached["provider_error"] = "No station with recent readings was found."
            return cached
        return result

    async def search(self, query: str) -> dict[str, Any]:
        search_provider = getattr(self.primary_provider, "search", None)
        if search_provider is None:
            raise OpenAQError("Manual search is not supported by the configured provider.", 501)
        return await search_provider(query)

    async def _try_secondary(
        self, latitude: float, longitude: float, cache_key: str
    ) -> Optional[dict[str, Any]]:
        if not self.secondary_provider.is_configured:
            return None
        try:
            result = await self.secondary_provider.nearby(latitude, longitude)
        except OpenAQError as error:
            logger.warning(
                "Secondary air-quality provider unavailable (HTTP %s).",
                error.status_code,
            )
            return None
        if not result["found"]:
            return None
        await self.cache_provider.store(cache_key, result)
        return result

# Backward-compatible service name for existing integrations.
OpenAQService = AirQualityService
openaq_service = AirQualityService(OpenAQProvider())
