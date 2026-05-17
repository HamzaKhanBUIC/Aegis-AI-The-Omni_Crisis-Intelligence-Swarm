# Aegis-Omni: The Omni-Crisis Intelligence Swarm

![Aegis-Omni Tactical Banner](docs/aegis_banner.png)

> **"Don't respond to crises. Predict, verify, and neutralize them before they escalate."**

---

## 🏆 Hackathon Compliance & Credits

### Team Aegis
* **Lead Developer & Architect**: Hamza Imran 
  * [GitHub Repository](https://github.com/HamzaKhanBUIC/Aegis-AI-The-Omni_Crisis-Intelligence-Swarm) | [LinkedIn Profile](https://www.linkedin.com/in/hamza-imran-17569b383/)
  * *(Sole developer for all codebase, architecture, AI swarm logic, and full-stack implementation)*
* **QA Engineer, Compiler, Folder Assembler & Recording Editor**: Hamza Asif 
  * *(Responsible for QA, compilation, repository structuring, and demo video recording/editing guidance)*

### Google Antigravity & LLM Orchestration
**Mandatory Requirement Declaration:** We officially confirm that **Google Antigravity (AG)** was the **MAIN Orchestrator** throughout our entire development lifecycle. All agentic workflow implementations, project orchestration, and code generation were executed using AG as the primary orchestrator. We are submitting all generated artifacts (implementation plans, task lists, walkthroughs) within this repository to validate the AG development lifecycle.

---

## 🛡️ What Is Aegis-Omni? (Challenge 3: CIRO)

Aegis-Omni is a **sovereign, multi-agent AI swarm** designed for metropolitan-scale deployment in high-entropy urban environments (e.g., Karachi, Pakistan). It solves the fragmentation and reactivity of traditional emergency systems by autonomously ingesting chaotic multi-source crisis signals, fusing them against physical sensor telemetry, eliminating false alarms via Zero-Trust verification, and dispatching emergency resources—all in real-time.

---

## ✅ Hackathon Requirements Met

### 1. Multi-Source Input Processing
* **Implementation:** Accepts noisy, informal text complaints from citizens via the **Flutter Mobile App**. Simultaneously ingests simulated API data (Weather/Traffic sensors) via our Python simulation engine.

### 2. Event Detection
* **Implementation:** Uses our LangGraph Swarm gateway to identify anomalies and cluster crisis signals into recognizable threats (e.g., `URBAN_FLOODING`, `CIVIL_UNREST`).

### 3. Reasoning & Situation Analysis
* **Implementation:** The `TriageAgent` combines multi-source signals to infer the situation, estimate severity (LOW/MEDIUM/HIGH/CATASTROPHIC), and generate a confidence score with an agentic reasoning trace.

### 4. Action Planning
* **Implementation:** The `ResourceAllocator` agent dynamically generates coordinated response actions, creating emergency tickets, planning routing, and mapping specific resources (e.g., KWSB Dewatering Pumps, Traffic Police).

### 5. Action Simulation (CRITICAL)
* **Implementation:** The pipeline perfectly simulates the execution. When a signal is ingested, the system generates simulated emergency tickets, updates mock map routes on the **Web Admin Dashboard**, and sends real-time simulated alerts directly back to the **Mobile App Chatbot Terminal**.

### 6. Outcome Visualization
* **Implementation:** The impact is shown beautifully on the **Flutter Web Admin Dashboard** (Tactical Map, Active Crises logs, and Inspector panel) and the **Mobile App** (Citizen Status Tracking & Live Terminal Feed).

### 7. Agentic Workflow (MANDATORY)
* **Implementation:** Built using a structured LangGraph multi-agent pipeline mapping planning → decision → execution. Multiple specialized agents (`DataFuser`, `TriageAgent`, `ValidationSentinel`, `CascadePredictor`, `ResourceAllocator`) interact chronologically.

---

## 🏗️ Architecture & Deliverables

```plaintext
Aegis-Omni-Master/
│
├── 📂 docs/                          ← Documentation, mathematical deep-dives, & artifacts
├── 🐍 backend_swarm/                 ← AI Brain: LangGraph + FastAPI Gateway
│   ├── main_api.py                   ← FastAPI entry point + Firestore listener
│   ├── agents/                       ← Multi-Agent interaction nodes
│   ├── simulate_citizen_report.py   ← Action Simulation script
│   └── antigravity_trace_log.txt    ← Agent Trace / Logs (Deliverable 3)
│
├── 📱 frontend_mobile/               ← Working Prototype Mobile App (Deliverable 1)
├── 💻 frontend_admin/                ← Working Prototype Web App (Optional Deliverable)
│
├── Dockerfile                        ← Production container
├── docker-compose.yml                ← Standalone one-command deployment
└── README.md                         ← You are here (Deliverable 4)
```

*(Note: The Demo Video (Deliverable 2) is submitted externally as required).*

---

## 🧠 The "Curveball" — Zero-Trust Verification

The system is intentionally designed to be **fooled by social media hysteria** — and then **catch itself**.

**Scenario:** Simulated tweets claim a catastrophic flash flood has destroyed a bridge. Triage AI classifies: `FLOODING / CATASTROPHIC / 100,000 affected`.  
**Zero-Trust fires:** Weather telemetry reads `rain_mm: 0.0`. A natural flash flood is physically impossible with zero active precipitation.  
**Override Action Simulation:** `INFRASTRUCTURE_BURST_PIPE / MEDIUM` — KWSB Heavy Repair Squad dispatched instead of flood rescue.

---

## 🔑 Running The System

```bash
# 1. Install dependencies
pip install -r backend_swarm/requirements.txt

# 2. Terminal 1 — Start the Swarm Gateway (Agentic Workflow)
cd backend_swarm
python main_api.py

# 3. Terminal 2 — Fire Action Simulation (Mock Telemetry)
cd backend_swarm
python simulate_citizen_report.py

# 4. Terminals 3 & 4 — Run Mobile and Web Dashboards
# Run Flutter apps in their respective frontend directories
```

---
*Aegis-Omni Intelligence Command · Built exclusively via Google Antigravity · May 2026*
