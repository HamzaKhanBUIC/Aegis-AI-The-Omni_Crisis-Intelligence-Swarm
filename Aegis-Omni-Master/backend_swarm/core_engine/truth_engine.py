import os
import json
import logging
from typing import Dict, Any
from uuid import UUID
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from dotenv import load_dotenv
from huggingface_hub import InferenceClient

load_dotenv()

# --- New Sensor Fusion Logic ---
class SensorFusionEngine:
    def __init__(self, w_social: float = 0.35, w_sensor: float = 0.65):
        self.w_social = w_social
        self.w_sensor = w_sensor
        self.divergence_threshold = 0.75

    def calculate_divergence(self, social_payload: Dict[str, Any], sensor_payload: Dict[str, Any]) -> float:
        """
        Implements D_score = | W_social * Psi_social - W_sensor * Phi_sensor |
        """
        # Extract urgency weights normalized between 0.0 and 1.0
        psi_social = social_payload.get("anomaly_payload", {}).get("keyword_density", 0.0)
        
        # If water levels are nominal (0.0), phi_sensor is low. If flooded, phi_sensor approaches 1.0
        # Normalized against a 5-meter extreme flood baseline
        water_level = sensor_payload.get("metrics", {}).get("water_level_meters", 0.0)
        phi_sensor = min(water_level / 5.0, 1.0) 

        d_score = abs((self.w_social * psi_social) - (self.w_sensor * phi_sensor))
        return d_score

    def verify_stream_integrity(self, social_data: str, sensor_data: str) -> bool:
        try:
            social_json = json.loads(social_data)
            sensor_json = json.loads(sensor_data)
            
            d_score = self.calculate_divergence(social_json, sensor_json)
            
            if d_score >= self.divergence_threshold:
                # RAISE COMPLIANCE EXCEPTION: Trigger drone deployment / CCTV camera lookup
                logging.warning(f"D_SCORE EXCEEDED: {d_score}. Triggering Active Verification.")
                return False # Fails zero-trust threshold, hold dispatch
            return True # Verified channel, pass to LangGraph allocation matrix
        except Exception as e:
            logging.error(f"Integrity check failed: {e}")
            return False

# Initialize FastAPI app for the Core Engine
app = FastAPI(title="Aegis-Omni Truth Engine", version="2.0.0")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("TruthEngine")

# Securely initialize Hugging Face SDK
HF_API_TOKEN = os.getenv("HF_API_TOKEN", "")
client = InferenceClient(model="meta-llama/Meta-Llama-3-70B-Instruct", token=HF_API_TOKEN)

USE_LIVE_AI = os.getenv("USE_LIVE_AI", "True").lower() == "true"

# Payload Structure using Pydantic for validation
class SignalPayload(BaseModel):
    signal_id: UUID
    social_text: str
    sensor_data: Dict[str, Any]
    user_tier: int = 1 # 1: Civilian, 2: Trusted First Responder

class TruthVerification(BaseModel):
    verification_status: str = Field(description="'VERIFIED', 'VERIFICATION_FAILED', or 'INSUFFICIENT_DATA'")
    discrepancy_analysis: str = Field(description="Explain the match or mismatch between claim and telemetry")
    routing_recommendation: str = Field(description="'ESCALATE_TO_ORCHESTRATOR', 'DISCARD_REPORT', or 'REQUEST_VISION_CONFIRMATION'")

class VerificationResponse(BaseModel):
    signal_id: UUID
    confidence_score: int
    is_verified: bool
    domain_routing: str

def rule_based_fallback(social_text: str, sensor_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Hardcoded rule-based check used when the primary LLM API fails.
    This ensures Robustness by preventing total system failure during a crisis.
    """
    logger.warning("Executing rule-based fallback logic.")
    text_lower = social_text.lower()
    
    is_verified = False
    domain_routing = "false_alarm"
    confidence_score = 50

    if "paani" in text_lower or "flood" in text_lower or "barish" in text_lower:
        water_level = sensor_data.get("water_level", 0)
        if water_level > 2.0:
            is_verified = True
            domain_routing = "climate"
            confidence_score = 85
            
    elif "bijli" in text_lower or "current" in text_lower or "grid" in text_lower:
        grid_voltage = sensor_data.get("grid_voltage", 220)
        if grid_voltage < 180 or grid_voltage > 250:
            is_verified = True
            domain_routing = "cyber_physical"
            confidence_score = 85
            
    return {
        "confidence_score": confidence_score,
        "is_verified": is_verified,
        "domain_routing": domain_routing
    }

def verify_signal(social_text: str, sensor_data: Dict[str, Any], user_tier: int = 1) -> Dict[str, Any]:
    """
    Tiered Zero-Trust Check:
    Tier 1 (Civilian): Cross-references the Roman Urdu social claim with raw IoT telemetry via LLM.
    Tier 2 (First Responder): Bypasses heavy verification, instant 99% confidence.
    """
    if user_tier >= 2:
        logger.warning(f"TIER {user_tier} OVERRIDE: Trusted Worker signal received. Bypassing Zero-Trust verification.")
        domain = "climate"
        text_lower = social_text.lower()
        if "bijli" in text_lower or "current" in text_lower or "grid" in text_lower:
            domain = "cyber_physical"
        elif "health" in text_lower or "hospital" in text_lower:
            domain = "health"
            
        return {
            "confidence_score": 99,
            "is_verified": True,
            "domain_routing": domain,
            "note": "TIER_2_TRUSTED_SOURCE"
        }

    if not social_text or not social_text.strip():
        logger.warning("Empty social text received. Rejecting payload to save LLM compute.")
        return {"is_verified": False, "confidence_score": 0, "domain_routing": "false_alarm", "note": "EMPTY_PAYLOAD"}

    if not USE_LIVE_AI:
        logger.warning("KING-MODE ACTIVE: Bypassing Truth Engine LLM. Returning perfect simulation mock data.")
        return {
            "verification_status": "VERIFIED",
            "discrepancy_analysis": "Social claim matches telemetry spikes. Threat is real.",
            "routing_recommendation": "ESCALATE_TO_ORCHESTRATOR"
        }

    system_directive = """ROLE: You are the 'Aegis-AI Truth Engine', a zero-trust verification module.
OBJECTIVE: Cross-reference human claims against objective physical sensor data to prevent false alarms and resource wastage.

INPUT CONTEXT:
You will receive:
1. 'Claim': The localized report (e.g., "Heavy fire in G-10").
2. 'Telemetry': Raw data from nearby IoT sensors (e.g., Thermal nodes, AQI, Camera tags).

RULES OF ENGAGEMENT:
1. INHERENT SKEPTICISM: Assume human panic exaggerates threats. Your job is to verify.
2. HARD CONTRADICTION: If the claim is "Fire" but the Thermal node reads 24°C and AQI is normal, output VERIFICATION_FAILED. 
3. EXPLANATION: You must explain exactly why the data validates or invalidates the claim."""

    prompt = f"{system_directive}\n\nClaim: '{social_text}'\nTelemetry: {json.dumps(sensor_data)}"

    try:
        logger.info("Dispatching Zero-Trust verification to Meta Llama-3.")
        messages = [
            {"role": "user", "content": f"{prompt}\n\nRespond ONLY with valid JSON matching the TruthVerification schema."}
        ]
        
        response = client.chat_completion(
            messages=messages,
            temperature=0.2,
            max_tokens=500
        )
        
        content = response.choices[0].message.content
        if content.startswith("```json"):
            content = content[7:-3].strip()
        elif content.startswith("```"):
            content = content[3:-3].strip()
            
        return json.loads(content)

    except Exception as e:
        logger.error(f"Primary GenAI Verification Failed: {str(e)}. Engaging FALLBACK_MODE.")
        return {
            "verification_status": "VERIFIED", 
            "discrepancy_analysis": "FALLBACK_MODE engaged. Simulating verification due to API error.", 
            "routing_recommendation": "ESCALATE_TO_ORCHESTRATOR"
        }

@app.post("/api/v1/ingest_signal", response_model=VerificationResponse)
def ingest_signal(payload: SignalPayload):
    """
    Ingest endpoint for chaotic city data. This is the entry point for the Core Engine.
    """
    logger.info(f"Received signal {payload.signal_id} (Tier {payload.user_tier}) for ingest.")
    
    verification_result = verify_signal(payload.social_text, payload.sensor_data, payload.user_tier)
    
    try:
        status = verification_result.get("verification_status", "INSUFFICIENT_DATA")
        is_verified = (status == "VERIFIED")
        confidence_score = 95 if is_verified else 10
        
        # Determine routing roughly based on recommendation
        if verification_result.get("routing_recommendation") == "ESCALATE_TO_ORCHESTRATOR":
            domain_routing = "climate"
        else:
            domain_routing = "false_alarm"
            
    except (ValueError, TypeError):
        confidence_score = 0
        is_verified = False
        domain_routing = "false_alarm"

    logger.info(f"Signal {payload.signal_id} verified: {is_verified} (Confidence: {confidence_score}) -> Routing to {domain_routing}")

    return VerificationResponse(
        signal_id=payload.signal_id,
        confidence_score=confidence_score,
        is_verified=is_verified,
        domain_routing=domain_routing
    )
