import math
import logging
import time
from collections import deque
from datetime import datetime, timezone
from pathlib import Path
from typing import Deque, Dict, List, Optional, Tuple
from fastapi import Depends, FastAPI, HTTPException, Query, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from dotenv import load_dotenv

BACKEND_DIR = Path(__file__).resolve().parents[1]
load_dotenv(BACKEND_DIR / ".env")

from app.models import (
    HealthResponse,
    AirQualityResponse,
    HourlyForecastItem,
    Question,
    AssistantResponse,
    AssistantAirQualityContext,
    RoutineListResponse,
    RoutineItemResponse,
    IndoorTipResponse,
    ImpactBenchmarkResponse,
    ImpactBenchmarkItem,
    ImpactActionRequest,
    ImpactActionResponse,
    ImpactActionListResponse,
    CommunityChallengeRequest,
    CommunityChallengeResponse,
    CommunityChallengeListResponse,
    RoutineGenerationRequest,
    NearbyAirQualityResponse,
    MonitoringStation,
    LocationSearchResponse,
    LocationDetailsResponse,
)
from app.services.gemini_service import GeminiUnavailable, gemini_service
from app.services.firebase_service import (
    FirebaseAuthenticationUnavailable,
    InvalidFirebaseToken,
    firebase_service,
)
from app.services.openaq_service import OpenAQError, openaq_service
from app.services.google_places_service import (
    LocationSearchError,
    google_places_service,
)

logger = logging.getLogger(__name__)

app = FastAPI(
    title="SmogShield AI API",
    version="0.1.0",
    description="Backend microservice for SmogShield AI - Winter smog advisory & GenAI assistant interface",
)

# CORS Middleware for Web and Local Development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

location_bearer_scheme = HTTPBearer(auto_error=False)


def require_authenticated_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(
        location_bearer_scheme
    ),
) -> Dict[str, object]:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="A Firebase bearer token is required.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        return firebase_service.verify_id_token(credentials.credentials)
    except InvalidFirebaseToken as error:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="The Firebase ID token is invalid or expired.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from error
    except FirebaseAuthenticationUnavailable as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error


class LocationRateLimiter:
    def __init__(self, limit: int = 30, window_seconds: int = 60):
        self.limit = limit
        self.window_seconds = window_seconds
        self._requests: Dict[Tuple[str, str], Deque[float]] = {}

    def check(self, request: Request, scope: str) -> None:
        now = time.monotonic()
        client_host = request.client.host if request.client else "unknown"
        key = (client_host, scope)

        for existing_key, timestamps in list(self._requests.items()):
            while timestamps and now - timestamps[0] >= self.window_seconds:
                timestamps.popleft()
            if not timestamps:
                del self._requests[existing_key]

        timestamps = self._requests.setdefault(key, deque())
        if len(timestamps) >= self.limit:
            retry_after = max(
                1, math.ceil(self.window_seconds - (now - timestamps[0]))
            )
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many location requests. Try again shortly.",
                headers={"Retry-After": str(retry_after)},
            )
        timestamps.append(now)

    def clear(self) -> None:
        self._requests.clear()


location_rate_limiter = LocationRateLimiter()


def limit_location_search(request: Request) -> None:
    location_rate_limiter.check(request, "search")


def limit_location_details(request: Request) -> None:
    location_rate_limiter.check(request, "details")


def limit_assistant_request(request: Request) -> None:
    location_rate_limiter.check(request, "assistant")


# Global Exception Handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "InternalServerError",
            "detail": "An unexpected server error occurred.",
        },
    )


@app.get("/health", response_model=HealthResponse)
def health():
    return HealthResponse(
        status="ok",
        mode="live",
        version="0.1.0",
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


@app.get("/api/v1/air-quality", response_model=AirQualityResponse)
def air_quality(
    city: str = Query(..., description="Use the nearby coordinate endpoint instead"),
    standard: str = Query("IN_AQI", description="AQI scale standard (IN_AQI or US_AQI)"),
):
    raise HTTPException(
        status_code=status.HTTP_410_GONE,
        detail="City-name AQI snapshots are not supported. Select a location and use /api/v1/air-quality/nearby.",
    )


@app.get("/api/v1/locations/search", response_model=LocationSearchResponse)
async def search_locations(
    q: str = Query(..., max_length=100),
    session_token: Optional[str] = Query(None, min_length=36, max_length=36),
    _user: Dict[str, object] = Depends(require_authenticated_user),
    _rate_limit: None = Depends(limit_location_search),
):
    query = q.strip()
    if len(query) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Enter at least two non-whitespace characters.",
        )
    try:
        return await google_places_service.search(query, session_token)
    except LocationSearchError as error:
        headers = (
            {"Retry-After": error.retry_after}
            if error.retry_after is not None
            else None
        )
        raise HTTPException(
            status_code=error.status_code, detail=str(error), headers=headers
        ) from error


@app.get(
    "/api/v1/locations/details",
    response_model=LocationDetailsResponse,
)
async def location_details(
    place_id: str = Query(..., min_length=1, max_length=512),
    session_token: Optional[str] = Query(None, min_length=36, max_length=36),
    _user: Dict[str, object] = Depends(require_authenticated_user),
    _rate_limit: None = Depends(limit_location_details),
):
    place_id = place_id.strip()
    if not place_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="place_id must contain non-whitespace characters.",
        )
    try:
        return await google_places_service.details(place_id, session_token)
    except LocationSearchError as error:
        headers = (
            {"Retry-After": error.retry_after}
            if error.retry_after is not None
            else None
        )
        raise HTTPException(
            status_code=error.status_code, detail=str(error), headers=headers
        ) from error


async def _build_nearby_response(data: dict) -> NearbyAirQualityResponse:
    if data["found"]:
        try:
            recommendations, engine, is_mock = (
                await gemini_service.generate_pollution_recommendations(
                    station=data["station_name"],
                    provider=data["provider"],
                    observed_at=data["observed_at"],
                    pollutants=data["pollutants"],
                )
            )
        except GeminiUnavailable:
            logger.warning("Gemini recommendations are unavailable.")
            recommendations, engine, is_mock = [], "unavailable", False
    else:
        recommendations, engine, is_mock = [], None, False
    response_data = dict(data)
    response_data.update(
        status="success" if data["found"] else "no_data",
        source=data.get("source", "OpenAQ"),
        data_status=data.get(
            "data_status", "nearest_station" if data["found"] else "no_station"
        ),
        no_data_reason=(
            data.get("no_data_reason")
            if not data["found"]
            else None
        ),
        station=(
            MonitoringStation(
                id=data["location_id"],
                name=data["station_name"],
                latitude=data.get("station_latitude"),
                longitude=data.get("station_longitude"),
                distance_km=data.get("distance_km"),
            )
            if data["found"]
            else None
        ),
        measurements={
            key: value if value["value"] is not None else None
            for key, value in data["pollutants"].items()
        },
        recommendations=recommendations,
        recommendation_engine=engine,
    )
    return NearbyAirQualityResponse(**response_data)


@app.get(
    "/api/v1/air-quality/nearby",
    response_model=NearbyAirQualityResponse,
)
async def nearby_air_quality(
    lat: float = Query(...),
    lon: float = Query(...),
    city: Optional[str] = Query(None, max_length=150),
    state: Optional[str] = Query(None, max_length=150),
    country: Optional[str] = Query(None, max_length=150),
    display_name: Optional[str] = Query(None, max_length=300),
):
    if not (
        math.isfinite(lat)
        and math.isfinite(lon)
        and -90 <= lat <= 90
        and -180 <= lon <= 180
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Latitude must be between -90 and 90 and longitude between -180 and 180.",
        )
    try:
        data = await openaq_service.nearby(lat, lon)
    except OpenAQError as error:
        headers = (
            {"Retry-After": error.retry_after}
            if error.retry_after is not None
            else None
        )
        raise HTTPException(
            status_code=error.status_code, detail=str(error), headers=headers
        ) from error
    data["requested_location"] = {
        "latitude": lat,
        "longitude": lon,
        "city": city,
        "state": state,
        "country": country,
        "display_name": display_name,
    }
    return await _build_nearby_response(data)


@app.get(
    "/api/v1/air-quality/search",
    response_model=NearbyAirQualityResponse,
)
async def search_air_quality(
    query: str = Query(..., min_length=2, max_length=100),
):
    try:
        data = await openaq_service.search(query)
    except OpenAQError as error:
        raise HTTPException(status_code=error.status_code, detail=str(error)) from error
    return await _build_nearby_response(data)


async def _assistant_air_quality_context(
    question: Question,
) -> Optional[AssistantAirQualityContext]:
    location = question.selected_location
    if location is None:
        return None
    try:
        data = await openaq_service.nearby(location.latitude, location.longitude)
    except OpenAQError as error:
        logger.warning("OpenAQ context unavailable with status %s.", error.status_code)
        return AssistantAirQualityContext(
            status="unavailable",
            source="OpenAQ",
        )

    source = str(data.get("source") or "OpenAQ")
    if not data.get("found"):
        return AssistantAirQualityContext(
            status="unavailable",
            source=source,
        )
    measurements = {
        name: observation
        for name, observation in data.get("pollutants", {}).items()
        if isinstance(observation, dict)
    }
    freshness = data.get("freshness")
    status_value = (
        "available_fresh"
        if isinstance(freshness, str) and freshness.casefold() == "fresh"
        else "available_stale"
    )
    return AssistantAirQualityContext(
        status=status_value,
        source=source,
        station=data.get("station_name"),
        observed_at=data.get("observed_at"),
        freshness=freshness,
        measurements=measurements,
    )


@app.post("/api/v1/assistant", response_model=AssistantResponse)
async def assistant(
    question: Question,
    _user: Dict[str, object] = Depends(require_authenticated_user),
    _rate_limit: None = Depends(limit_assistant_request),
):
    air_quality = await _assistant_air_quality_context(question)
    try:
        return await gemini_service.generate_response(question, air_quality)
    except GeminiUnavailable as error:
        raise HTTPException(
            status_code=error.status_code,
            detail=str(error),
        ) from error


@app.get("/api/v1/routines", response_model=RoutineListResponse)
async def get_routines(
    city: str = Query(..., min_length=1, max_length=100),
    has_children: bool = Query(False),
    has_respiratory_condition: bool = Query(False),
    primary_commute_mode: Optional[str] = Query(None, max_length=100),
    air_purification_setup: Optional[str] = Query(None, max_length=200),
    _user: Dict[str, object] = Depends(require_authenticated_user),
):
    request = RoutineGenerationRequest(
        city=city,
        has_children=has_children,
        has_respiratory_condition=has_respiratory_condition,
        primary_commute_mode=primary_commute_mode,
        air_purification_setup=air_purification_setup,
    )
    try:
        routines = await gemini_service.generate_routines(request)
    except GeminiUnavailable as error:
        raise HTTPException(
            status_code=error.status_code,
            detail=str(error),
        ) from error
    return RoutineListResponse(city=city, routines=routines)


@app.get("/api/v1/indoor-tips", response_model=List[IndoorTipResponse])
def get_indoor_tips():
    return [
        IndoorTipResponse(
            id="hepa_h13",
            title="True HEPA (H13) Mechanical Filtration",
            summary="Captures 99.97% of fine particles down to 0.3 microns without emitting ozone.",
            detailed_explanation="Mechanical filters are the gold standard for PM2.5 capture. Avoid electrostatic precipitators that produce harmful ozone.",
            category="filtration",
            scientific_basis="ISO 29463 and EN 1822 particulate testing standards.",
            is_recommended=True,
        ),
        IndoorTipResponse(
            id="timed_ventilation",
            title="Solar Inversion Ventilation Timing",
            summary="Ventilate only during midday (1-3 PM) solar dispersion windows.",
            detailed_explanation="Winter smog peaks at night and morning due to thermal inversion. Opening windows during early morning traps dense ground-level pollution inside.",
            category="ventilation",
            scientific_basis="Planetary atmospheric boundary layer thermal mixing kinetics.",
            is_recommended=True,
        ),
    ]


@app.get("/api/v1/impact/benchmarks", response_model=ImpactBenchmarkResponse)
def get_impact_benchmarks():
    return ImpactBenchmarkResponse(
        formula="Distance (km) x (Baseline vehicle factor - Clean mode factor) = kg CO2e avoided",
        disclaimer="Estimates represent societal emissions savings, not individual personal exposure reduction.",
        benchmarks=[
            ImpactBenchmarkItem(
                mode="Solo Petrol Car",
                emission_factor_kg_co2e_per_km=0.18,
                description="Average urban passenger car with single occupant",
            ),
            ImpactBenchmarkItem(
                mode="Electric Mass Metro",
                emission_factor_kg_co2e_per_km=0.07,
                description="Grid-electrified mass transit system per passenger-km",
            ),
            ImpactBenchmarkItem(
                mode="Electric Bus / Shuttle",
                emission_factor_kg_co2e_per_km=0.05,
                description="High-capacity clean public bus transit",
            ),
        ],
    )


@app.get(
    "/api/v1/impact/actions",
    response_model=ImpactActionListResponse,
)
def get_impact_actions(
    user: Dict[str, object] = Depends(require_authenticated_user),
):
    user_id = str(user["uid"])
    try:
        actions = firebase_service.list_impact_actions(user_id)
    except FirebaseAuthenticationUnavailable as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
    return ImpactActionListResponse(actions=actions)


@app.post(
    "/api/v1/impact/actions",
    response_model=ImpactActionResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_impact_action(
    request: ImpactActionRequest,
    user: Dict[str, object] = Depends(require_authenticated_user),
):
    benchmarks = {
        item.mode: item
        for item in get_impact_benchmarks().benchmarks
    }
    baseline = benchmarks.get(request.baseline_mode)
    alternative = benchmarks.get(request.alternative_mode)
    if baseline is None or alternative is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Choose transport modes from the impact benchmarks.",
        )

    savings = round(
        request.distance_km
        * (
            baseline.emission_factor_kg_co2e_per_km
            - alternative.emission_factor_kg_co2e_per_km
        ),
        4,
    )
    formula = (
        f"{request.distance_km:g} km × "
        f"({baseline.emission_factor_kg_co2e_per_km:g} − "
        f"{alternative.emission_factor_kg_co2e_per_km:g}) kg CO₂e/km"
    )
    action = {
        "title": request.title,
        "baseline_mode": request.baseline_mode,
        "alternative_mode": request.alternative_mode,
        "distance_km": request.distance_km,
        "co2e_savings_kg": savings,
        "formula": formula,
    }
    try:
        saved = firebase_service.save_impact_action(str(user["uid"]), action)
    except FirebaseAuthenticationUnavailable as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
    return ImpactActionResponse(**saved)


@app.get(
    "/api/v1/community/challenges",
    response_model=CommunityChallengeListResponse,
)
def get_community_challenges(
    user: Dict[str, object] = Depends(require_authenticated_user),
):
    try:
        challenges = firebase_service.list_community_challenges(str(user["uid"]))
    except FirebaseAuthenticationUnavailable as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
    return CommunityChallengeListResponse(challenges=challenges)


@app.post(
    "/api/v1/community/challenges",
    response_model=CommunityChallengeResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_community_challenge(
    request: CommunityChallengeRequest,
    user: Dict[str, object] = Depends(require_authenticated_user),
):
    data = request.model_dump()
    data["ends_at"] = request.ends_at.astimezone(timezone.utc).isoformat()
    try:
        challenge = firebase_service.create_community_challenge(
            str(user["uid"]), data
        )
    except FirebaseAuthenticationUnavailable as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
    return CommunityChallengeResponse(**challenge)


@app.post(
    "/api/v1/community/challenges/{challenge_id}/join",
    status_code=status.HTTP_204_NO_CONTENT,
)
def join_community_challenge(
    challenge_id: str,
    user: Dict[str, object] = Depends(require_authenticated_user),
):
    try:
        firebase_service.join_community_challenge(str(user["uid"]), challenge_id)
    except KeyError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Community challenge was not found.",
        ) from error
    except FirebaseAuthenticationUnavailable as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error


@app.delete(
    "/api/v1/community/challenges/{challenge_id}/join",
    status_code=status.HTTP_204_NO_CONTENT,
)
def leave_community_challenge(
    challenge_id: str,
    user: Dict[str, object] = Depends(require_authenticated_user),
):
    try:
        firebase_service.leave_community_challenge(
            str(user["uid"]), challenge_id
        )
    except KeyError as error:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Community challenge was not found.",
        ) from error
    except FirebaseAuthenticationUnavailable as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(error),
        ) from error
