import os
import uuid
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
current_dir = os.path.dirname(os.path.abspath(__file__))
cred_path = os.path.join(current_dir, "serviceAccountKey.json")

if not os.path.exists(cred_path):
    print(f"Error: Could not find '{cred_path}'")
    exit(1)

if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

def submit_citizen_report():
    print("="*60)
    print(" 📱 AEGIS-OMNI CITIZEN REPORTING SIMULATOR ")
    print("="*60)

    incident_type = input("Incident Type (e.g. URBAN_FLOODING, CIVIL_UNREST, STRUCTURAL_PANIC): ").strip()
    description = input("Describe the situation: ").strip()

    print("\n[Optional] Inject Telemetry to test Verification:")
    rain_input = input("Rainfall in mm (press Enter for 0.0): ").strip()
    rain_mm = float(rain_input) if rain_input else 0.0

    tilt_input = input("Structural Tilt Sensor (e.g. NORMAL, ABNORMAL - press Enter for NORMAL): ").strip()
    tilt_sensor = tilt_input.upper() if tilt_input else "NORMAL"

    traffic_input = input("Traffic Congestion Level (0-100 - press Enter for 85): ").strip()
    traffic_level = int(traffic_input) if traffic_input else 85

    doc_id = f"CITIZEN-REP-{uuid.uuid4().hex[:6].upper()}"

    payload = {
        "incident_id": doc_id,
        "incident_type": incident_type,
        "description": description,
        "status": "PENDING",  # This triggers the Swarm Listener!
        "processed_by_ai": False,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "sensor_data": {
            "rain_mm": rain_mm,
            "humidity": 60.0,
            "tilt_sensor_reading": tilt_sensor,
            "congestion": traffic_level
        }
    }

    # Push to Firebase
    db.collection("crisis_reports").document(doc_id).set(payload)

    print("\n✅ Report Submitted to Firebase!")
    print(f"Document ID: {doc_id}")
    print("Check your terminal running 'main_api.py' to watch the Swarm process this in real-time.")

if __name__ == "__main__":
    submit_citizen_report()
