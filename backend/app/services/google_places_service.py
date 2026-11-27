import logging
import os
import re
from typing import Any, Optional
from urllib.parse import quote

import httpx


logger = logging.getLogger(__name__)
GOOGLE_PLACES_BASE_URL = "https://places.googleapis.com/v1"
MAX_SUGGESTIONS = 5


class LocationSearchError(Exception):
    def __init__(
        self,
        message: str,
        status_code: int = 502,
        retry_after: Optional[str] = None,
    ):
        super().__init__(message)
        self.status_code = status_code
        self.retry_after = retry_after


class GooglePlacesService:
    def __init__(self, client: Optional[httpx.AsyncClient] = None):
        self._client = client

    async def search(self, query: str, session_token: Optional[str]) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "input": query,
            "includedPrimaryTypes": [
                "locality",
                "administrative_area_level_3",
                "administrative_area_level_4",
            ],
            "includeQueryPredictions": False,
            "languageCode": "en",
        }
        if session_token:
            payload["sessionToken"] = self._validate_session_token(session_token)
        data = await self._request(
            "POST",
            f"{GOOGLE_PLACES_BASE_URL}/places:autocomplete",
            json=payload,
            field_mask=(
                "suggestions.placePrediction.placeId,"
                "suggestions.placePrediction.text.text,"
                "suggestions.placePrediction.structuredFormat.mainText.text,"
                "suggestions.placePrediction.structuredFormat.secondaryText.text"
            ),
        )
        raw_suggestions = data.get("suggestions", [])
        if not isinstance(raw_suggestions, list):
            raise LocationSearchError("Google Places returned invalid suggestions.")
        suggestions = []
        for item in raw_suggestions[:MAX_SUGGESTIONS]:
            if not isinstance(item, dict):
                continue
            prediction = item.get("placePrediction")
            if not isinstance(prediction, dict) or not prediction.get("placeId"):
                continue
            structured = prediction.get("structuredFormat") or {}
            main_text = structured.get("mainText") or {}
            description = (prediction.get("text") or {}).get("text", "")
            suggestions.append(
                {
                    "place_id": prediction["placeId"],
                    "city": main_text.get("text") or description,
                    "state": None,
                    "country": None,
                    "latitude": None,
                    "longitude": None,
                    "display_name": description,
                    "description": description,
                    "attribution": "Google Maps",
                }
            )
        return {"suggestions": suggestions, "session_token": session_token}

    async def details(self, place_id: str, session_token: Optional[str]) -> dict[str, Any]:
        params = {}
        if session_token:
            params["sessionToken"] = self._validate_session_token(session_token)
        data = await self._request(
            "GET",
            f"{GOOGLE_PLACES_BASE_URL}/places/{quote(place_id, safe='')}",
            params=params,
            field_mask="id,displayName,location,addressComponents,formattedAddress",
        )
        location = data.get("location") or {}
        latitude, longitude = location.get("latitude"), location.get("longitude")
        if not (
            isinstance(latitude, (int, float))
            and not isinstance(latitude, bool)
            and -90 <= latitude <= 90
            and isinstance(longitude, (int, float))
            and not isinstance(longitude, bool)
            and -180 <= longitude <= 180
        ):
            raise LocationSearchError(
                "Google Places returned invalid coordinates.", 502
            )

        components: dict[str, str] = {}
        for component in data.get("addressComponents", []):
            if not isinstance(component, dict):
                continue
            for kind in component.get("types", []):
                components[kind] = component.get("longText", "")
        city = (
            components.get("locality")
            or components.get("postal_town")
            or components.get("administrative_area_level_3")
            or components.get("administrative_area_level_2")
            or (data.get("displayName") or {}).get("text", "")
        )
        return {
            "place_id": data.get("id", place_id),
            "city": city,
            "state": components.get("administrative_area_level_1"),
            "country": components.get("country"),
            "latitude": latitude,
            "longitude": longitude,
            "display_name": data.get("formattedAddress") or city,
            "attribution": "Google Maps",
        }

    @staticmethod
    def _validate_session_token(value: str) -> str:
        if not re.fullmatch(r"[A-Fa-f0-9-]{36}", value):
            raise LocationSearchError(
                "session_token must be a UUID generated for this search session.",
                400,
            )
        return value

    async def _request(
        self,
        method: str,
        url: str,
        *,
        field_mask: str,
        json: Optional[dict[str, Any]] = None,
        params: Optional[dict[str, str]] = None,
    ) -> dict[str, Any]:
        api_key = os.getenv("GOOGLE_MAPS_API_KEY", "").strip()
        if not api_key:
            raise LocationSearchError(
                "City search is not configured. Configure GOOGLE_MAPS_API_KEY.",
                503,
            )
        headers = {
            "Accept": "application/json",
            "X-Goog-Api-Key": api_key,
            "X-Goog-FieldMask": field_mask,
        }
        try:
            if self._client is not None:
                response = await self._client.request(
                    method, url, json=json, params=params, headers=headers
                )
            else:
                async with httpx.AsyncClient(timeout=8) as client:
                    response = await client.request(
                        method, url, json=json, params=params, headers=headers
                    )
        except httpx.TimeoutException as error:
            raise LocationSearchError("Google Places request timed out.", 504) from error
        except httpx.RequestError as error:
            raise LocationSearchError(
                "Unable to reach the Google Places service.", 502
            ) from error

        if response.status_code == 404:
            raise LocationSearchError("The selected place was not found.", 404)
        if response.status_code in (401, 403):
            logger.warning("Google Places rejected the backend API key.")
            raise LocationSearchError(
                "City search is unavailable. Check Google Places API key configuration.",
                503,
            )
        if response.status_code == 429:
            raise LocationSearchError(
                "Google Places rate limit reached.",
                503,
                response.headers.get("Retry-After"),
            )
        if response.status_code >= 500:
            raise LocationSearchError("Google Places is temporarily unavailable.", 503)
        if response.status_code >= 400:
            raise LocationSearchError("Google Places rejected the search request.", 400)
        try:
            result = response.json()
        except ValueError as error:
            raise LocationSearchError(
                "Google Places returned invalid JSON."
            ) from error
        if not isinstance(result, dict):
            raise LocationSearchError("Google Places returned invalid data.")
        return result


google_places_service = GooglePlacesService()
