"""
src/main_api.py

AEGIS-OMNI SWARM GATEWAY · PRODUCTION ENGINE (EXPERT 2)
────────────────────────────────────────────────────────
The definitive integration layer that unifies the FastAPI REST boundary 
and the live Firestore 'Citizen Sentinel' listener.

Architectural Role: 
1. Ingests raw crisis signals (Mobile/IoT).
2. Fuses signals into the Sovereign AgentState.
3. Dispatches asynchronous execution to the LangGraph Swarm Engine.
4. Maintains the definitive 'Antigravity' audit trail.
"""

import asyncio
import logging
import os
import sys
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Any, Dict, List

import firebase_admin
import uvicorn
from fastapi import BackgroundTasks, FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from pydantic import BaseModel, Field

# ──────────────────────────────────────────────────────────────────────────────
# SYSTEM PATH & ENGINE INTEGRATION
# ──────────────────────────────────────────────────────────────────────────────
# Add parent directory to sys.path to allow 'from src...' imports
# as required by the elite Systems Architect specification.
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

try:
    from src.agents.graph import aegis_swarm_engine
except ImportError as e:
    # Fallback to local import if the parent-path strategy fails in certain environments
    logging.warning(f"[SYSTEM] Absolute import failed ({e}). Attempting relative import.")
    from agents.graph import aegis_swarm_engine

try:
    from src.security.guardrails import sanitize_input
except ImportError as e:
    logging.warning(f"[SYSTEM] Absolute security import failed ({e}). Attempting relative import.")
    from security.guardrails import sanitize_input

# ──────────────────────────────────────────────────────────────────────────────
# FIREBASE INITIALIZATION
# ──────────────────────────────────────────────────────────────────────────────
cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", os.path.join(parent_dir, "config", "serviceAccountKey.json"))
if not os.path.exists(cred_path):
    # Don't strictly crash for now if it's missing in CI
    logging.warning(f"Firebase serviceAccountKey.json missing at {cred_path}. Initializing MockFirestoreClient.")
    
    # Implement Mock Firestore Client for clean standalone spins
    class MockFirestoreDocument:
        def __init__(self, col_name, doc_id):
            self.col_name = col_name
            self.doc_id = doc_id
        def update(self, data):
            logging.info(f"[MOCK FIRESTORE] Updated doc '{self.doc_id}' in collection '{self.col_name}' with data: {data}")
            return None

    class MockFirestoreQuery:
        def __init__(self, col_name):
            self.col_name = col_name
        def on_snapshot(self, callback):
            logging.warning(f"[MOCK FIRESTORE] Snapshot listener attached to collection '{self.col_name}' (running in standalone simulation)")
            return None

    class MockFirestoreCollection:
        def __init__(self, name):
            self.name = name
        def document(self, doc_id):
            return MockFirestoreDocument(self.name, doc_id)
        def where(self, *args, **kwargs):
            return MockFirestoreQuery(self.name)

    class MockFirestoreClient:
        def collection(self, name):
            return MockFirestoreCollection(name)
            
    db = MockFirestoreClient()
else:
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    db = firestore.client()

# ──────────────────────────────────────────────────────────────────────────────
# LOGGING & AUDIT CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="[AEGIS-GATEWAY] %(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("AegisGateway")

TRACE_LOG_PATH = os.path.join(current_dir, "antigravity_trace_log.txt")

# ──────────────────────────────────────────────────────────────────────────────
# SCHEMAS & UTILITIES
# ──────────────────────────────────────────────────────────────────────────────

class WeatherTelemetry(BaseModel):
    # Safe fallback defaults to protect data fusion from Null reference errors
    precipitation: float = Field(default=0.0, description="Rainfall in mm/hr")
    humidity: float = Field(default=50.0, description="Humidity percentage")

class TrafficTelemetry(BaseModel):
    congestion_level: int = Field(default=0, description="0-100 scale of local gridlock")
    active_roadblocks: int = Field(default=0, description="Number of detected blockages")

class SocialSignal(BaseModel):
    text: str
    source: str = "social"

class SentinelPayload(BaseModel):
    doc_id: str = Field(..., description="Unique Trace ID for the incident")
    input_text: str
    weather: WeatherTelemetry = Field(default_factory=WeatherTelemetry)
    traffic: TrafficTelemetry = Field(default_factory=TrafficTelemetry)
    metadata: Dict[str, Any] = Field(default_factory=dict)

def create_initial_state(doc_id: str, input_text: str, weather: WeatherTelemetry, traffic: TrafficTelemetry) -> Dict[str, Any]:
    """
    Instantiates the precise initial_state schema required by the LangGraph engine.
    Ensures conformance with both the Expert 1 engine and the Curveball logic.
    """
    timestamp = datetime.now(timezone.utc).isoformat()
    return {
        "doc_id": doc_id,
        "incoming_signals": {
            "gateway_fused": {
                "social_text": input_text,
                "rain_mm": weather.precipitation,
                "traffic_congestion": traffic.congestion_level
            }
        },
        "current_classification": {},
        "cascading_threats": [],
        "resource_dispatches": [],
        "reasoning_trace": [
            f"[{timestamp}] [INGEST] Signal received from gateway boundary. Trace ID: {doc_id}"
        ],
        "sensor_telemetry": {
            "rain_mm": weather.precipitation,
            "humidity": weather.humidity,
            "system_health": 1.0
        }
    }

# ──────────────────────────────────────────────────────────────────────────────
# CORE EXECUTION ROUTINE
# ──────────────────────────────────────────────────────────────────────────────

async def run_swarm_orchestration(doc_id: str, input_text: str, weather: WeatherTelemetry, traffic: TrafficTelemetry):
    """
    The definitive execution block. Handles engine invocation, 
    audit logging, and Firestore writeback.
    """
    logger.info(f"🌀 Starting Swarm Orchestration for {doc_id}...")

    try:
        # 0. Pass through Security Guardrails
        sanitized_input = sanitize_input(input_text)
        logger.info(f"🛡️ Security Guardrails: Input checked. Raw: {repr(input_text)} | Sanitized: {repr(sanitized_input)}")

        # 1. Prepare State
        initial_state = create_initial_state(doc_id, sanitized_input, weather, traffic)

        # 2. Invoke Engine (Expert 1)
        final_state = await aegis_swarm_engine.ainvoke(initial_state)

        # 3. Audit Logger (The Judges' Trace)
        with open(TRACE_LOG_PATH, "a", encoding="utf-8") as log_file:
            log_file.write(f"\n--- SESSION: {doc_id} | {datetime.now(timezone.utc).isoformat()} ---\n")
            for trace_line in final_state.get("reasoning_trace", []):
                log_file.write(f"{trace_line}\n")
            log_file.write("--- END SESSION ---\n")

        # 4. Database Writeback
        classification = final_state.get("current_classification", {})
        dispatches = final_state.get("resource_dispatches", [])

        db.collection("crisis_reports").document(doc_id).update({
            "status": "PROCESSED",
            "processed_by_ai": True,
            "ai_classification": classification,
            "ai_dispatches": dispatches,
            "ai_processed_at": firestore.SERVER_TIMESTAMP,
            "threat_level": classification.get("severity", "LOW")
        })

        logger.info(f"✅ Swarm completed for {doc_id}. Status: {classification.get('crisis_type')}")

    except Exception as e:
        logger.error(f"❌ Swarm Execution Failure for {doc_id}: {str(e)}")
        # Fallback: Update DB with error status
        db.collection("crisis_reports").document(doc_id).update({
            "status": "ERROR",
            "error_detail": str(e)
        })

# ──────────────────────────────────────────────────────────────────────────────
# FASTAPI APPLICATION
# ──────────────────────────────────────────────────────────────────────────────

# ... (rest of the file content before app instantiation)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan event to start background tasks like the Firebase listener."""
    start_firebase_listener()
    yield

app = FastAPI(title="Aegis-Omni Sovereign Gateway", version="2.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Tighten this up for production, but leave wide open for initial deployment
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ──────────────────────────────────────────────────────────────────────────────
# WEBSOCKET CONNECTION MANAGER
# ──────────────────────────────────────────────────────────────────────────────
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                # Handle stale connections gracefully during rapid live-reloads
                pass

manager = ConnectionManager()

@app.websocket("/stream/swarm")
async def swarm_stream(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Maintain connection alive heartbeat
            await asyncio.sleep(1)
    except WebSocketDisconnect:
        manager.disconnect(websocket)

# ──────────────────────────────────────────────────────────────────────────────
# REST API ENDPOINTS
# ──────────────────────────────────────────────────────────────────────────────

@app.post("/api/v1/sentinel/submit", tags=["Ingestion"])
async def submit_sentinel_signal(payload: SentinelPayload, background_tasks: BackgroundTasks):
    """
    REST Boundary: Receives telemetry and citizens reports.
    Uses BackgroundTasks for zero-lag client response.
    """
    logger.info(f"📥 Gateway Ingest: {payload.doc_id}")

    background_tasks.add_task(
        run_swarm_orchestration,
        payload.doc_id,
        payload.input_text,
        payload.weather,
        payload.traffic
    )

    return {
        "status": "ACCEPTED",
        "trace_id": payload.doc_id,
        "message": "Signal queued for Swarm Orchestration."
    }


# ──────────────────────────────────────────────────────────────────────────────
# FIREBASE LIVE LISTENER (LIFESPAN)
# ──────────────────────────────────────────────────────────────────────────────

def start_firebase_listener():
    """
    Attaches a live snapshot listener to Firestore.
    Bridges thread-callback to the async event loop.
    """
    loop = asyncio.get_event_loop()

    def on_snapshot(col_snapshot, changes, read_time):
        for change in changes:
            if change.type.name == "ADDED":
                doc = change.document
                data = doc.to_dict()

                # Filter for PENDING reports not yet processed
                if data.get("status") == "PENDING" and not data.get("processed_by_ai"):
                    doc_id = doc.id
                    incident_type = data.get("incident_type") or "CITIZEN_REPORT"
                    description = data.get("description") or data.get("text") or ""
                    input_text = f"{incident_type}: {description}"

                    # Fetch telemetry with safe fallbacks
                    sensor_data = data.get("sensor_data") or {}
                    rain_mm = sensor_data.get("rain_mm")
                    if rain_mm is None:
                        rain_mm = data.get("precipitation")
                    if rain_mm is None:
                        rain_mm = 0.0

                    humidity = sensor_data.get("humidity") or data.get("humidity") or 50.0
                    congestion = sensor_data.get("congestion") or data.get("congestion") or 10

                    weather = WeatherTelemetry(
                        precipitation=float(rain_mm),
                        humidity=float(humidity)
                    )
                    traffic = TrafficTelemetry(
                        congestion_level=int(congestion)
                    )

                    logger.info(f"🔥 Firebase Signal Detected: {doc_id}")

                    # Bridge to Async Loop
                    asyncio.run_coroutine_threadsafe(
                        run_swarm_orchestration(doc_id, input_text, weather, traffic),
                        loop
                    )

    logger.info("📡 Attaching Live Firestore Listener to 'crisis_reports'...")
    db.collection("crisis_reports").where(filter=FieldFilter("status", "==", "PENDING")).on_snapshot(on_snapshot)



# ──────────────────────────────────────────────────────────────────────────────
# MAIN ENTRY
# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
