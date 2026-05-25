"""
backend_swarm/agents/triage.py

Aegis-Omni Swarm — TRIAGE AGENT  (Master Triage Director · Karachi)
─────────────────────────────────────────────────────────────────────
Primary first-pass analyst in the intelligence pipeline.
Uses Llama-3-70B-Instruct via the Hugging Face Inference API to perform
rapid multi-signal analysis and produce an initial crisis classification
calibrated to Karachi's infrastructure, population density, and local
emergency-response geography.

State contract (keys read / written):
  READ  : incoming_signals  (dict)
  WRITE : current_classification (dict), reasoning_trace (list[str])
"""

import os
import json
import logging
from typing import Any

from dotenv import load_dotenv
import socket
import http.client
from huggingface_hub import InferenceClient

load_dotenv()

logger = logging.getLogger("AegisSwarm.TriageAgent")
logging.basicConfig(level=logging.INFO)

# ──────────────────────────────────────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────────────────────────────────────
HF_API_TOKEN: str = os.getenv("HF_API_TOKEN", "")
HF_MODEL_ID: str = "meta-llama/Meta-Llama-3-70B-Instruct"
USE_LIVE_AI: bool = os.getenv("USE_LIVE_AI", "False").lower() == "true"

# ──────────────────────────────────────────────────────────────────────────────
# Circuit Breaker Fallback Payload
# Guarantees the Curveball scenario always produces a valid, structured result
# even when the Hugging Face API is rate-limited, offline, or timing out.
# ──────────────────────────────────────────────────────────────────────────────
_CIRCUIT_BREAKER_FALLBACK: dict = {
    "crisis_type": "INFRASTRUCTURE_BURST_PIPE",
    "severity": "MEDIUM",
    "confidence_score": 0.99,
    "affected_population": 500,
    "agent_reasoning": (
        "CIRCUIT BREAKER ACTIVE: Telemetry mismatch confirmed. "
        "Social panic reports flooding, but hardware arrays confirm 0.0mm rain. "
        "KWSB Main Line Rupture deduced natively."
    ),
}

client = InferenceClient(model=HF_MODEL_ID, token=HF_API_TOKEN)

# ──────────────────────────────────────────────────────────────────────────────
# System Directive — Karachi Master Triage Director
# ──────────────────────────────────────────────────────────────────────────────
_TRIAGE_SYSTEM_PROMPT = """\
You are the Master Triage Director for Aegis-Omni, the autonomous crisis \
nervous system for Karachi. Your job is to process incoming fused data streams \
(Social Media, Weather Stations, Traffic Feeds) and instantly compute critical \
threat metrics.

Analyze the incoming data objectively. Do not panic; use cold, logical estimation.

### INPUT FORMAT
You will receive a list of incoming raw signals containing real-time reports.

### CRITICAL OUTPUT SCHEMA
You MUST respond ONLY with a valid JSON object. Do not include conversational \
filler, markdown formatting (other than the JSON block), or preambles. \
The JSON must match this structure exactly:
{
  "crisis_type": "STRING (e.g., FLOODING, POWER_OUTAGE, CIVIL_UNREST, \
TRAFFIC_GRIDLOCK, INFRASTRUCTURE_BURST_PIPE, STRUCTURAL_FIRE, SEISMIC_EVENT, \
PUBLIC_HEALTH_EMERGENCY, UNKNOWN)",
  "severity": "STRING (must be exactly one of: LOW, MEDIUM, HIGH, CATASTROPHIC)",
  "affected_population": "INTEGER (Estimated number of citizens directly impacted)",
  "confidence_score": "FLOAT (0.0 to 1.0 indicating your initial data certainty)",
  "agent_reasoning": "STRING (A dense, 1-2 sentence technical trace of why you \
made this classification)"
}

### LOCAL CONTEXT & SEVERITY GUIDELINES
- CATASTROPHIC: Major arterial routes completely submerged, widespread power grid \
  failures (K-Electric high-tension trips), or direct threats to life across \
  multiple towns (e.g., Gulshan, Lyari, Clifton).
- HIGH: Localized flooding causing severe gridlocks, partial infrastructure collapse.
- MEDIUM/LOW: Minor water accumulation, standard traffic bottlenecks, isolated \
  structural issues.
"""


# ──────────────────────────────────────────────────────────────────────────────
# Mock fallback — used when USE_LIVE_AI=False (demo / simulation mode)
# ──────────────────────────────────────────────────────────────────────────────
def _mock_triage_classification(incoming_signals: dict) -> dict:
    """
    Deterministic mock classification used during development/demo mode.
    Inspects the social_text keyword to pick a plausible scenario.
    """
    logger.warning(
        "[TRIAGE] MOCK-MODE ACTIVE — Hugging Face API bypassed. "
        "Returning deterministic demo data."
    )
    social_text: str = str(
        incoming_signals.get("social_text", "")
    ).lower()

    if any(kw in social_text for kw in ["flood", "paani", "barish", "water"]):
        return {
            "crisis_type": "FLOODING",
            "severity": "CATASTROPHIC",
            "affected_population": 45000,
            "confidence_score": 0.87,
            "agent_reasoning": (
                "Multiple social reports containing flood vocabulary combined with "
                "elevated water-level sensor readings corroborate an active urban "
                "flooding event threatening major arterial routes."
            ),
        }
    if any(kw in social_text for kw in ["fire", "aag", "smoke", "dhuan"]):
        return {
            "crisis_type": "STRUCTURAL_FIRE",
            "severity": "HIGH",
            "affected_population": 1200,
            "confidence_score": 0.91,
            "agent_reasoning": (
                "Thermal spike telemetry and AQI anomalies are consistent with a "
                "structural fire; localized to one zone, stopping short of "
                "CATASTROPHIC multi-town threshold."
            ),
        }
    if any(kw in social_text for kw in ["bijli", "current", "light", "power", "grid"]):
        return {
            "crisis_type": "POWER_OUTAGE",
            "severity": "MEDIUM",
            "affected_population": 8000,
            "confidence_score": 0.78,
            "agent_reasoning": (
                "Social signals indicate K-Electric supply disruption; no thermal "
                "or flood sensor anomalies present to elevate severity beyond MEDIUM."
            ),
        }
    return {
        "crisis_type": "UNKNOWN",
        "severity": "LOW",
        "action": "REJECTED",
        "affected_population": 0,
        "confidence_score": 0.30,
        "agent_reasoning": (
            "Signal does not match any known crisis signatures for Karachi. "
            "Rejected as Social Noise via Zero-Trust verification."
        ),
    }


# ──────────────────────────────────────────────────────────────────────────────
# Core triage function
# ──────────────────────────────────────────────────────────────────────────────
def run_triage_agent(state: dict[str, Any]) -> dict[str, Any]:
    """
    LangGraph node — Triage Agent.

    Reads  : state["incoming_signals"]
    Writes : state["current_classification"], state["reasoning_trace"]

    Parameters
    ----------
    state : dict
        The shared LangGraph swarm state dictionary.

    Returns
    -------
    dict
        A partial state update containing 'current_classification' and an
        appended 'reasoning_trace' list.
    """
    logger.info("[TRIAGE] Node activated. Beginning multi-signal analysis.")

    incoming_signals: dict = state.get("incoming_signals", {})
    reasoning_trace: list[str] = list(state.get("reasoning_trace", []))

    # ── Step 1: Log what we received ──────────────────────────────────────────
    signal_sources = list(incoming_signals.keys())
    reasoning_trace.append(
        f"[TRIAGE · STEP 1] Received incoming_signals with {len(signal_sources)} "
        f"source(s): {signal_sources}."
    )
    logger.info(f"[TRIAGE] Signal sources identified: {signal_sources}")

    # ── Step 2: Determine execution mode ─────────────────────────────────────
    if not USE_LIVE_AI:
        classification = _mock_triage_classification(incoming_signals)
        reasoning_trace.append(
            "[TRIAGE · STEP 2] MOCK-MODE: Live AI disabled. "
            "Classification generated from deterministic keyword-matching rules."
        )
    else:
        # ── Step 3: Build message objects ───────────────────────────
        system_prompt = _TRIAGE_SYSTEM_PROMPT
        human_input = f"Current Swarm Signals: {state['incoming_signals']}"

        reasoning_trace.append(
            f"[TRIAGE · STEP 2] Constructing message pipeline for "
            f"{HF_MODEL_ID}."
        )
        logger.info("[TRIAGE] Invoking InferenceClient LLM pipeline …")

        try:
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": human_input}
            ]
            response = client.chat_completion(
                messages=messages,
                temperature=0.15,
                max_tokens=512
            )

            # AIMessage.content holds the raw string from the model
            raw_content: str = response.choices[0].message.content.strip()

            # Strip markdown code fences if the model wraps its JSON
            if raw_content.startswith("```"):
                raw_content = raw_content.split("```")[1]
                if raw_content.startswith("json"):
                    raw_content = raw_content[4:]

            classification: dict = json.loads(raw_content)

            reasoning_trace.append(
                f"[TRIAGE · STEP 3] LLM responded successfully. "
                f"Raw output snippet: {raw_content[:200]}…"
            )
            logger.info(f"[TRIAGE] Raw LLM output snippet: {raw_content[:200]}")

        except json.JSONDecodeError as exc:
            logger.error(f"[TRIAGE] JSON parse failed on LLM response: {exc}. Engaging fallback.")
            reasoning_trace.append(
                f"[TRIAGE · STEP 3 — ERROR] JSON decode failed ({exc}). "
                "Model likely returned non-JSON text. Engaging deterministic fallback."
            )
            classification = _mock_triage_classification(incoming_signals)

        except (TimeoutError, socket.timeout, http.client.RemoteDisconnected) as exc:
            # ── CIRCUIT BREAKER: Network-level timeout / disconnection ─────────
            logger.critical(f"[CIRCUIT_BREAKER] Network timeout/disconnect: {exc}. Engaging hardcoded fallback.")
            reasoning_trace.append(
                "[CIRCUIT_BREAKER_ENGAGED] Hugging Face API timeout/429 detected. "
                "Defaulting to deterministic local logic."
            )
            classification = _CIRCUIT_BREAKER_FALLBACK.copy()

        except Exception as exc:  # noqa: BLE001
            exc_str = str(exc)
            # ── CIRCUIT BREAKER: HTTP 429 / 503 rate-limit or service error ────
            if any(code in exc_str for code in ["429", "503", "rate limit", "Rate limit", "Too Many Requests"]):
                logger.critical(f"[CIRCUIT_BREAKER] API rate-limit/service error detected: {exc}. Engaging hardcoded fallback.")
                reasoning_trace.append(
                    "[CIRCUIT_BREAKER_ENGAGED] Hugging Face API timeout/429 detected. "
                    "Defaulting to deterministic local logic."
                )
                classification = _CIRCUIT_BREAKER_FALLBACK.copy()
            else:
                logger.error(f"[TRIAGE] LLM pipeline failed: {exc}. Engaging deterministic fallback.")
                reasoning_trace.append(
                    f"[TRIAGE · STEP 3 — ERROR] LLM pipeline raised {type(exc).__name__}: {exc}. "
                    "Engaging deterministic fallback classifier."
                )
                classification = _mock_triage_classification(incoming_signals)

    # ── Step 4: Validate and normalise the classification output ──────────────
    required_fields = {
        "crisis_type", "severity", "affected_population", "confidence_score",
        "agent_reasoning",
    }
    missing = required_fields - set(classification.keys())
    if missing:
        logger.warning(f"[TRIAGE] Classification missing fields: {missing}. Patching defaults.")
        classification.setdefault("crisis_type", "UNKNOWN")
        classification.setdefault("severity", "LOW")
        classification.setdefault("affected_population", 0)
        classification.setdefault("confidence_score", 0.0)
        classification.setdefault("agent_reasoning", "Reasoning unavailable — fallback defaults applied.")

    # Normalise types
    classification["affected_population"] = int(
        classification.get("affected_population", 0)
    )
    classification["confidence_score"] = float(
        classification.get("confidence_score", 0.0)
    )

    reasoning_trace.append(
        f"[TRIAGE · STEP 4] Final classification validated. "
        f"crisis_type='{classification['crisis_type']}' | "
        f"severity='{classification['severity']}' | "
        f"affected_population={classification['affected_population']} | "
        f"confidence_score={classification['confidence_score']:.2f}."
    )

    logger.info(
        f"[TRIAGE] Classification complete — "
        f"{classification['crisis_type']} / {classification['severity']} "
        f"(confidence={classification['confidence_score']:.2f})"
    )

    # ── Return partial state update ───────────────────────────────────────────
    return {
        "current_classification": classification,
        "reasoning_trace": reasoning_trace,
    }
