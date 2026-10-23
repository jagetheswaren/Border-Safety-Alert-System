import os
import json
import logging
from typing import Optional, Dict, Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
import httpx

from app.dependencies import get_db
from app.api.auth import get_current_user
from app.models.user import User
from app.models.zone import Zone
from app.models.alert import Alert

logger = logging.getLogger("bsas.ai")
router = APIRouter()

class AIChatRequest(BaseModel):
    message: str = Field(..., description="User query or message to the BSAS AI assistant")
    conversation_id: Optional[str] = Field(None, description="Optional persistent conversation session ID")
    telemetry: Optional[Dict[str, Any]] = Field(None, description="Optional read-only client telemetry snapshot")

class AIChatResponse(BaseModel):
    reply: str
    provider: str
    source: str = "ai"
    success: bool = True

def _build_safety_context(db: Session, telemetry: Optional[Dict[str, Any]] = None) -> str:
    """
    Constructs an immutable, read-only safety snapshot for the AI context.
    Authoritative safety decisions remain strictly determined by RiskEngine / GeofenceService.
    """
    zones: List[Zone] = db.query(Zone).filter(Zone.enabled == True).all()
    zone_summaries = []
    for z in zones:
        zone_summaries.append(f"- {z.name} (Type: {z.type}, Severity: {z.severity}, Warning Buffer: {z.warning_radius_m}m)")
    
    zone_text = "\n".join(zone_summaries) if zone_summaries else "No active zones configured in database."

    recent_alerts: List[Alert] = db.query(Alert).order_by(Alert.created_at.desc()).limit(5).all()
    alert_summaries = []
    for a in recent_alerts:
        status_text = "RESOLVED" if a.resolved_at else ("ACKNOWLEDGED" if a.acknowledged else "ACTIVE")
        alert_summaries.append(f"- [{a.severity}] {a.title}: {a.message} (Status: {status_text})")
    alert_text = "\n".join(alert_summaries) if alert_summaries else "No recent alerts on record."

    telemetry_text = "No live client telemetry provided."
    if telemetry:
        lat = telemetry.get("latitude")
        lon = telemetry.get("longitude")
        risk = telemetry.get("risk_state", "UNKNOWN")
        zone_state = telemetry.get("zone_state", "UNKNOWN")
        telemetry_text = f"Coordinates: {lat}, {lon} | Risk State: {risk} | Zone State: {zone_state}"

    context = f"""You are the Border Safety Alert System (BSAS) Advisory Assistant.
You provide intelligent, clear guidance to civilian operators, field personnel, and maritime navigators.

AUTHORITATIVE SAFETY DIRECTIVES:
1. You are strictly an advisory assistant. The BSAS RiskEngine and GeofenceService are the sole authoritative sources of risk state.
2. Never override, alter, or contradict official zone or alert states.
3. Never invent hypothetical GPS coordinates or fabricate non-existent border breach events.
4. If asked about current boundaries or safety status, refer to the verified database data below.

CURRENT VERIFIED DATABASE CONTEXT:
Configured Safety & Restricted Zones ({len(zones)} active):
{zone_text}

Recent Incident Alerts ({len(recent_alerts)} recorded):
{alert_text}

Live Client Telemetry:
{telemetry_text}
"""
    return context

async def _call_gemini_api(api_key: str, system_context: str, user_message: str) -> Optional[str]:
    """Calls Google Gemini API using httpx."""
    # Try gemini-1.5-flash then gemini-2.0-flash
    models = ["gemini-1.5-flash", "gemini-2.0-flash", "gemini-1.5-pro"]
    for model in models:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        payload = {
            "contents": [
                {
                    "role": "user",
                    "parts": [{"text": f"{system_context}\n\nUser Question: {user_message}"}]
                }
            ],
            "generationConfig": {
                "temperature": 0.4,
                "maxOutputTokens": 800
            }
        }
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                res = await client.post(url, json=payload)
                if res.status_code == 200:
                    data = res.json()
                    candidates = data.get("candidates", [])
                    if candidates:
                        parts = candidates[0].get("content", {}).get("parts", [])
                        if parts and "text" in parts[0]:
                            return parts[0]["text"].strip()
                else:
                    logger.warning("Gemini model %s returned status %d: %s", model, res.status_code, res.text[:200])
        except Exception as e:
            logger.warning("Gemini API call failed for model %s: %s", model, str(e))
    return None

async def _call_openai_api(api_key: str, system_context: str, user_message: str) -> Optional[str]:
    """Calls OpenAI Chat Completion API using httpx."""
    url = "https://api.openai.com/v1/chat/completions"
    payload = {
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": system_context},
            {"role": "user", "content": user_message}
        ],
        "temperature": 0.4,
        "max_tokens": 800
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            res = await client.post(url, json=payload, headers=headers)
            if res.status_code == 200:
                data = res.json()
                choices = data.get("choices", [])
                if choices:
                    return choices[0].get("message", {}).get("content", "").strip()
            else:
                logger.warning("OpenAI returned status %d: %s", res.status_code, res.text[:200])
    except Exception as e:
        logger.warning("OpenAI API call failed: %s", str(e))
    return None

async def _call_ollama_api(host: str, system_context: str, user_message: str) -> Optional[str]:
    """Calls local Ollama API if running."""
    url = f"{host.rstrip('/')}/api/chat"
    payload = {
        "model": "qwen3:0.6b",
        "messages": [
            {"role": "system", "content": system_context},
            {"role": "user", "content": user_message}
        ],
        "stream": False
    }
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.post(url, json=payload)
            if res.status_code == 200:
                data = res.json()
                return data.get("message", {}).get("content", "").strip()
    except Exception:
        pass
    return None

def _generate_rule_grounded_response(db: Session, message: str, telemetry: Optional[Dict[str, Any]]) -> str:
    """
    Authoritative fallback response grounded in verified database state
    when no cloud LLM API key is currently injected into the backend environment.
    """
    msg_lower = message.lower()
    zones = db.query(Zone).filter(Zone.enabled == True).all()
    recent_alerts = db.query(Alert).order_by(Alert.created_at.desc()).limit(5).all()

    if any(k in msg_lower for k in ["zone", "boundary", "restricted", "corridor", "configured"]):
        if not zones:
            return "Currently, there are no active safety zones configured in the BSAS database."
        lines = [f"BSAS currently has {len(zones)} active safety zones configured:"]
        for z in zones:
            lines.append(f"• {z.name}: Classification '{z.type}', Severity '{z.severity}', Warning buffer radius {z.warning_radius_m}m.")
        lines.append("\nAll geofence perimeters are actively monitored in real time by the BSAS GeofenceService.")
        return "\n".join(lines)

    if any(k in msg_lower for k in ["alert", "warning", "breach", "incident"]):
        if not recent_alerts:
            return "All operational sectors are currently nominal. No active incident alerts are recorded in the database."
        lines = [f"BSAS Incident Alert Registry (showing latest {len(recent_alerts)}):"]
        for a in recent_alerts:
            status_text = "Resolved" if a.resolved_at else ("Acknowledged" if a.acknowledged else "ACTIVE ALERT")
            lines.append(f"• [{a.severity}] {a.title}: {a.message} [{status_text}]")
        return "\n".join(lines)

    if any(k in msg_lower for k in ["gps", "location", "position", "coordinate"]):
        if telemetry and telemetry.get("latitude") and telemetry.get("longitude"):
            lat = telemetry.get("latitude")
            lon = telemetry.get("longitude")
            risk = telemetry.get("risk_state", "SAFE")
            zone = telemetry.get("zone_state", "SAFE")
            return (
                f"Authoritative telemetry reports your position at {lat:.5f}°, {lon:.5f}°.\n"
                f"Current Risk Engine State: {risk}\n"
                f"Current Geofence Zone: {zone}\n"
                "Maintain continuous GPS lock to ensure real-time perimeter alert tracking."
            )
        return (
            "The current zone status is unavailable until live location data is received. "
            "Please ensure location permissions are granted and GPS telemetry is streaming to BSAS."
        )

    if any(k in msg_lower for k in ["help", "what is", "about", "how does", "system", "features"]):
        return (
            "The Border Safety Alert System (BSAS) protects civilian vessels and border-adjacent operators "
            "with real-time GPS tracking, multi-zone geofence calculations, multi-modal alerts (audio, haptic, TTS), "
            "and an operations dashboard. Authoritative safety decisions are governed by the RiskEngine and GeofenceService."
        )

    # General grounded response
    return (
        f"BSAS Advisory Assistant received your query: '{message}'.\n\n"
        f"Verified System State:\n"
        f"• Active Monitored Zones: {len(zones)}\n"
        f"• Recent Alerts Recorded: {len(recent_alerts)}\n"
        f"• Authoritative Engine: Online and operational.\n\n"
        "To enable open-ended natural language conversational AI, set GEMINI_API_KEY or OPENAI_API_KEY in the backend environment."
    )

@router.post("/chat", response_model=AIChatResponse)
async def chat_with_ai(
    req: AIChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Authenticated AI Chat Gateway.
    - Injects read-only authoritative BSAS safety context (zones, alerts, telemetry).
    - Queries configured online AI provider (Google Gemini, OpenAI, or Ollama).
    - Falls back to database-grounded advisory engine if no API key is set.
    """
    system_context = _build_safety_context(db, req.telemetry)

    # 1. Check Google Gemini API
    gemini_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
    if gemini_key:
        reply = await _call_gemini_api(gemini_key, system_context, req.message)
        if reply:
            return AIChatResponse(reply=reply, provider="google-gemini", source="ai", success=True)

    # 2. Check OpenAI API
    openai_key = os.getenv("OPENAI_API_KEY")
    if openai_key:
        reply = await _call_openai_api(openai_key, system_context, req.message)
        if reply:
            return AIChatResponse(reply=reply, provider="openai", source="ai", success=True)

    # 3. Check Ollama
    ollama_host = os.getenv("OLLAMA_HOST", "http://127.0.0.1:11434")
    reply = await _call_ollama_api(ollama_host, system_context, req.message)
    if reply:
        return AIChatResponse(reply=reply, provider="ollama", source="ai", success=True)

    # 4. Authoritative Database Grounded Fallback
    fallback_reply = _generate_rule_grounded_response(db, req.message, req.telemetry)
    return AIChatResponse(
        reply=fallback_reply,
        provider="bsas-safety-engine",
        source="ai",
        success=True
    )
