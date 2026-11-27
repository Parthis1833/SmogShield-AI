from datetime import datetime, timezone
from typing import Dict, List, Literal, Optional
from pydantic import BaseModel, Field, computed_field, field_validator, model_validator


class HealthResponse(BaseModel):
    status: str
    mode: str
    version: str
    timestamp: str


class HourlyForecastItem(BaseModel):
    hour: int = Field(..., ge=0, le=23, description="Hour of the day in 24h format")
    aqi: int = Field(..., ge=0, description="AQI reading")
    pm25: float = Field(..., ge=0, description="PM2.5 concentration in ug/m3")


class AirQualityResponse(BaseModel):
    city: str
    aqi: int
    aqi_standard: str = Field("IN_AQI", description="IN_AQI (CPCB) or US_AQI (EPA)")
    category: str
    pm25_ug_m3: float
    pm10_ug_m3: float
    no2_ug_m3: float = 45.0
    so2_ug_m3: float = 18.0
    co_mg_m3: float = 1.4
    o3_ug_m3: float = 32.0
    station_name: str
    observed_at: str
    source: str
    health_advisory: str
    hourly_trend: List[HourlyForecastItem] = []


class PollutantObservation(BaseModel):
    value: Optional[float] = None
    unit: Optional[str] = None
    observed_at: Optional[str] = None


class RequestedLocation(BaseModel):
    latitude: float
    longitude: float
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    display_name: Optional[str] = None


class LocationSuggestion(BaseModel):
    place_id: str
    city: str
    state: Optional[str] = None
    country: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    display_name: str
    description: str
    attribution: str


class LocationSearchResponse(BaseModel):
    suggestions: List[LocationSuggestion]
    session_token: Optional[str] = None
    source: str = "Google Places"


class LocationDetailsResponse(BaseModel):
    place_id: str
    city: str
    state: Optional[str] = None
    country: Optional[str] = None
    latitude: float
    longitude: float
    display_name: str
    attribution: str
    source: str = "Google Places"


class MonitoringStation(BaseModel):
    id: str
    name: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    distance_km: Optional[float] = None


class NearbyAirQualityResponse(BaseModel):
    status: str
    source: str
    data_status: str
    requested_location: Optional[RequestedLocation] = None
    station: Optional[MonitoringStation] = None
    measurements: Dict[str, Optional[PollutantObservation]]
    is_cached: bool = False
    cache_age_seconds: float = 0.0
    search_radius_km: Optional[int] = None
    provider_error: Optional[str] = None
    no_data_reason: Optional[str] = None
    found: bool
    location_id: Optional[str] = None
    station_name: Optional[str] = None
    station_latitude: Optional[float] = None
    station_longitude: Optional[float] = None
    distance_km: Optional[float] = None
    provider: Optional[str] = None
    observed_at: Optional[str] = None
    freshness: Optional[str] = None
    freshest_age_minutes: Optional[float] = None
    pollutants: Dict[str, PollutantObservation]
    recommendations: List[str] = []
    recommendation_engine: Optional[str] = None


class AssistantLocation(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    city: Optional[str] = Field(None, max_length=100)
    state: Optional[str] = Field(None, max_length=100)
    country: Optional[str] = Field(None, max_length=100)
    display_name: Optional[str] = Field(None, max_length=200)


class ConversationTurn(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(..., min_length=1, max_length=6000)

    @field_validator("content")
    @classmethod
    def trim_content(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Conversation turns must contain text.")
        return value


class FamilyMemberHealthContext(BaseModel):
    name: str = ""
    relationship: str = "Member"
    age: Optional[int] = None
    has_asthma: bool = False
    asthma_severity: str = "None"
    other_respiratory_conditions: Optional[str] = None
    other_health_conditions: Optional[str] = None
    is_vulnerable: bool = False


class Question(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    city: Optional[str] = Field(None, max_length=100)
    has_children: bool = False
    has_respiratory_condition: bool = False
    primary_commute_mode: Optional[str] = Field(None, max_length=100)
    air_purification_setup: Optional[str] = Field(None, max_length=200)
    family_members: List[FamilyMemberHealthContext] = Field(default_factory=list)
    selected_location: Optional[AssistantLocation] = None
    history: List[ConversationTurn] = Field(default_factory=list, max_length=12)
    conversation_id: Optional[str] = Field(None, min_length=1, max_length=128)

    @field_validator("message")
    @classmethod
    def trim_message(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Message must contain non-whitespace characters.")
        return value

    @model_validator(mode="after")
    def limit_history_size(self) -> "Question":
        if sum(len(turn.content) for turn in self.history) > 24000:
            raise ValueError("Conversation history is too long.")
        return self


class AssistantAirQualityContext(BaseModel):
    status: Literal["available_fresh", "available_stale", "unavailable"]
    source: str
    station: Optional[str] = None
    observed_at: Optional[str] = None
    freshness: Optional[str] = None
    measurements: Dict[str, PollutantObservation] = Field(default_factory=dict)


class AssistantResponse(BaseModel):
    message: str
    conversation_id: str
    model: str
    source_status: Literal["available_fresh", "available_stale", "unavailable"]
    relevant_context: Optional[AssistantAirQualityContext] = None
    engine: str = "gemini"
    disclaimer: str
    suggested_prompts: List[str] = Field(default_factory=list)
    citations: List[str] = Field(default_factory=list)

    @computed_field
    @property
    def answer(self) -> str:
        return self.message


class RoutineItemResponse(BaseModel):
    id: str
    time: str
    time_period: str
    title: str
    detail: str
    reason: str
    category: str
    target_audience: str


class RoutineListResponse(BaseModel):
    city: str
    routines: List[RoutineItemResponse]


class RoutineGenerationRequest(BaseModel):
    city: str = Field(..., min_length=1, max_length=100)
    has_children: bool = False
    has_respiratory_condition: bool = False
    primary_commute_mode: Optional[str] = Field(None, max_length=100)
    air_purification_setup: Optional[str] = Field(None, max_length=200)


class IndoorTipResponse(BaseModel):
    id: str
    title: str
    summary: str
    detailed_explanation: str
    category: str
    scientific_basis: str
    is_recommended: bool


class ImpactBenchmarkItem(BaseModel):
    mode: str
    emission_factor_kg_co2e_per_km: float
    description: str


class ImpactBenchmarkResponse(BaseModel):
    benchmarks: List[ImpactBenchmarkItem]
    disclaimer: str
    formula: str


class ImpactActionRequest(BaseModel):
    title: str = Field(..., min_length=3, max_length=120)
    baseline_mode: str = Field(..., min_length=1, max_length=80)
    alternative_mode: str = Field(..., min_length=1, max_length=80)
    distance_km: float = Field(..., gt=0, le=1000)

    @model_validator(mode="after")
    def modes_must_differ(self) -> "ImpactActionRequest":
        if self.baseline_mode == self.alternative_mode:
            raise ValueError("Choose different baseline and alternative modes.")
        return self


class ImpactActionResponse(BaseModel):
    id: str
    title: str
    baseline_mode: str
    alternative_mode: str
    distance_km: float
    co2e_savings_kg: float
    formula: str
    recorded_at: str


class ImpactActionListResponse(BaseModel):
    actions: List[ImpactActionResponse]


class CommunityChallengeRequest(BaseModel):
    title: str = Field(..., min_length=3, max_length=100)
    description: str = Field(..., min_length=10, max_length=1000)
    goal: str = Field(..., min_length=3, max_length=200)
    participant_goal: int = Field(..., ge=2, le=1000000)
    ends_at: datetime

    @field_validator("ends_at")
    @classmethod
    def end_date_must_be_future(cls, value: datetime) -> datetime:
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        if value <= datetime.now(timezone.utc):
            raise ValueError("Challenge end date must be in the future.")
        return value


class CommunityChallengeResponse(BaseModel):
    id: str
    title: str
    description: str
    goal: str
    participant_goal: int
    participants_count: int
    joined: bool
    ends_at: str
    created_by: str


class CommunityChallengeListResponse(BaseModel):
    challenges: List[CommunityChallengeResponse]
