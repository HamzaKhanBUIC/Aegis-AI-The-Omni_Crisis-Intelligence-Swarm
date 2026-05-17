import asyncio
import sys
import os
import json

# Ensure the parent directory is in sys.path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from backend_swarm.core_engine.graph import aegis_swarm_engine

async def test_integration():
    data_file = os.path.join(current_dir, "crisis_data.json")
    
    if not os.path.exists(data_file):
        print(f"Error: Could not find '{data_file}'")
        return
        
    with open(data_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        data = [data]

    print("\n" + "="*80)
    print(" AEGIS-OMNI CORE ENGINE · INTEGRATION TEST ".center(80, "="))
    print("="*80)
    
    for index, payload in enumerate(data, start=1):
        print(f"\n--- Processing Incident {index}: {payload.get('incident_id', 'UNKNOWN')} ---")
        
        initial_state = {
            "doc_id": payload.get("incident_id", "TEST-DOC-ID"),
            "incoming_signals": {
                "social_text": payload.get("description", payload.get("social_signal", {}).get("sample_text", "")),
                "social_media_sentiment": payload.get("social_signal", {}).get("sentiment_score", -0.5),
                "source": "CITIZEN_REPORT_LIVE"
            },
            "current_classification": {},
            "resource_dispatches": [],
            "reasoning_trace": [],
            "sensor_telemetry": payload.get("sensor_data", {})
        }

        try:
            final_state = await aegis_swarm_engine.ainvoke(initial_state)

            print("+ " + "-"*78 + " +")
            print("|" + f" SWARM REASONING TRACE - {payload.get('incident_id')} ".center(78) + "|")
            print("+ " + "-"*78 + " +")
            for trace in final_state.get("reasoning_trace", []):
                print(f"  -> {trace}")
            print("+ " + "-"*78 + " +")

            classification = final_state.get("current_classification", {})
            crisis_type = classification.get("crisis_type", "UNKNOWN")
            severity = classification.get("severity", "UNKNOWN")
            
            print(f"\n FINAL CRISIS TYPE : {crisis_type}")
            print(f" SEVERITY LEVEL    : {severity}")
            
        except Exception as e:
            print(f"\n[CRITICAL ERROR] Engine invocation failed for incident {index}: {e}")

if __name__ == "__main__":
    asyncio.run(test_integration())
