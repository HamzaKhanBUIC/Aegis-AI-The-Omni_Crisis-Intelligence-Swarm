import asyncio
import sys
import os

# ──────────────────────────────────────────────────────────────────────────────
# SYSTEM PATH CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────
# Ensure the parent directory is in sys.path so we can import 'backend_swarm' 
# as a package. This allows the import path specified in the request to function.
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

# Import the compiled aegis_swarm_engine
try:
    from backend_swarm.core_engine.graph import aegis_swarm_engine
except ImportError as e:
    print(f"Import Error: {e}")
    print("Ensure you are running this script from the backend_swarm directory or have the parent directory in PYTHONPATH.")
    sys.exit(1)

# ──────────────────────────────────────────────────────────────────────────────
# 'CURVEBALL' TEST SUITE
# ──────────────────────────────────────────────────────────────────────────────

async def test_curveball_scenario():
    """
    Initializes and executes the exact 'Curveball' state.
    
    A 'Curveball' occurs when social media reports a massive flood, but physical
    weather sensors report 0.0mm of rain. The swarm must detect this discrepancy
    in the routing layer and engage the ValidationSentinel to reclassify the
    event (e.g., as a water main burst pipe).
    """
    print("\n" + "="*80)
    print(" AEGIS-OMNI CORE ENGINE · 'CURVEBALL' DISCREPANCY TEST ".center(80, "="))
    print("="*80)

    # 1. INITIALIZE THE EXACT 'CURVEBALL' STATE
    # Note: 'social_text' keyword triggers the FLOODING classification in Mock Mode
    # Note: 'rain_mm' = 0.0 triggers the Zero-Trust Routing Discrepancy
    test_state = {
        "doc_id": "TEST-SNSR-CONFLICT-99",
        "incoming_signals": {
            "social_text": "Massive flooding on Karsaz Road! Water is rising rapidly. We need rescue teams now!",
            "source": "CITIZEN_REPORT_LIVE"
        },
        "current_classification": {},
        "resource_dispatches": [],
        "reasoning_trace": [],
        "sensor_telemetry": {
            "rain_mm": 0.0,  # THE CURVEBALL: Zero precipitation recorded
            "humidity": 45.2,
            "wind_speed_kph": 12.0
        }
    }

    print(f"[*] INITIALIZED STATE: Doc ID {test_state['doc_id']}")
    print(f"[*] SIGNAL: '{test_state['incoming_signals']['social_text'][:50]}...'")
    print(f"[*] SENSOR TELEMETRY: Rain = {test_state['sensor_telemetry']['rain_mm']}mm")
    print("\n[*] INVOKING SWARM ENGINE ...\n")

    try:
        # 2. INVOKE THE GRAPH
        # aegis_swarm_engine.ainvoke is the asynchronous entry point for LangGraph
        final_state = await aegis_swarm_engine.ainvoke(test_state)

        # 3. OUTPUT THE REASONING TRACE
        print("+ " + "-"*78 + " +")
        print("|" + " SWARM REASONING TRACE ".center(78) + "|")
        print("+ " + "-"*78 + " +")
        for trace in final_state.get("reasoning_trace", []):
            print(f"  -> {trace}")
        print("+ " + "-"*78 + " +")

        # 4. OUTPUT FINAL CONCLUSIONS
        classification = final_state.get("current_classification", {})
        crisis_type = classification.get("crisis_type", "UNKNOWN")
        severity = classification.get("severity", "UNKNOWN")
        
        print("\n" + "="*80)
        print(f" FINAL CRISIS TYPE : {crisis_type}")
        print(f" SEVERITY LEVEL    : {severity}")
        print("="*80)

        # Verification of Curveball Resolution
        if crisis_type == "INFRASTRUCTURE_BURST_PIPE":
            print("\n[SUCCESS] Test Passed: Discrepancy detected. Flood reclassified to Burst Pipe.")
        else:
            print("\n[FAILED] Test Failed: Discrepancy was not resolved correctly.")

    except Exception as e:
        print(f"\n[CRITICAL ERROR] Engine invocation failed: {e}")

if __name__ == "__main__":
    # Ensure uvicorn or other async loops don't conflict
    asyncio.run(test_curveball_scenario())
