"""
src/security/api_guard.py
Request guards for the gateway: API-key auth for the paid-LLM ingest route,
an in-memory rate limiter and a request body cap.
Everything fails closed when its configuration is missing.
"""

import hmac
import logging
import math
import os
import threading
import time
from collections import deque
from typing import Callable, Deque, Dict, Optional

from fastapi import Header, HTTPException, Request, status
from fastapi.responses import JSONResponse

logger = logging.getLogger("AegisSecurity.ApiGuard")

API_KEY_ENV = "AEGIS_INGEST_API_KEY"
MIN_API_KEY_LENGTH = 32
DEFAULT_MAX_BODY_BYTES = 16 * 1024


def _env_int(name: str, default: int) -> int:
    try:
        value = int(os.getenv(name, ""))
    except ValueError:
        return default
    return value if value > 0 else default


# ──────────────────────────────────────────────────────────────────────────────
# API KEY AUTH
# ──────────────────────────────────────────────────────────────────────────────

def verify_ingest_api_key(x_api_key: Optional[str] = Header(default=None)) -> None:
    """FastAPI dependency: require the shared ingest key in the X-API-Key header."""
    expected = os.getenv(API_KEY_ENV, "")
    if len(expected) < MIN_API_KEY_LENGTH:
        # Fail closed: an unconfigured (or weakly configured) server never runs the swarm.
        logger.error(f"{API_KEY_ENV} is unset or shorter than {MIN_API_KEY_LENGTH} chars; ingest disabled.")
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Ingest is not configured.")
    if not x_api_key or not hmac.compare_digest(x_api_key.encode(), expected.encode()):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or missing API key.")


# ──────────────────────────────────────────────────────────────────────────────
# RATE LIMITING
# ──────────────────────────────────────────────────────────────────────────────

class SlidingWindowRateLimiter:
    """
    Allows at most `max_requests` per `window_seconds` for each key.

    In-memory and per-process: counters reset on restart and are not shared
    between workers or replicas. Move to a shared store (e.g. Redis) before
    running more than one process.
    """

    MAX_TRACKED_KEYS = 10_000

    def __init__(self, max_requests: int, window_seconds: float,
                 clock: Callable[[], float] = time.monotonic):
        if max_requests < 1 or window_seconds <= 0:
            raise ValueError("max_requests and window_seconds must be positive")
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._clock = clock
        self._hits: Dict[str, Deque[float]] = {}
        self._lock = threading.Lock()

    def _expire(self, hits: Deque[float], now: float) -> None:
        cutoff = now - self.window_seconds
        while hits and hits[0] <= cutoff:
            hits.popleft()

    def allow(self, key: str) -> bool:
        now = self._clock()
        with self._lock:
            if len(self._hits) >= self.MAX_TRACKED_KEYS:
                for stale_key in [k for k, h in self._hits.items() if not h or h[-1] <= now - self.window_seconds]:
                    del self._hits[stale_key]
            hits = self._hits.setdefault(key, deque())
            self._expire(hits, now)
            if len(hits) >= self.max_requests:
                return False
            hits.append(now)
            return True

    def retry_after(self, key: str) -> int:
        """Whole seconds until `key` may send another request (0 if it may now)."""
        now = self._clock()
        with self._lock:
            hits = self._hits.get(key)
            if not hits:
                return 0
            self._expire(hits, now)
            if len(hits) < self.max_requests:
                return 0
            return max(1, math.ceil(hits[0] + self.window_seconds - now))


def ingest_rate_limiter_from_env() -> SlidingWindowRateLimiter:
    return SlidingWindowRateLimiter(
        max_requests=_env_int("INGEST_RATE_LIMIT", 10),
        window_seconds=_env_int("INGEST_RATE_WINDOW_SECONDS", 60),
    )


def listener_rate_limiter_from_env() -> SlidingWindowRateLimiter:
    """Global cap on swarm runs started by the Firestore listener (client-created reports)."""
    return SlidingWindowRateLimiter(
        max_requests=_env_int("SWARM_LISTENER_MAX_PER_MINUTE", 30),
        window_seconds=60,
    )


def enforce_ingest_rate_limit(request: Request) -> None:
    """
    FastAPI dependency: per-client-IP limit using `app.state.ingest_limiter`.
    Behind a reverse proxy every request shares the proxy's IP; run uvicorn with
    --proxy-headers and a trusted --forwarded-allow-ips so the real IP is used.
    """
    limiter: SlidingWindowRateLimiter = request.app.state.ingest_limiter
    client_ip = request.client.host if request.client else "unknown"
    if not limiter.allow(client_ip):
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            "Rate limit exceeded.",
            headers={"Retry-After": str(limiter.retry_after(client_ip))},
        )


# ──────────────────────────────────────────────────────────────────────────────
# REQUEST BODY SIZE LIMIT
# ──────────────────────────────────────────────────────────────────────────────

def max_body_bytes_from_env() -> int:
    return _env_int("MAX_REQUEST_BYTES", DEFAULT_MAX_BODY_BYTES)


class BodySizeLimitMiddleware:
    """Rejects HTTP request bodies over `max_bytes` with 413, including chunked uploads."""

    def __init__(self, app, max_bytes: int = DEFAULT_MAX_BODY_BYTES):
        self.app = app
        self.max_bytes = max_bytes

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        declared = dict(scope.get("headers") or []).get(b"content-length")
        if declared is not None:
            try:
                too_large = int(declared) > self.max_bytes
            except ValueError:
                too_large = True
            if too_large:
                await self._reject(scope, receive, send)
                return

        received = 0

        async def limited_receive():
            nonlocal received
            message = await receive()
            if message["type"] == "http.request":
                received += len(message.get("body", b""))
                if received > self.max_bytes:
                    # FastAPI re-raises HTTPExceptions raised while reading the body.
                    raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "Request body too large.")
            return message

        await self.app(scope, limited_receive, send)

    async def _reject(self, scope, receive, send):
        response = JSONResponse({"detail": "Request body too large."},
                                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE)
        await response(scope, receive, send)

