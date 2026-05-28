# Aegis-AI Omni-Crisis Intelligence Swarm

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
![Python](https://img.shields.io/badge/python-3.10%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Security](https://img.shields.io/badge/security-Zero_Trust-red)

A sovereign, high-availability, agentic architecture for omni-crisis intelligence gathering, triage, and response orchestration.

## 🧠 System Topology

```text
[Citizen Sensors / IoT] --(REST/WebSockets)--> [FastAPI Gateway]
                                                    |
                                                    v
[Zero-Trust Firewall] <----(Telemetry & Logs)---- [Data Fuser Node]
                                                    |
                                                    v
                                          [Triage Engine Node]
                                           /                 \
                          (Conflict/Anomaly)                 (Clean Signal)
                                /                                   \
                 [Validation Analyst Node]                    [Predictive Cascade Node]
                                \                                   /
                                 \                                 /
                                  ---->[Resource Allocator] <------
                                                    |
                                                    v
                                         [Remediation Dispatch]
```

## 🛡️ Security Posture

- **Zero-Trust Boundaries**: Agent-to-agent communication requires strict telemetry and signal validation.
- **Guardrails**: Input vectors are systematically sanitized against chaos injections.
- **Secrets Management**: No credentials ever touch disk storage directly in the repository.

## 🚀 Quick Start (Poetry)

1. **Install Dependencies**
   ```bash
   poetry install
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   # Add your specific HF_API_TOKEN and Service Account Keys
   ```

3. **Launch the Swarm Gateway**
   ```bash
   poetry run uvicorn src.main_api:app --reload --host 0.0.0.0 --port 8000
   ```
