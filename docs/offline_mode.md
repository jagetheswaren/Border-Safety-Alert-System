# Offline mode (target behavior)

## Works offline (after one-time downloads)

GPS positioning, offline map tiles, boundary SQLite DB, geo-fence, feature extraction,
TFLite LSTM + Random Forest inference, risk engine, A* routing on local graph,
voice/vibration/notifications, trip + alert history, templated safety guidance.

## Requires connectivity (optional)

Map-tile pack download, boundary dataset updates, model file updates, backend sync.
Never gate core safety decisions on connectivity.

## Demo

Download Region while online → disable Wi-Fi + mobile data → verify map renders,
distance updates, risk states change, alerts fire.
