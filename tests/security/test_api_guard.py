"""
Tests for the gateway guards on the paid-LLM ingest route: API-key auth,
per-IP rate limiting, body/input size limits and the CORS allow-list.
The swarm itself is stubbed out, so no LLM or Firestore call is made.
"""

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

import src.main_api as main_api
from src.security.api_guard import (
    API_KEY_ENV,
    SlidingWindowRateLimiter,
    cors_options,
    parse_allowed_origins,
)

SUBMIT_URL = "/api/v1/sentinel/submit"
VALID_KEY = "test-ingest-key-" + "x" * 32
PAYLOAD = {"doc_id": "TEST-DOC-1", "input_text": "Water rising fast on Karsaz Road"}


class FakeClock:
    def __init__(self, start: float = 1000.0):
        self.now = start

    def __call__(self) -> float:
        return self.now


@pytest.fixture
def swarm_calls(monkeypatch):
    """Stubs the background swarm run and returns the list of calls it receives."""
    calls = []
    monkeypatch.setattr(main_api, "run_swarm_orchestration", lambda *args: calls.append(args))
    monkeypatch.setattr(main_api.app.state, "ingest_limiter", SlidingWindowRateLimiter(3, 60))
    monkeypatch.setenv(API_KEY_ENV, VALID_KEY)
    return calls


@pytest.fixture
def client():
    return TestClient(main_api.app)


# ── API-key auth ──────────────────────────────────────────────────────────────

def test_ingest_fails_closed_when_key_not_configured(client, swarm_calls, monkeypatch):
    monkeypatch.delenv(API_KEY_ENV)
    response = client.post(SUBMIT_URL, json=PAYLOAD, headers={"X-API-Key": "anything"})
    assert response.status_code == 503
    assert swarm_calls == []


def test_ingest_fails_closed_when_key_too_short(client, swarm_calls, monkeypatch):
    monkeypatch.setenv(API_KEY_ENV, "short")
    response = client.post(SUBMIT_URL, json=PAYLOAD, headers={"X-API-Key": "short"})
    assert response.status_code == 503
    assert swarm_calls == []


def test_ingest_rejects_missing_key(client, swarm_calls):
    response = client.post(SUBMIT_URL, json=PAYLOAD)
    assert response.status_code == 401
    assert swarm_calls == []


def test_ingest_rejects_wrong_key(client, swarm_calls):
    response = client.post(SUBMIT_URL, json=PAYLOAD, headers={"X-API-Key": VALID_KEY + "x"})
    assert response.status_code == 401
    assert swarm_calls == []


def test_ingest_accepts_valid_key_and_queues_swarm(client, swarm_calls):
    response = client.post(SUBMIT_URL, json=PAYLOAD, headers={"X-API-Key": VALID_KEY})
    assert response.status_code == 200
    assert response.json()["status"] == "ACCEPTED"
    assert len(swarm_calls) == 1
    assert swarm_calls[0][0] == "TEST-DOC-1"


# ── Rate limiting ─────────────────────────────────────────────────────────────

def test_ingest_rate_limit_returns_429_with_retry_after(client, swarm_calls):
    headers = {"X-API-Key": VALID_KEY}
    statuses = [client.post(SUBMIT_URL, json=PAYLOAD, headers=headers).status_code for _ in range(4)]
    assert statuses == [200, 200, 200, 429]
    blocked = client.post(SUBMIT_URL, json=PAYLOAD, headers=headers)
    assert blocked.status_code == 429
    assert 1 <= int(blocked.headers["Retry-After"]) <= 60
    assert len(swarm_calls) == 3


def test_rate_limit_runs_before_auth_so_key_guessing_is_throttled(client, swarm_calls):
    statuses = [
        client.post(SUBMIT_URL, json=PAYLOAD, headers={"X-API-Key": f"guess-{i}"}).status_code
        for i in range(4)
    ]
    assert statuses == [401, 401, 401, 429]


def test_limiter_slides_window_and_reports_retry_after():
    clock = FakeClock()
    limiter = SlidingWindowRateLimiter(max_requests=2, window_seconds=60, clock=clock)
    assert limiter.allow("1.2.3.4")
    clock.now += 10
    assert limiter.allow("1.2.3.4")
    assert not limiter.allow("1.2.3.4")
    assert limiter.retry_after("1.2.3.4") == 50  # first hit expires at t=60
    clock.now += 50.5
    assert limiter.retry_after("1.2.3.4") == 0
    assert limiter.allow("1.2.3.4")
    assert not limiter.allow("1.2.3.4")


def test_limiter_keeps_clients_separate():
    limiter = SlidingWindowRateLimiter(max_requests=1, window_seconds=60, clock=FakeClock())
    assert limiter.allow("10.0.0.1")
    assert not limiter.allow("10.0.0.1")
    assert limiter.allow("10.0.0.2")


@pytest.mark.parametrize("max_requests, window", [(0, 60), (5, 0), (-1, 60)])
def test_limiter_rejects_invalid_config(max_requests, window):
    with pytest.raises(ValueError):
        SlidingWindowRateLimiter(max_requests, window)


# ── Input size limits ─────────────────────────────────────────────────────────

def test_ingest_rejects_oversized_input_text(client, swarm_calls):
    payload = {**PAYLOAD, "input_text": "a" * (main_api.MAX_INPUT_CHARS + 1)}
    response = client.post(SUBMIT_URL, json=payload, headers={"X-API-Key": VALID_KEY})
    assert response.status_code == 422
    assert swarm_calls == []


@pytest.mark.parametrize("doc_id", ["", "reports/other-doc", "../x", "a" * 129])
def test_ingest_rejects_unsafe_doc_ids(client, swarm_calls, doc_id):
    payload = {**PAYLOAD, "doc_id": doc_id}
    response = client.post(SUBMIT_URL, json=payload, headers={"X-API-Key": VALID_KEY})
    assert response.status_code == 422
    assert swarm_calls == []


def test_ingest_rejects_body_over_limit(client, swarm_calls):
    body = b'{"doc_id": "X", "input_text": "' + b"a" * 20_000 + b'"}'
    response = client.post(
        SUBMIT_URL, content=body,
        headers={"X-API-Key": VALID_KEY, "Content-Type": "application/json"},
    )
    assert response.status_code == 413
    assert swarm_calls == []


def test_ingest_rejects_chunked_body_over_limit(client, swarm_calls):
    def chunks():
        for _ in range(20):
            yield b"a" * 1024

    response = client.post(
        SUBMIT_URL, content=chunks(),
        headers={"X-API-Key": VALID_KEY, "Content-Type": "application/json"},
    )
    assert response.status_code == 413
    assert swarm_calls == []


# ── CORS ──────────────────────────────────────────────────────────────────────

@pytest.mark.parametrize("raw", [None, "", " , ", "*", "https://*.example.com", "ftp://x.example"])
def test_allowed_origins_fail_closed(raw):
    assert parse_allowed_origins(raw) == []


def test_allowed_origins_parses_explicit_list():
    raw = " https://aegis-ai-omni.web.app/ ,http://localhost:5000, * "
    assert parse_allowed_origins(raw) == ["https://aegis-ai-omni.web.app", "http://localhost:5000"]


def test_cors_options_never_allow_credentials():
    options = cors_options("https://aegis-ai-omni.web.app")
    assert options["allow_credentials"] is False
    assert "*" not in options["allow_origins"]
    assert "*" not in options["allow_methods"]
    assert "*" not in options["allow_headers"]


def _preflight(client, origin):
    return client.options(SUBMIT_URL, headers={
        "Origin": origin,
        "Access-Control-Request-Method": "POST",
        "Access-Control-Request-Headers": "content-type,x-api-key",
    })


def test_cors_allow_list_only_echoes_listed_origin():
    from fastapi.middleware.cors import CORSMiddleware

    app = FastAPI()
    app.add_middleware(CORSMiddleware, **cors_options("https://aegis-ai-omni.web.app"))

    @app.post(SUBMIT_URL)
    def submit():
        return {}

    test_client = TestClient(app)
    allowed = _preflight(test_client, "https://aegis-ai-omni.web.app")
    assert allowed.headers["access-control-allow-origin"] == "https://aegis-ai-omni.web.app"
    assert "access-control-allow-credentials" not in allowed.headers

    denied = _preflight(test_client, "https://evil.example")
    assert "access-control-allow-origin" not in denied.headers


def test_gateway_rejects_unlisted_cross_origin_preflight(client):
    response = _preflight(client, "https://evil.example")
    assert "access-control-allow-origin" not in response.headers
    assert response.headers.get("access-control-allow-credentials") != "true"
