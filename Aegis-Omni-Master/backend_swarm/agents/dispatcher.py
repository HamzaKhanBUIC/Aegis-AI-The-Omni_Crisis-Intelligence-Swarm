"""
backend_swarm/agents/dispatcher.py

Aegis-Omni Swarm — DISPATCHER AGENT  (Command Logistics Controller · Karachi)
───────────────────────────────────────────────────────────────────────────────
Third node in the intelligence pipeline. Reads the validated crisis
classification and allocates real Karachi emergency assets from a finite pool:

  • KWSB      — Karachi Water & Sewerage Board repair crews
  • KE        — K-Electric field engineers
  • RESCUE_1122 — Sindh Rescue 1122 ambulances / rapid-response units
  • TRAFFIC_POLICE — District Traffic Police units

Uses the same Llama-3-70B-Instruct / LangChain pipeline as the Triage Agent
so the entire swarm is architecturally consistent.

State contract (keys read / written):
  READ  : current_classification (dict), incoming_signals (dict)
  WRITE : resource_dispatches (list[dict]), reasoning_trace (list[str])
"""

import os
import json
import logging
from typing import Any

from dotenv import load_dotenv
from dotenv import load_dotenv
from huggingface_hub import InferenceClient

load_dotenv()

logger = logging.getLogger("AegisSwarm.DispatcherAgent")
logging.basicConfig(level=logging.INFO)

# ──────────────────────────────────────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────────────────────────────────────
HF_API_TOKEN: str = os.getenv("HF_API_TOKEN", "")
HF_MODEL_ID: str = "meta-llama/Meta-Llama-3-70B-Instruct"
USE_LIVE_AI: bool = os.getenv("USE_LIVE_AI", "False").lower() == "true"

client = InferenceClient(model=HF_MODEL_ID, token=HF_API_TOKEN)


# ──────────────────────────────────────────────────────────────────────────────
# System Directive — Command Logistics Controller
# ──────────────────────────────────────────────────────────────────────────────
_DISPATCHER_SYSTEM_PROMPT = """\
You are the Command Logistics Controller for the Karachi Emergency Response \
Framework. You manage a finite pool of municipal assets: Karachi Water & \
Sewerage Board (KWSB) repair crews, K-Electric field engineers, Sindh Rescue \
1122 ambulances, and District Traffic Police units.

Your job is to read the verified threat assessment and allocate assets where \
they will preserve the most infrastructure and prevent human casualty.

### CONSTRAINT RULES
- Rescue 1122 and Traffic units take absolute priority if there is a threat \
  to human life.
- Engineering crews (KWSB/K-Electric) must be routed to the exact \
  coordinate/source of the structural failure, not the generic area of effect.
- If multiple crises exist, optimize by severity and population density \
  (e.g., prioritizing a high-density zone like Saddar or Gulshan over a \
  lower-density industrial or residential periphery).

### OUTPUT SCHEMA
You MUST respond ONLY with a valid JSON object matching this structure exactly. \
Do not include preambles, markdown fences, or conversational filler:
{
  "allocated_units": [
    {
      "agency": "STRING (one of: KWSB, KE, RESCUE_1122, TRAFFIC_POLICE)",
      "unit_count": "INTEGER",
      "target_location": "STRING (specific coordinate or named location in Karachi)",
      "objective": "STRING (precise operational task for this unit)"
    }
  ],
  "allocation_rationale": "STRING (Explicitly justify why these resources were \
committed here and what trade-offs were made under constraints.)"
}
"""


# ──────────────────────────────────────────────────────────────────────────────
# Mock fallback — deterministic asset allocations for demo mode
# ──────────────────────────────────────────────────────────────────────────────
def _mock_dispatch(classification: dict, incoming_signals: dict) -> dict:
    """
    Returns a realistic but hardcoded resource dispatch plan based on the
    crisis_type from the current_classification.
    Used when USE_LIVE_AI=False or when the LLM pipeline fails.
    """
    logger.warning(
        "[DISPATCHER] MOCK-MODE ACTIVE — LLM pipeline bypassed. "
        "Returning deterministic demo dispatch plan."
    )

    crisis_type: str = classification.get("crisis_type", "UNKNOWN").upper()
    severity: str = classification.get("severity", "LOW").upper()
    override_applied: bool = classification.get("override_applied", False)

    # ── Scenario: Curveball burst pipe (post-validator override) ──────────────
    if override_applied or "BURST_PIPE" in crisis_type or "INFRASTRUCTURE" in crisis_type:
        return {
            "allocated_units": [
                {
                    "agency": "KWSB",
                    "unit_count": 4,
                    "target_location": "Underground main junction, G-10/2 near Ibn-e-Sina Road",
                    "objective": (
                        "Locate and isolate burst high-pressure water main. "
                        "Deploy emergency pipe clamps and divert flow to secondary loop."
                    ),
                },
                {
                    "agency": "TRAFFIC_POLICE",
                    "unit_count": 6,
                    "target_location": "Murree Road / Peshawar Road intersection, G-10",
                    "objective": (
                        "Establish road closure perimeter around flooded surface area. "
                        "Re-route vehicular traffic via Kashmir Highway."
                    ),
                },
                {
                    "agency": "RESCUE_1122",
                    "unit_count": 2,
                    "target_location": "G-10 Markaz, standby at sector entry point",
                    "objective": (
                        "Standby for any civilian injury during pipe repair operations. "
                        "No flood-rescue deployment — infrastructure source confirmed, not weather."
                    ),
                },
            ],
            "allocation_rationale": (
                "Crisis confirmed as INFRASTRUCTURE_BURST_PIPE (MEDIUM severity) — "
                "NOT a weather flood. KWSB crews take operational lead targeting the "
                "exact pipe junction. Rescue 1122 placed on standby (not forward-deployed) "
                "as human life risk is low. No KWSB flood-pump resources allocated; "
                "storm-drain equipment would be wasteful without a meteorological source."
            ),
        }

    # ── Scenario: Genuine flooding (CATASTROPHIC) ─────────────────────────────
    if "FLOOD" in crisis_type and severity in ("CATASTROPHIC", "HIGH"):
        return {
            "allocated_units": [
                {
                    "agency": "RESCUE_1122",
                    "unit_count": 12,
                    "target_location": "Gulshan-e-Iqbal, Lyari Expressway on-ramps, Clifton Block 2",
                    "objective": (
                        "Immediate life-rescue operations in high-density submerged zones. "
                        "Prioritize Lyari and Gulshan given peak population density."
                    ),
                },
                {
                    "agency": "KWSB",
                    "unit_count": 6,
                    "target_location": "Lyari River drain outfall, Korangi pumping station",
                    "objective": (
                        "Activate emergency storm-drain pumps and clear blockages "
                        "to accelerate water recession from arterial roads."
                    ),
                },
                {
                    "agency": "TRAFFIC_POLICE",
                    "unit_count": 10,
                    "target_location": "Shahrae Faisal, MA Jinnah Road, University Road junctions",
                    "objective": (
                        "Close submerged arterial routes, direct emergency vehicles via "
                        "Northern Bypass and Super Highway to avoid gridlock."
                    ),
                },
                {
                    "agency": "KE",
                    "unit_count": 4,
                    "target_location": "K-Electric grid substations: SITE, Baldia, Landhi",
                    "objective": (
                        "Pre-emptively isolate low-lying substation feeders to prevent "
                        "high-tension trips and electrocution risk in flooded streets."
                    ),
                },
            ],
            "allocation_rationale": (
                "CATASTROPHIC urban flood threatens multi-town life safety. Rescue 1122 "
                "deployed in force (12 units) to highest-density zones first (Lyari, Gulshan). "
                "KWSB pump activation addresses root hydrological cause. K-Electric isolation "
                "is a life-safety prerequisite — electrocution in standing water is the #1 "
                "secondary fatality vector in Karachi monsoon events."
            ),
        }

    # ── Scenario: Power outage ────────────────────────────────────────────────
    if "POWER" in crisis_type or "OUTAGE" in crisis_type:
        return {
            "allocated_units": [
                {
                    "agency": "KE",
                    "unit_count": 5,
                    "target_location": "Affected feeder substation (cross-reference signal zone)",
                    "objective": (
                        "Diagnose high-tension trip cause, restore feeder within SLA. "
                        "Prioritize hospitals, Rescue 1122 stations, and water pumping facilities."
                    ),
                },
                {
                    "agency": "TRAFFIC_POLICE",
                    "unit_count": 3,
                    "target_location": "Major intersections in blackout zone",
                    "objective": (
                        "Manual traffic control at signal-dark junctions to prevent "
                        "gridlock and keep emergency corridors clear."
                    ),
                },
            ],
            "allocation_rationale": (
                "MEDIUM-severity power outage; K-Electric engineers are the primary resource. "
                "Traffic Police deployed to prevent secondary gridlock from signal failures. "
                "No Rescue 1122 forward-deployment unless medical facilities are affected."
            ),
        }

    # ── Default minimal response ──────────────────────────────────────────────
    return {
        "allocated_units": [
            {
                "agency": "RESCUE_1122",
                "unit_count": 1,
                "target_location": "Nearest district headquarters to reported signal zone",
                "objective": "Monitor and assess. Deploy only on confirmed life-threat escalation.",
            }
        ],
        "allocation_rationale": (
            "Crisis type UNKNOWN or severity LOW. Minimal standby posture adopted. "
            "No large-scale resource commitment until further signal corroboration."
        ),
    }


# ──────────────────────────────────────────────────────────────────────────────
# Core dispatcher function
# ──────────────────────────────────────────────────────────────────────────────
def run_dispatcher_agent(state: dict[str, Any]) -> dict[str, Any]:
    """
    LangGraph node — Dispatcher / Command Logistics Controller Agent.

    Reads  : state["current_classification"], state["incoming_signals"]
    Writes : state["resource_dispatches"], state["reasoning_trace"]

    Parameters
    ----------
    state : dict
        The shared LangGraph swarm state dictionary.

    Returns
    -------
    dict
        A partial state update containing 'resource_dispatches' and an
        appended 'reasoning_trace' list.
    """
    logger.info("[DISPATCHER] Node activated. Computing resource allocation plan.")

    classification: dict = state.get("current_classification", {})
    incoming_signals: dict = state.get("incoming_signals", {})
    reasoning_trace: list[str] = list(state.get("reasoning_trace", []))

    # ── Step 1: Snapshot classification for the audit trail ───────────────────
    crisis_type = classification.get("crisis_type", "UNKNOWN")
    severity = classification.get("severity", "LOW")
    population = classification.get("affected_population", 0)
    override_applied = classification.get("override_applied", False)

    reasoning_trace.append(
        f"[DISPATCHER · STEP 1] Logistics Controller activated. "
        f"Reading validated classification → "
        f"crisis_type='{crisis_type}' | severity='{severity}' | "
        f"affected_population={population} | override_applied={override_applied}."
    )
    logger.info(
        f"[DISPATCHER] Planning dispatch for: {crisis_type} / {severity} "
        f"(pop={population}, override={override_applied})"
    )

    # ── Step 2: Determine execution mode ─────────────────────────────────────
    if not USE_LIVE_AI:
        dispatch_plan = _mock_dispatch(classification, incoming_signals)
        reasoning_trace.append(
            "[DISPATCHER · STEP 2] MOCK-MODE: LLM pipeline disabled. "
            "Dispatch plan generated from deterministic rule-based allocator."
        )
    else:
        # ── Step 3: Build message objects ───────────────────────────
        system_prompt = _DISPATCHER_SYSTEM_PROMPT
        human_input = (
            f"Verified Threat Assessment: {json.dumps(classification, ensure_ascii=False)}\n\n"
            f"Supporting Signal Context: {json.dumps(incoming_signals, ensure_ascii=False)}"
        )

        reasoning_trace.append(
            f"[DISPATCHER · STEP 2] Constructing message pipeline for "
            f"{HF_MODEL_ID}."
        )
        logger.info("[DISPATCHER] Invoking InferenceClient LLM pipeline …")

        try:
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": human_input}
            ]
            response = client.chat_completion(
                messages=messages,
                temperature=0.1,
                max_tokens=768
            )

            raw_content: str = response.choices[0].message.content.strip()

            # Strip markdown code fences if the model wraps its JSON
            if raw_content.startswith("```"):
                raw_content = raw_content.split("```")[1]
                if raw_content.startswith("json"):
                    raw_content = raw_content[4:]

            dispatch_plan: dict = json.loads(raw_content)

            reasoning_trace.append(
                f"[DISPATCHER · STEP 3] LLM responded successfully. "
                f"Raw output snippet: {raw_content[:200]}…"
            )
            logger.info(f"[DISPATCHER] Raw LLM output snippet: {raw_content[:200]}")

        except json.JSONDecodeError as exc:
            logger.error(f"[DISPATCHER] JSON parse failed: {exc}. Engaging fallback.")
            reasoning_trace.append(
                f"[DISPATCHER · STEP 3 — ERROR] JSON decode failed ({exc}). "
                "Engaging deterministic fallback allocator."
            )
            dispatch_plan = _mock_dispatch(classification, incoming_signals)

        except Exception as exc:  # noqa: BLE001
            logger.error(f"[DISPATCHER] LLM pipeline failed: {exc}. Engaging fallback.")
            reasoning_trace.append(
                f"[DISPATCHER · STEP 3 — ERROR] LLM pipeline raised "
                f"{type(exc).__name__}: {exc}. Engaging deterministic fallback allocator."
            )
            dispatch_plan = _mock_dispatch(classification, incoming_signals)

    # ── Step 4: Validate the dispatch plan structure ──────────────────────────
    allocated_units: list[dict] = dispatch_plan.get("allocated_units", [])
    allocation_rationale: str = dispatch_plan.get(
        "allocation_rationale", "Rationale unavailable."
    )

    if not allocated_units:
        logger.warning("[DISPATCHER] LLM returned empty allocated_units. Applying minimal standby.")
        reasoning_trace.append(
            "[DISPATCHER · STEP 4 — WARNING] Dispatch plan contained no allocated units. "
            "Applying minimal RESCUE_1122 standby as safety net."
        )
        allocated_units = [
            {
                "agency": "RESCUE_1122",
                "unit_count": 1,
                "target_location": "Central staging area",
                "objective": "Standby pending further signal corroboration.",
            }
        ]

    unit_count_total = sum(u.get("unit_count", 0) for u in allocated_units)
    agencies_deployed = list({u.get("agency", "UNKNOWN") for u in allocated_units})

    reasoning_trace.append(
        f"[DISPATCHER · STEP 4] Dispatch plan validated. "
        f"Total units committed: {unit_count_total} across {len(allocated_units)} deployment(s). "
        f"Agencies activated: {agencies_deployed}."
    )
    reasoning_trace.append(
        f"[DISPATCHER · STEP 4 — RATIONALE] {allocation_rationale}"
    )

    logger.info(
        f"[DISPATCHER] Dispatch complete — "
        f"{unit_count_total} total units → {agencies_deployed}"
    )

    # ── Return partial state update ───────────────────────────────────────────
    return {
        "resource_dispatches": allocated_units,
        "reasoning_trace": reasoning_trace,
    }
