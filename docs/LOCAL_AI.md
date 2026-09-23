# BSAS Local AI Assistant Architecture & Deployment Guide

## 1. Overview
The **BSAS Local AI Assistant** is an on-device advisory feature designed to explain official safety conditions, summarize telemetry coordinates, and provide geospatial awareness guidance without cloud dependencies.

> **CRITICAL SAFETY BOUNDARY**:
> The Local AI Assistant is **strictly read-only and advisory**. It receives an immutable `SafetyContextSnapshot` from the system. It **cannot mutate or override** GPS fixes, geofence zones, machine learning inference outputs, risk engine evaluations, or safety alert triggers.

---

## 2. Dual-Mode Deployment Architecture

BSAS implements a dual runtime architecture tailored to development and production environments:

```text
DEVELOPMENT / LAPTOP BRIDGE:
┌─────────────────────────┐
│     Windows Host        │
│   Ollama Service        │ ◄─── Listening on 127.0.0.1:11434
│   Qwen2.5-0.5B (GPU)    │      (Verified 0.27s response latency)
└────────────┬────────────┘
             │ HTTP Streaming API (/api/generate)
             ▼
┌─────────────────────────┐
│  BSAS LocalChatService  │
│  • Mode: Ollama GPU     │
│  • Streaming parser     │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│   Flutter Chat UI       │
└─────────────────────────┘


PRODUCTION FIELD MODE (ON-DEVICE ANDROID):
┌─────────────────────────┐
│  Android Smartphone     │
│  (e.g. Samsung SM-A127F)│
│  Native llama.cpp /     │
│  GGUF Runtime           │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  BSAS LocalChatService  │
│  • Mode: On-Device GGUF │
│  • Bounded context RAM  │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│   Flutter Chat UI       │
└─────────────────────────┘
```

---

## 3. Ollama Configuration on Developer Laptop
1. **Service Verification**:
   ```powershell
   ollama --version
   ollama list
   ollama ps
   ```
2. **Model Selection**:
   The development suite utilizes `qwen2.5:0.5b` (397 MB GGUF Q4_K_M), running with 100% GPU acceleration on Windows:
   ```powershell
   ollama pull qwen2.5:0.5b
   ```
3. **HTTP Streaming Endpoint**:
   `POST http://127.0.0.1:11434/api/generate` with `stream: true`.

---

## 4. Safety Invariants & Guardrails
- **Prompt Grounding**: Prompts inject the real-time sensor snapshot:
  - Official Risk State (`SAFE`, `CAUTION`, `WARNING`, `CRITICAL`)
  - Real GNSS Coordinates & Accuracy
  - Nearest Boundary Vector & Distance
  - Active Alert Count
- **Hallucination Prevention**: For exact telemetry queries (`Where am I?`, `System health`), deterministic snapshot values are provided directly.
- **Offline Integrity**: Operates without internet access, eliminating data leakage and external downtime.
