# Aegis-AI Omni-Crisis Intelligence Swarm

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
![Python](https://img.shields.io/badge/python-3.10%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Security](https://img.shields.io/badge/security-Zero_Trust-red)
[![CI/CD](https://github.com/yourusername/aegis-omni/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/yourusername/aegis-omni/actions/workflows/ci-cd.yml)
[![Security Scan](https://github.com/yourusername/aegis-omni/actions/workflows/security-scan.yml/badge.svg)](https://github.com/yourusername/aegis-omni/actions/workflows/security-scan.yml)

> **Sovereign, multi-agent AI swarm designed for metropolitan-scale predictive defense and zero-trust event validation.**

A sovereign, high-availability, agentic architecture for omni-crisis intelligence gathering, triage, and response orchestration.

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Key Capabilities](#-key-capabilities)
- [Technical Stack](#-technical-stack)
- [Quick Start](#-quick-start)
- [Deployment](#-deployment)
- [Configuration](#-configuration)
- [API Documentation](#-api-documentation)
- [Testing](#-testing)
- [Security](#-security)
- [Contributing](#-contributing)
- [License](#-license)

## 🧠 Architecture Overview

```
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

### System Components

- **FastAPI Gateway**: REST and WebSocket entry point for all citizen sensor data
- **Data Fuser Node**: Normalizes multi-source signals (text, telemetry, sensors)
- **Triage Engine**: Real-time crisis severity classification
- **Validation Analyst**: Zero-trust corroboration to eliminate false positives
- **Predictive Cascade**: Anticipates secondary effects and resource needs
- **Resource Allocator**: Dynamic emergency resource orchestration

## ⚡ Key Capabilities

- **Edge Execution**: Zero-latency, localized data processing for critical real-time decision making
- **Parallel Agent Processing**: Simultaneous evaluation by multiple agent nodes (Triage, Validation, Allocation)
- **Zero-Trust Verification**: Autonomous multi-source corroboration to eliminate false positives and noise
- **Autonomous Resource Orchestration**: Dynamic generation of coordinated response actions and routing
- **Multi-Source Signal Fusion**: Ingests noisy citizen reports alongside rigid physical sensor telemetry
- **Action Simulation Pipeline**: High-fidelity execution simulator with instant edge node alerts

## 🛠️ Technical Stack

| Component | Technology |
|-----------|------------|
| **AI Orchestration** | LangGraph, Custom Multi-Agent Swarms |
| **LLM Models** | Llama-3-70B, Google Gemini |
| **Backend Framework** | FastAPI (Python 3.10+) |
| **Database** | Firebase Firestore |
| **Containerization** | Docker, Docker Compose |
| **Frontend** | Flutter (Web & Mobile) |
| **Security** | Zero-Trust Architecture, Input Guardrails |

## 🚀 Quick Start

### Prerequisites

- Python 3.10+
- Poetry (dependency management)
- Docker & Docker Compose (optional, for containerized deployment)
- Hugging Face API token (for LLM access)
- Firebase service account credentials

### Installation

#### Option 1: Poetry (Recommended for Development)

```bash
# Clone the repository
git clone https://github.com/yourusername/aegis-omni.git
cd aegis-omni

# Install dependencies
poetry install

# Configure environment
cp .env.example .env
# Edit .env with your HF_API_TOKEN and Firebase credentials

# Run the swarm gateway
poetry run uvicorn src.main_api:app --reload --host 0.0.0.0 --port 8000
```

#### Option 2: Docker (Production Deployment)

```bash
# Clone the repository
git clone https://github.com/yourusername/aegis-omni.git
cd aegis-omni

# Configure environment
cp .env.example .env
# Add your credentials

# Build and deploy
docker-compose -f deploy/docker-compose.yml up --build
```

Access the API at `http://localhost:8000` and view docs at `http://localhost:8000/docs`.

## 🏗️ Deployment

### Production Configuration

1. **Set environment variables** in `.env`:
   ```env
   HF_API_TOKEN="your_huggingface_token"
   FIREBASE_CREDENTIALS_PATH="./config/serviceAccountKey.json"
   USE_LIVE_AI="True"
   ```

2. **Place Firebase credentials** at `config/serviceAccountKey.json`

3. **Deploy with Docker Compose**:
   ```bash
   docker-compose -f deploy/docker-compose.yml up -d
   ```

### Health Checks

The system includes built-in health monitoring:
- `/health` - Basic health endpoint
- `/health/detailed` - Detailed system status with agent states

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `HF_API_TOKEN` | Hugging Face API token for LLM access | Required |
| `FIREBASE_CREDENTIALS_PATH` | Path to Firebase service account JSON | `./config/serviceAccountKey.json` |
| `USE_LIVE_AI` | Enable live LLM inference (False = mock mode) | `True` |
| `LOG_LEVEL` | Logging verbosity | `INFO` |

### Agent Configuration

Edit `config/agent_config.yaml` to customize:
- Agent behavior thresholds
- Triage priority rules
- Resource allocation policies

## 📚 API Documentation

Once running, access interactive API documentation:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### Key Endpoints

- `POST /api/v1/report` - Submit crisis report
- `GET /api/v1/events` - List active events
- `WS /ws/telemetry` - WebSocket for real-time telemetry
- `GET /health` - Health check

## 🧪 Testing

```bash
# Run all tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=src

# Run specific test categories
poetry run pytest tests/unit/
poetry run pytest tests/integration/
poetry run pytest tests/security/
```

## 🛡️ Security

### Security Posture

- **Zero-Trust Boundaries**: Agent-to-agent communication requires strict telemetry and signal validation
- **Input Guardrails**: All input vectors are systematically sanitized against chaos injections
- **Secrets Management**: No credentials ever touch disk storage directly in the repository
- **Automated Scanning**: Daily security scans via GitHub Actions

### Security Best Practices

1. Never commit `.env` files or service account keys
2. Rotate API tokens regularly
3. Review security scan reports in GitHub Actions
4. Use `tests/security/chaos_injector.py` for penetration testing

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- Code passes linting (`poetry run ruff check src/`)
- Tests pass (`poetry run pytest`)
- Documentation is updated as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- LangGraph team for the orchestration framework
- Hugging Face for model access
- Firebase for real-time database infrastructure

## 📞 Support

For issues and questions:
- Create an issue on GitHub

---

<div align="center">

**Aegis-AI Omni-Crisis Intelligence Swarm** · Built with sovereignty and zero-trust principles

</div>
