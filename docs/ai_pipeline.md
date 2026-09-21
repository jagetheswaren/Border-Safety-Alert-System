# AI pipeline plan (no models trained in Phase 1)

## Model 1 — LSTM movement prediction

- Input: sequence of last N GPS/movement records (lat, lon, speed, bearing, time-derived).
- Output: predicted future displacement (delta_lat, delta_lon) or future lat/lon.
- Training: TensorFlow/Keras in `ml/training/train_lstm.py` (Phase 10).
- Export: `ml/export/export_lstm_tflite.py` → `assets/models/lstm_model.tflite` + `preprocessing.json`.
- Metrics: MAE, RMSE on trajectory-split test set. No fabricated accuracy.

## Model 2 — Random Forest risk classifier

- Input: distance_to_boundary, speed, bearing, direction_to_boundary, bearing_difference,
  estimated_time_to_boundary, boundary_risk, predicted movement, distance/speed change.
- Output: LOW | MEDIUM | HIGH (+ optional risk_score).
- Training: scikit-learn `RandomForestClassifier` in `ml/training/train_random_forest.py` (Phase 11).
- Metrics: accuracy, precision, recall, F1, confusion matrix; prioritize HIGH recall.
- Export: model + feature metadata for on-device inference (Phase 12).

## Mobile inference (Phase 12+)

`AiService` loads both `.tflite` files, validates tensor shapes, runs inference,
falls back to deterministic engine on error. Same preprocessing as training.
