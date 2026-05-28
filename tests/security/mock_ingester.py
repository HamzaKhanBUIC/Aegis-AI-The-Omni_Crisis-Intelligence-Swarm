"""
src/mock_ingester.py

AEGIS-OMNI MOCK DATA PIPELINE INGESTER
─────────────────────────────────────────────────────────────
Reads crisis_data.json and streams payloads into Firebase
Firestore's 'crisis_reports' collection at a controlled pace,
mimicking a live multi-source signal feed.

Usage (from Aegis-Omni-Master directory):
    .\\src\\venv\\Scripts\\python.exe src\\mock_ingester.py

The server (main_api.py) must be running to process these reports.
The Curveball scenario (MOCK-CURVEBALL-003) is injected 3rd and will
trigger the Zero-Trust ValidationSentinel automatically.
"""

import json
import logging
import os
import sys
import time
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore

# ──────────────────────────────────────────────────────────────────────────────
# SETUP LOGGING
# ──────────────────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="[MOCK-INGESTER] %(asctime)s - %(message)s"
)
logger = logging.getLogger("MockIngester")

# ──────────────────────────────────────────────────────────────────────────────
# FIREBASE INIT
# ──────────────────────────────────────────────────────────────────────────────
current_dir = os.path.dirname(os.path.abspath(__file__))
cred_path = os.path.join(current_dir, "serviceAccountKey.json")

if not os.path.exists(cred_path):
    logger.error(f"CRITICAL: serviceAccountKey.json missing at {cred_path}")
    sys.exit(1)

if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ──────────────────────────────────────────────────────────────────────────────
# LOAD MOCK DATA
# ──────────────────────────────────────────────────────────────────────────────
data_path = os.path.join(current_dir, "crisis_data.json")
if not os.path.exists(data_path):
    logger.error(f"CRITICAL: crisis_data.json missing at {data_path}")
    sys.exit(1)

with open(data_path, "r", encoding="utf-8") as f:
    MOCK_SCENARIOS = json.load(f)

STREAM_INTERVAL_SECONDS = 5  # Time between injections

# ──────────────────────────────────────────────────────────────────────────────
# BANNER
# ──────────────────────────────────────────────────────────────────────────────
def print_banner():
    print("\n" + "=" * 60)
    print("  [AEGIS-OMNI] MOCK DATA PIPELINE")
    print("  Sovereign Crisis Signal Emitter v1.0")
    print("=" * 60)
    print(f"  Loaded {len(MOCK_SCENARIOS)} scenario(s) from crisis_data.json")
    print(f"  Emission interval: {STREAM_INTERVAL_SECONDS}s per signal")
    print("  [!] Scenario 3 (MOCK-CURVEBALL-003) is the ZERO-TRUST TRAP")
    print("=" * 60 + "\n")

# ──────────────────────────────────────────────────────────────────────────────
# CORE INGESTION FUNCTION
# ──────────────────────────────────────────────────────────────────────────────
def emit_scenario(scenario: dict, index: int):
    """
    Transforms a crisis_data.json scenario into the exact Firestore
    data contract expected by main_api.py's on_snapshot listener.
    """
    doc_id = scenario["incident_id"]
    meta = scenario.get("_meta", {})
    is_curveball = "CURVEBALL" in doc_id.upper()

    print("\n" + "-" * 60)
    # Safely encode label for Windows cp1252 terminals (strips non-encodable chars)
    safe_label = meta.get('label', 'N/A').encode('cp1252', errors='replace').decode('cp1252')
    print(f"  [{index+1}/{len(MOCK_SCENARIOS)}] Emitting: {doc_id}")
    print(f"  Type   : {scenario.get('incident_type')}")
    print(f"  Label  : {safe_label}")

    if is_curveball:
        print("  [!!!] *** CURVEBALL SCENARIO ACTIVE ***")
        print("  [!!!] rain_mm=0.0 but social claims FLOODING")
        print("  [!!!] ValidationSentinel should intercept this!")

    # Build the payload matching the contract in main_api.py / simulate_citizen_report.py
    # The on_snapshot listener reads: incident_type, description, status,
    # processed_by_ai, sensor_data{rain_mm, humidity, tilt_sensor_reading, congestion}
    sensor_data = scenario.get("sensor_data", {})

    firestore_payload = {
        "incident_id": doc_id,
        "incident_type": scenario.get("incident_type", "UNKNOWN"),
        "description": scenario.get("description", ""),
        "status": "PENDING",              # CRITICAL: triggers the swarm listener
        "processed_by_ai": False,         # CRITICAL: prevents re-processing
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "source": "MOCK_INGESTER",
        "sensor_data": {
            # Fields consumed by WeatherTelemetry in main_api.py
            "rain_mm": sensor_data.get("rain_mm", 0.0),
            "humidity": sensor_data.get("humidity", 50.0),
            # Fields consumed by TrafficTelemetry
            "congestion": sensor_data.get("congestion", 10),
            # Additional fields for richer validation
            "tilt_sensor_reading": sensor_data.get("tilt_sensor_reading", "NORMAL"),
            "thermal_reading_celsius": sensor_data.get("thermal_reading_celsius", 30.0),
            "water_level_cm": sensor_data.get("water_level_cm", "normal"),
            "seismic_magnitude_richter": sensor_data.get("seismic_magnitude_richter", 0.0),
            "vehicle_velocity_kmh": sensor_data.get("vehicle_velocity_kmh", 0.0),
        },
        # Embed social signal metadata for dashboard display
        "social_signal": scenario.get("social_signal", {}),
        "_meta": meta,
    }

    # Push to Firestore — the on_snapshot listener in main_api.py will fire
    db.collection("crisis_reports").document(doc_id).set(firestore_payload)

    print(f"  [OK] Injected into Firestore -> crisis_reports/{doc_id}")
    print(f"  [..] Waiting {STREAM_INTERVAL_SECONDS}s before next emission...\n")

# ──────────────────────────────────────────────────────────────────────────────
# MAIN STREAM LOOP
# ──────────────────────────────────────────────────────────────────────────────
def run_pipeline():
    print_banner()
    print("  Starting emission loop. Watch your main_api.py terminal!\n")

    for i, scenario in enumerate(MOCK_SCENARIOS):
        try:
            emit_scenario(scenario, i)
        except Exception as e:
            logger.error(f"Failed to emit scenario {scenario.get('incident_id')}: {e}")

        # Wait between emissions (skip wait after last one)
        if i < len(MOCK_SCENARIOS) - 1:
            time.sleep(STREAM_INTERVAL_SECONDS)

    print("\n" + "=" * 60)
    print("  [DONE] All mock scenarios emitted to Firestore.")
    print("  Check main_api.py terminal for Swarm processing logs.")
    print("  Check antigravity_trace_log.txt for the full audit trail.")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    run_pipeline()
