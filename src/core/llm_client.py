import os

from dotenv import load_dotenv
from langchain_huggingface import HuggingFaceEndpoint

# Load keys from .env
load_dotenv()
hf_token = os.getenv("HF_API_TOKEN")

if not hf_token or "secure_token" in hf_token:
    # We raise a warning but don't crash yet to allow for mock modes
    print("⚠️ WARNING: HF_API_TOKEN is missing or placeholder in .env file.")

# Instantiate the Master Llama-3 Client
# This client is shared across the Triage and Validator agents
hf_llm_client = HuggingFaceEndpoint(
    repo_id="meta-llama/Meta-Llama-3-70B-Instruct",
    task="text-generation",
    max_new_tokens=512,
    temperature=0.1, # Low temperature ensures deterministic JSON structures
    huggingfacehub_api_token=hf_token
)
