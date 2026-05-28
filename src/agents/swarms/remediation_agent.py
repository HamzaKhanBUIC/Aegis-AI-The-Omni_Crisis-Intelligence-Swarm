import json
import logging
import os
from typing import Any, Dict

from dotenv import load_dotenv
from huggingface_hub import InferenceClient

load_dotenv()

logger = logging.getLogger("AegisSwarm.Predictor")

# Securely initialize Hugging Face SDK
HF_API_TOKEN = os.getenv("HF_API_TOKEN", "")
USE_LIVE_AI: bool = os.getenv("USE_LIVE_AI", "False").lower() == "true"
client = InferenceClient(model="meta-llama/Meta-Llama-3-70B-Instruct", token=HF_API_TOKEN)

def run_predict_cascade(state: Dict[str, Any]) -> Dict[str, Any]:
    """
    PredictCascadeNode: Uses Llama-3-70B to forecast secondary infrastructure failures
    before resources are allocated.
    """
    classification = state.get("current_classification", {})
    trace = list(state.get("reasoning_trace", []))
    cascading_threats = list(state.get("cascading_threats", []))

    crisis_type = classification.get("crisis_type", "UNKNOWN")
    severity = classification.get("severity", "LOW")
    description = classification.get("description", "No detailed description provided.")

    trace.append("[PREDICT_CASCADE_NODE] Analyzing current incident to predict secondary infrastructural impacts.")

    # Avoid unnecessary API calls if no real threat
    if severity == "LOW" or "FALSE" in crisis_type.upper():
        trace.append("[PREDICT_CASCADE_NODE] Low severity or false alarm detected. No cascading predictions required.")
        return {"reasoning_trace": trace, "cascading_threats": cascading_threats}

    # ── MOCK MODE: Use deterministic predictions when HuggingFace is not active ──
    if not USE_LIVE_AI:
        logger.warning("[PREDICTOR] MOCK-MODE ACTIVE — Hugging Face API bypassed. Using deterministic cascade predictions.")
        _MOCK_CASCADES = {
            "FLOODING": [
                "Major arterial routes (Sharae Faisal, M-9 Motorway) submerged within 30 mins",
                "K-Electric substations in flood zones at risk — city-wide power grid trip imminent",
                "KWSB water treatment plants in low-lying zones may go offline",
            ],
            "INFRASTRUCTURE_BURST_PIPE": [
                "Water pressure drop will affect hospitals and civil facilities within 2km radius",
                "Localized road subsidence risk from pipe erosion beneath tarmac",
                "Emergency water supply deficit for ~50,000 citizens within 6 hours",
            ],
            "STRUCTURAL_FIRE": [
                "Thermal spread risk to adjacent structures within 50m",
                "Smoke AQI spike will trigger respiratory emergencies city-wide",
            ],
            "POWER_OUTAGE": [
                "Traffic signal failure on major junctions — gridlock imminent",
                "Hospital backup generators will activate — fuel reserve monitoring required",
            ],
        }
        predictions = _MOCK_CASCADES.get(crisis_type, [f"Secondary cascade risk assessment pending for {crisis_type}"])
        cascading_threats.extend(predictions)
        trace.append(f"[PREDICT_CASCADE_NODE] MOCK: Predicted {len(predictions)} secondary cascading threats for {crisis_type}.")
        return {"cascading_threats": cascading_threats, "reasoning_trace": trace}

    system_directive = """ROLE: You are the Aegis-Omni Predictive Analyst.
OBJECTIVE: Predict secondary, cascading infrastructural failures in Karachi resulting from a primary incident.
RULES:
1. Output exactly a valid JSON array of strings. Do not include introductory text, markdown formatting blocks, or explanations outside the JSON array.
2. Keep predictions concise and specific to the primary crisis context (e.g., ["Localized gridlock within 45 mins", "Power outage will disable traffic lights in Zone 3"]).
3. Focus on logical consequences related to traffic, healthcare, grid, or fintech."""

    prompt = f"{system_directive}\n\nPrimary Crisis: {crisis_type} (Severity: {severity})\nContext: {description}"

    try:
        messages = [
            {"role": "user", "content": prompt}
        ]

        response = client.chat_completion(
            messages=messages,
            temperature=0.3,
            max_tokens=250
        )

        content = response.choices[0].message.content
        if content.startswith("```json"):
            content = content[7:-3].strip()
        elif content.startswith("```"):
            content = content[3:-3].strip()

        predictions = json.loads(content)
        if isinstance(predictions, list):
            cascading_threats.extend(predictions)
            trace.append(f"[PREDICT_CASCADE_NODE] Successfully predicted {len(predictions)} secondary threats.")
        else:
            trace.append("[PREDICT_CASCADE_NODE] Warning: LLM output was not a JSON list.")

    except Exception as e:
        logger.error(f"Prediction failed: {str(e)}")
        trace.append(f"[PREDICT_CASCADE_NODE] Warning: Prediction engine error - {str(e)}")

    return {
        "cascading_threats": cascading_threats,
        "reasoning_trace": trace
    }
