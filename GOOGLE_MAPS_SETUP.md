# BSAS — Google Maps Platform Setup & Key Provisioning Guide

This guide details the exact steps required to provision and configure API keys for Google Maps Platform services in the **Border Safety & Alert System (BSAS)**.

---

## 1. Google Cloud Console Initial Setup

1. Open the [Google Cloud Console](https://console.cloud.google.com/).
2. Select your existing project or create a new project named `BSAS-Border-Safety`.
3. Enable billing on your Google Cloud Project (required by Google Maps Platform).

---

## 2. Enable Required Google Maps APIs

Navigate to **APIs & Services > Library** and search for and enable the following 5 APIs:

1. **Maps JavaScript API** (Powers the Next.js web operations map, Street View, and Vector Basemap)
2. **Places API (New)** (Powers location autocomplete, POI lookups, address search)
3. **Routes API** (Powers real-world A-to-B routing, distance calculation, polyline decoding, and ETA)
4. **Geocoding API** (Powers reverse geocoding from GPS pins to place names)
5. **Maps SDK for Android** (Powers the native Google Maps view in the Flutter mobile app)

---

## 3. Create Restricted API Keys

For production security, do **NOT** use a single unrestricted key. Create separate keys with principle of least privilege:

### Key A: Web Client API Key (Next.js Dashboard)

1. Go to **APIs & Services > Credentials > Create Credentials > API Key**.
2. Name the key: `BSAS-Web-Client-Key`.
3. Under **Application restrictions**, select **Websites (HTTP referrers)**:
   - For local development:
     - `http://localhost:3000/*`
     - `http://127.0.0.1:3000/*`
   - For production deployment:
     - `https://your-production-domain.com/*`
4. Under **API restrictions**, select **Restrict key** and check:
   - *Maps JavaScript API*
   - *Places API (New)*
   - *Routes API*
   - *Geocoding API*
5. Save the key.

### Key B: Android Mobile API Key (Flutter Mobile App)

1. Create a second key named: `BSAS-Android-Client-Key`.
2. Under **Application restrictions**, select **Android apps**:
   - Package name: `com.bsas.border_safety_alert_system`
   - SHA-1 certificate fingerprint:
     - For debug: obtain via `cd android && ./gradlew signingReport`
     - For release: use your release keystore SHA-1.
3. Under **API restrictions**, select **Restrict key** and check:
   - *Maps SDK for Android*
   - *Places API (New)*
   - *Routes API*
   - *Geocoding API*
4. Save the key.

### Key C: Server API Key (FastAPI Backend, Optional)

1. Create a third key named: `BSAS-Server-Key`.
2. Under **Application restrictions**, select **IP addresses** (add your server's static outbound IP).
3. Under **API restrictions**, check:
   - *Routes API*
   - *Geocoding API*
4. Save the key.

---

## 4. Local Project Configuration

### Frontend Configuration (`frontend/.env.local`):
Create or edit `frontend/.env.local`:
```bash
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=AIzaSy...Your_Web_Client_Key...
NEXT_PUBLIC_GOOGLE_MAP_ID=bsas_tactical_vector_map
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
```

### Android Manifest Configuration (`android/app/src/main/AndroidManifest.xml`):
Ensure the meta-data tag under `<application>` contains your Android key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSy...Your_Android_Client_Key..." />
```

### Backend Configuration (`backend/.env`):
```bash
GOOGLE_MAPS_SERVER_API_KEY=AIzaSy...Your_Server_Key...
```

---

## 5. Graceful Fallback Mode (No Key Required)

BSAS is architected with a **zero-crash fallback guarantee**:
- If `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` is not provided, the dashboard automatically initializes the **MapLibre GL JS engine** using local/cached vector boundaries.
- A non-blocking banner notifies operators:
  > *"Google Maps API key not configured. Operating in Offline / Local GeoJSON Fallback Mode."*
- Monitored boundaries, safety zones, geodesic distance calculations, on-device AI, and local alerts remain 100% operational.
