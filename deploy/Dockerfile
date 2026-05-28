# ──────────────────────────────────────────────────────────────────────────────
# Aegis-Omni Intelligence Swarm — Dockerfile
# Builds a production-grade container for the FastAPI + LangGraph backend.
# ──────────────────────────────────────────────────────────────────────────────

FROM python:3.11-slim

# Set environment
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8

WORKDIR /app

# Install OS dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies first (layer caching)
COPY backend_swarm/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the full backend source
COPY backend_swarm/ ./backend_swarm/

# Create the log file so it mounts cleanly
RUN touch ./backend_swarm/antigravity_trace_log.txt

# Expose FastAPI port
EXPOSE 8000

# Health check — confirms the swarm gateway is alive
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Launch the Swarm Gateway
CMD ["python", "backend_swarm/main_api.py"]
