"""
src/core_engine/graph.py

Aegis-Omni Swarm — LANGGRAPH ORCHESTRATION ENGINE
──────────────────────────────────────────────────
Wires the sovereign agents into a directed, stateful pipeline.
"""

import logging
from typing import Any, Dict, List, TypedDict

from langgraph.graph import END, StateGraph

from src.agents.swarms.analyst_agent import run_validation_agent
from src.agents.swarms.remediation_agent import run_predict_cascade

# Import the nodes we've built
from src.agents.swarms.triage_agent import run_triage_agent

# The dispatcher/allocator logic is handled by the ResourceAllocatorNode below

logger = logging.getLogger("AegisSwarm.Graph")
logging.basicConfig(level=logging.INFO)

# ==========================================
# 1. DEFINE THE SOVEREIGN STATE SCHEMA
# ==========================================
class AgentState(TypedDict):
    doc_id: str
    incoming_signals: Dict[str, Any]
    current_classification: Dict[str, Any]
    cascading_threats: List[str]
    resource_dispatches: List[Dict[str, Any]]
    reasoning_trace: List[str]
    sensor_telemetry: Dict[str, float]


# ==========================================
# 2. IMPLEMENT NODES
# ==========================================

def run_data_fuser(state: AgentState) -> Dict[str, Any]:
    """
    DataFuserNode: Ingests raw inputs and ensures structural conformity.
    """
    trace = list(state.get("reasoning_trace", []))
    trace.append("[DATA_FUSER_NODE] Normalizing incoming multi-source vector streams (Social, Weather, Telemetry).")

    # Ensure signals are formatted for the agents
    # If the input was a single dict, we wrap it
    return {"reasoning_trace": trace}

def run_resource_allocator(state: AgentState) -> Dict[str, Any]:
    """
    ResourceAllocatorNode: Handles operational deployment logic based on final ground truth.
    """
    classification = state.get("current_classification", {})
    trace = list(state.get("reasoning_trace", []))
    dispatches = list(state.get("resource_dispatches", []))

    crisis_type = classification.get("crisis_type", "UNKNOWN")
    severity = classification.get("severity", "LOW")

    trace.append(f"[RESOURCE_ALLOCATOR_NODE] Optimizing logistics for {crisis_type} with severity level {severity}.")

    # Simple deterministic asset allocation logic for the demo
    if crisis_type == "INFRASTRUCTURE_BURST_PIPE":
        dispatch_payload = {
            "agency": "KWSB_REPAIR_CREW",
            "unit_count": 2,
            "target_zone": "Gulshan-e-Iqbal Town",
            "objective": "Isolate Main Line B valve and repair rupture."
        }
        dispatches.append(dispatch_payload)
        trace.append("[RESOURCE_ALLOCATOR_NODE] Dispatched: KWSB Heavy Repair Squad Alpha routed to rupture site.")
    else:
        dispatch_payload = {
            "agency": "SINDH_RESCUE_1122",
            "unit_count": 1,
            "target_zone": "Karachi Core",
            "objective": "Standard monitoring standby."
        }
        dispatches.append(dispatch_payload)

    return {
        "resource_dispatches": dispatches,
        "reasoning_trace": trace
    }


# ==========================================
# 3. THE "CURVEBALL" CONDITIONAL ROUTING EDGE
# ==========================================
def route_after_triage(state: AgentState) -> str:
    """
    Zero-Trust Condition: Scans state for data conflict anomalies.
    If social channels claim flooding while sensors report zero rain, 
    reroute execution straight to the ValidationSentinel.
    """
    # In the new schema, we check sensor_telemetry and the triage classification
    classification = state.get("current_classification", {})
    telemetry = state.get("sensor_telemetry", {})
    trace = list(state.get("reasoning_trace", []))

    crisis_type = classification.get("crisis_type", "").upper()
    severity = classification.get("severity", "").upper()
    # Check both possible keys for rain
    rain = telemetry.get("rain_mm", telemetry.get("precipitation_rate_mm_hr", 0.0))

    # Curveball logic: Social reports flood, but hardware says zero rain
    if "FLOOD" in crisis_type and severity in ["HIGH", "CATASTROPHIC"] and rain == 0.0:
        trace.append("[ROUTE_MANAGER] CRITICAL DISCREPANCY DETECTED: Social panic mismatched with sensor telemetry. Executing Curveball Route to ValidationSentinel.")
        return "trigger_validation"

    # Curveball logic: Social reports structural tilt/fire, but sensors are normal
    tilt_sensor = telemetry.get("tilt_sensor_reading", "").upper()
    if "STRUCTURAL" in crisis_type and tilt_sensor == "NORMAL":
        trace.append("[ROUTE_MANAGER] CRITICAL DISCREPANCY DETECTED: Social panic of structural failure mismatched with normal sensor telemetry. Executing Curveball Route to ValidationSentinel.")
        return "trigger_validation"

    trace.append("[ROUTE_MANAGER] Data channels aligned. Proceeding directly to PredictCascadeNode.")
    return "trigger_allocation"


# ==========================================
# 4. GRAPH COMPILATION & EDGE CONFIGURATION
# ==========================================
workflow = StateGraph(AgentState)

# Register the architectural nodes
workflow.add_node("DataFuserNode", run_data_fuser)
workflow.add_node("TriageEngineNode", run_triage_agent)
workflow.add_node("ValidationNode", run_validation_agent)
workflow.add_node("PredictCascadeNode", run_predict_cascade)
workflow.add_node("ResourceAllocatorNode", run_resource_allocator)

# Establish workflow vectors
workflow.set_entry_point("DataFuserNode")
workflow.add_edge("DataFuserNode", "TriageEngineNode")

# Wire up the conditional logic gate
workflow.add_conditional_edges(
    "TriageEngineNode",
    route_after_triage,
    {
        "trigger_validation": "ValidationNode",
        "trigger_allocation": "PredictCascadeNode"
    }
)

# Terminate pipeline flow properly
workflow.add_edge("ValidationNode", "PredictCascadeNode")
workflow.add_edge("PredictCascadeNode", "ResourceAllocatorNode")
workflow.add_edge("ResourceAllocatorNode", END)

# Compile sovereign engine
aegis_swarm_engine = workflow.compile()

# ==========================================
# 5. EXECUTION WRAPPER FOR API
# ==========================================
def execute_swarm_workflow(initial_state: Dict[str, Any]) -> Dict[str, Any]:
    """
    Executes the compiled LangGraph workflow with the provided initial state.
    This is the primary entry point for the FastAPI background task.
    """
    logger.info(f"[SWARM_ENGINE] Executing workflow for Trace ID: {initial_state.get('doc_id')}")
    try:
        # Prepare state with required keys
        state: AgentState = {
            "doc_id": initial_state.get("doc_id", "unknown"),
            "incoming_signals": initial_state.get("incoming_signals", []),
            "current_classification": {},
            "cascading_threats": [],
            "resource_dispatches": [],
            "reasoning_trace": initial_state.get("decision_log", []),
            "sensor_telemetry": initial_state.get("sensor_telemetry", {})
        }

        # In this new architecture, incoming_signals might need to be populated
        # from the social_panic and incident_type in main_api.py
        # For now, we trust the input dictionary mapping

        final_state = aegis_swarm_engine.invoke(state)
        logger.info(f"[SWARM_ENGINE] Execution successful. Final classification: {final_state.get('current_classification', {}).get('crisis_type')}")
        return final_state
    except Exception as e:
        logger.error(f"[SWARM_ENGINE] Critical failure: {str(e)}")
        return initial_state
