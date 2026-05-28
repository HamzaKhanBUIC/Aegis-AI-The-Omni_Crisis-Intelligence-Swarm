"""
src/security/guardrails.py
Input sanitization and output guardrails.
"""

import logging

logger = logging.getLogger("AegisSecurity.Guardrails")

def sanitize_input(payload: str) -> str:
    """
    Sanitizes incoming text to prevent prompt injection, chaos vectors, or system commands.
    """
    if not payload:
        return ""
    
    # 1. Strip common prompt injection / system override phrases
    dangerous_patterns = [
        "ignore previous instructions",
        "system override",
        "sudo rm",
        "format system",
        "delete database",
        "drop table"
    ]
    
    sanitized = payload
    for pattern in dangerous_patterns:
        if pattern in sanitized.lower():
            logger.warning(f"🛡️ [GUARDRAILS DETECTED THREAT] Dangerous pattern blocked: '{pattern}'")
            # Replace or neutralize the threat
            sanitized = sanitized.replace(pattern, "[CLEANED THREAT]")
            
    # 2. Basic escape characters or stripping control characters if any
    sanitized = sanitized.replace("\x00", "").strip()
    
    return sanitized
