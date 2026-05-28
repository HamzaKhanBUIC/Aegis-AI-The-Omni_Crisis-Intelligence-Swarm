"""
src/core/config.py
Core configuration for the Aegis-Omni Swarm Engine.
"""

import os

from pydantic import BaseModel


class AppConfig(BaseModel):
    app_name: str = "Aegis-AI Omni-Crisis Swarm"
    version: str = "2.0.0"
    use_live_ai: bool = os.getenv("USE_LIVE_AI", "True").lower() == "true"
    hf_token: str | None = os.getenv("HF_API_TOKEN")

config = AppConfig()
