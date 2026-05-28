"""
src/agents/state.py
Sovereign State definition for the LangGraph agents.
"""

from typing import Any, Dict, List, TypedDict


class AgentState(TypedDict):
    doc_id: str
    incoming_signals: Dict[str, Any]
    current_classification: Dict[str, Any]
    cascading_threats: List[str]
    resource_dispatches: List[Dict[str, Any]]
    reasoning_trace: List[str]
    sensor_telemetry: Dict[str, float]
