import asyncio
from types import SimpleNamespace

import httpx2
import pytest
from fastapi.testclient import TestClient
from google.genai import errors
from pydantic import ValidationError

from app import main
from app.models import (
    AssistantAirQualityContext,
    AssistantResponse,
    Question,
)
from app.services.firebase_service import InvalidFirebaseToken
from app.services.gemini_service import GeminiService, GeminiUnavailable


class FakeModels:
    def __init__(self, text=None, error=None):
        self.text = text
        self.error = error
        self.calls = []

    async def generate_content(self, **kwargs):
        self.calls.append(kwargs)
        if self.error is not None:
            raise self.error
        return SimpleNamespace(text=self.text)


class FakeClient:
    def __init__(self, models):
        self.aio = SimpleNamespace(models=models)


def test_chat_uses_history_and_verified_observations():
    models = FakeModels("PM2.5 is fine particulate matter.")
    service = GeminiService(api_key="test-key", model="gemini-test", client=FakeClient(models))
    question = Question(
        message="Explain it in Hindi.",
        history=[
            {"role": "user", "content": "What is PM2.5?"},
            {"role": "assistant", "content": "A particulate pollutant."},
        ],
        conversation_id="conversation-1",
        selected_location={
            "latitude": 18.52,
            "longitude": 73.85,
            "city": "Pune",
        },
        has_children=True,
    )
    air_quality = AssistantAirQualityContext(
        status="available_fresh",
        source="OpenAQ",
        station="Pune station",
        observed_at="2025-01-02T03:04:05Z",
        freshness="Fresh",
        measurements={
            "PM2.5": {
                "value": 24.5,
                "unit": "µg/m³",
                "observed_at": "2025-01-02T03:04:05Z",
            }
        },
    )

    response = asyncio.run(service.generate_response(question, air_quality))

    assert response.message == response.answer == "PM2.5 is fine particulate matter."
    assert response.conversation_id == "conversation-1"
    assert response.model == "gemini-test"
    assert response.source_status == "available_fresh"
    assert response.relevant_context.measurements["PM2.5"].unit == "µg/m³"
    sent = models.calls[0]["contents"]
    assert [turn["role"] for turn in sent] == ["user", "model", "user"]
    assert "2025-01-02T03:04:05Z" in sent[-1]["parts"][0]["text"]
    assert "OpenAQ" in sent[-1]["parts"][0]["text"]


def test_chat_without_observations_marks_source_unavailable():
    models = FakeModels("PM2.5 is fine particulate matter.")
    service = GeminiService(api_key="test-key", client=FakeClient(models))

    response = asyncio.run(
        service.generate_response(Question(message="What is PM2.5?"), None)
    )

    assert response.source_status == "unavailable"
    assert response.relevant_context is None


def test_missing_key_fails_without_fabricated_answer():
    service = GeminiService(api_key="")

    with pytest.raises(GeminiUnavailable, match="GEMINI_API_KEY") as error:
        asyncio.run(service.generate_response(Question(message="What is PM2.5?"), None))
    assert error.value.status_code == 503


def test_service_account_email_is_never_used_as_gemini_key():
    service = GeminiService(api_key="firebase-admin@project.iam.gserviceaccount.com")

    assert service.client is None


@pytest.mark.parametrize(
    ("upstream_error", "message", "status_code"),
    [
        (
            errors.APIError(403, {"error": {"message": "invalid key"}}),
            "rejected",
            502,
        ),
        (
            errors.APIError(429, {"error": {"message": "quota"}}),
            "quota",
            503,
        ),
        (
            httpx2.ReadTimeout("upstream timeout"),
            "timed out",
            503,
        ),
    ],
)
def test_upstream_errors_are_explicit_and_never_fallback(
    upstream_error, message, status_code
):
    service = GeminiService(
        api_key="test-key",
        client=FakeClient(FakeModels(error=upstream_error)),
    )

    with pytest.raises(GeminiUnavailable, match=message) as error:
        asyncio.run(service.generate_response(Question(message="What is PM2.5?"), None))
    assert error.value.status_code == status_code


def test_chat_request_rejects_empty_or_oversized_history():
    with pytest.raises(ValidationError):
        Question(message="  ")
    with pytest.raises(ValidationError):
        Question(
            message="Question",
            history=[{"role": "user", "content": "x" * 2001}] * 12,
        )


def test_server_fetches_timestamped_open_aq_context_for_selected_location(monkeypatch):
    async def nearby(latitude, longitude):
        assert latitude == 18.52
        assert longitude == 73.85
        return {
            "found": True,
            "source": "OpenAQ",
            "station_name": "Pune station",
            "observed_at": "2025-01-02T03:04:05Z",
            "freshness": "Stale",
            "pollutants": {
                "PM2.5": {
                    "value": 24.5,
                    "unit": "µg/m³",
                    "observed_at": "2025-01-02T03:04:05Z",
                }
            },
        }

    monkeypatch.setattr(main.openaq_service, "nearby", nearby)
    question = Question(
        message="What do the readings mean?",
        selected_location={
            "latitude": 18.52,
            "longitude": 73.85,
            "city": "Pune",
        },
    )

    context = asyncio.run(main._assistant_air_quality_context(question))

    assert context is not None
    assert context.status == "available_stale"
    assert context.source == "OpenAQ"
    assert context.measurements["PM2.5"].unit == "µg/m³"
    assert context.measurements["PM2.5"].observed_at == "2025-01-02T03:04:05Z"


def test_assistant_requires_a_firebase_bearer_token(monkeypatch):
    client = TestClient(main.app)
    main.location_rate_limiter.clear()

    def invalid_token(_token):
        raise InvalidFirebaseToken("invalid")

    monkeypatch.setattr(main.firebase_service, "verify_id_token", invalid_token)

    missing = client.post("/api/v1/assistant", json={"message": "What is PM2.5?"})
    invalid = client.post(
        "/api/v1/assistant",
        json={"message": "What is PM2.5?"},
        headers={"Authorization": "Bearer invalid"},
    )

    assert missing.status_code == 401
    assert invalid.status_code == 401


def test_assistant_endpoint_accepts_verified_user_and_returns_typed_response(monkeypatch):
    client = TestClient(main.app)
    main.location_rate_limiter.clear()
    monkeypatch.setattr(
        main.firebase_service,
        "verify_id_token",
        lambda _token: {"uid": "test-user"},
    )

    async def generate(question, air_quality):
        assert question.message == "What is PM2.5?"
        assert air_quality is None
        return AssistantResponse(
            message="PM2.5 is fine particulate matter.",
            conversation_id="conversation-1",
            model="gemini-test",
            source_status="unavailable",
            disclaimer="Environmental guidance only.",
        )

    monkeypatch.setattr(main.gemini_service, "generate_response", generate)
    response = client.post(
        "/api/v1/assistant",
        json={"message": "What is PM2.5?"},
        headers={"Authorization": "Bearer valid-test-token"},
    )

    assert response.status_code == 200
    assert response.json()["message"] == response.json()["answer"]
    assert response.json()["conversation_id"] == "conversation-1"
    assert response.json()["model"] == "gemini-test"


def test_authenticated_chat_with_missing_gemini_key_returns_service_unavailable(
    monkeypatch,
):
    client = TestClient(main.app)
    main.location_rate_limiter.clear()
    monkeypatch.setattr(
        main.firebase_service,
        "verify_id_token",
        lambda _token: {"uid": "test-user"},
    )
    monkeypatch.setattr(main, "gemini_service", GeminiService(api_key=""))

    response = client.post(
        "/api/v1/assistant",
        json={"message": "What is PM2.5?"},
        headers={"Authorization": "Bearer valid-test-token"},
    )

    assert response.status_code == 503
    assert "GEMINI_API_KEY" in response.json()["detail"]
