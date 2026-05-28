"""
chaos_injector.py

Aegis-Omni Stress-Test: CHAOS INJECTOR
──────────────────────────────────────
Simulates a rapid spike in civic crisis reports by injecting realistic 
scenarios directly into the Firestore 'crisis_reports' collection.
Designed to test the async responsiveness of the Swarm Intelligence backend.
"""

import asyncio
import json
import os
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, firestore


# --- STYLIZED TERMINAL OUTPUT ---
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_missile_launch(doc_id, incident_type):
    """Prints a 'Missile Launched' style confirmation to the console."""
    print(f"{Colors.OKCYAN}[SYSTEM]{Colors.ENDC} {Colors.BOLD}WARHEAD ARMED:{Colors.ENDC} {doc_id}")
    print(f"{Colors.FAIL}[LAUNCH]{Colors.ENDC} Payload Type: {Colors.WARNING}{incident_type}{Colors.ENDC} | Target: {Colors.OKBLUE}Firestore/crisis_reports{Colors.ENDC}")
    print(f"{Colors.OKGREEN}[HIT]{Colors.ENDC} {Colors.BOLD}MISSILE LAUNCHED SUCCESSFULLY.{Colors.ENDC}")
    print("-" * 60)

async def inject_chaos():
    """
    Main injection engine. Reads crisis_data.json and pushes documents to Firestore.
    """
    # 🔑 Initialize Firebase
    cred_path = './serviceAccountKey.json'
    if not os.path.exists(cred_path):
        print(f"{Colors.FAIL}[ERROR]{Colors.ENDC} Service Account Key not found. Please place 'serviceAccountKey.json' in root.")
        return

    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    # 🧪 Read Crisis Data
    data_path = './crisis_data.json'
    if not os.path.exists(data_path):
        print(f"{Colors.FAIL}[ERROR]{Colors.ENDC} crisis_data.json not found.")
        return

    with open(data_path, 'r') as f:
        payloads = json.load(f)

    print(f"\n{Colors.HEADER}{Colors.BOLD}=== AEGIS-OMNI CHAOS INJECTION SEQUENCE INITIALIZED ==={Colors.ENDC}\n")
    print(f"{Colors.OKBLUE}[INIT]{Colors.ENDC} Target: Karachi Intelligence Grid")
    print(f"{Colors.OKBLUE}[INIT]{Colors.ENDC} Payload Count: {len(payloads)}")
    print(f"{Colors.OKBLUE}[INIT]{Colors.ENDC} Rate: 1 Signal / 2 Seconds")
    print("\n" + "=" * 60 + "\n")

    for payload in payloads:
        # Update timestamp to current to keep it 'real-time'
        payload['timestamp'] = datetime.utcnow().isoformat() + 'Z'

        # Inject into 'crisis_reports' (The collection the Swarm Listener is watching)
        doc_ref = db.collection('crisis_reports').document(payload['incident_id'])
        doc_ref.set(payload)

        # Stylized confirmation
        print_missile_launch(payload['incident_id'], payload['incident_type'])

        # Simulate rapid spike with a 2-second delay
        await asyncio.sleep(2)

    print(f"\n{Colors.OKGREEN}{Colors.BOLD}=== INJECTION SEQUENCE COMPLETE. SWARM SHOULD BE ENGAGED. ==={Colors.ENDC}\n")

if __name__ == "__main__":
    try:
        asyncio.run(inject_chaos())
    except KeyboardInterrupt:
        print(f"\n{Colors.FAIL}[ABORT]{Colors.ENDC} Injection sequence cancelled by operator.")
