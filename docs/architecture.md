# Architecture (Phase 1)

## Data flow (target)

```text
                  GPS / GNSS
                       |
                       v
                  Flutter App
                       |
        Offline Map + Boundary DB (SQLite) + GPS History
                       |
                       v
                Geo-Fence Engine
                       |
                       v
               Feature Extraction
                       |
            LSTM Prediction + Boundary Features
                       |
                       v
            Random Forest Risk Classifier
                       |
                       v
                  Risk Engine
                       |
            Alert Manager + A* Router
                       |
            Voice/Vibration/UI + Safe Route
                       |
              (optional) Offline LLM explains structured result
```

## Rules

1. Safety authority = deterministic geo-fence + trained ML risk engine. LLM never overrides.
2. Core pipeline works offline. Backend (FastAPI) is optional sync only.
3. Fallback: if TFLite inference fails, deterministic distance/direction/boundary-risk engine continues.
4. No hard-coded claim of knowing all world borders; only local DB regions.
