import os
import pandas as pd
import numpy as np
import json
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, mean_squared_error, mean_absolute_error

SEQ_LENGTH = 5

def create_sequences(df):
    sequences = []
    lstm_targets = []
    rf_features = []
    rf_targets = []
    
    # Group by trajectory (scenario_id)
    grouped = df.groupby('scenario_id')
    for name, group in grouped:
        group = group.sort_values('timestamp')
        features = group[['latitude', 'longitude', 'speed', 'bearing', 'distance_to_boundary', 'movement_direction_difference']].values
        
        for i in range(len(features) - SEQ_LENGTH):
            seq = features[i:i+SEQ_LENGTH]
            
            # Target for LSTM: Delta Lat/Lon from last point in sequence to next point
            last_pt = seq[-1]
            next_pt = features[i+SEQ_LENGTH]
            d_lat = next_pt[0] - last_pt[0]
            d_lon = next_pt[1] - last_pt[1]
            
            # Features for RF: We'll use the last point of the sequence
            rf_f = last_pt[2:6] # speed, bearing, distance, bearing_diff
            
            # Target for RF
            rf_t = group.iloc[i+SEQ_LENGTH]['target_risk']
            
            sequences.append(seq)
            lstm_targets.append([d_lat, d_lon])
            rf_features.append(rf_f)
            rf_targets.append(rf_t)
            
    return np.array(sequences), np.array(lstm_targets), np.array(rf_features), np.array(rf_targets)

def train_lstm(X_train, y_train, X_test, y_test):
    print("\n--- Training LSTM ---")
    model = tf.keras.Sequential([
        tf.keras.layers.LSTM(32, input_shape=(X_train.shape[1], X_train.shape[2]), return_sequences=False, unroll=True),
        tf.keras.layers.Dense(16, activation='relu'),
        tf.keras.layers.Dense(2) # d_lat, d_lon
    ])
    model.compile(optimizer='adam', loss='mse', metrics=['mae'])
    
    # Train
    model.fit(X_train, y_train, epochs=20, batch_size=32, validation_data=(X_test, y_test), verbose=1)
    
    # Evaluate
    preds = model.predict(X_test)
    mse = mean_squared_error(y_test, preds)
    mae = mean_absolute_error(y_test, preds)
    print(f"LSTM Test MSE: {mse:.8f}")
    print(f"LSTM Test MAE: {mae:.8f}")
    
    return model

def export_lstm_to_tflite(model, output_path):
    print(f"\n--- Exporting LSTM to TFLite: {output_path} ---")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    # Using unroll=True avoids the need for SELECT_TF_OPS (Flex delegate)
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
    tflite_model = converter.convert()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    print("TFLite model exported successfully.")

def rf_to_json(rf, feature_names):
    """ Converts a trained RandomForestClassifier into a JSON format interpretable by Dart. """
    trees_json = []
    for tree in rf.estimators_:
        tree_ = tree.tree_
        
        def recurse(node):
            if tree_.children_left[node] == tree_.children_right[node]: # Leaf
                class_idx = np.argmax(tree_.value[node][0])
                return {"type": "leaf", "class": int(rf.classes_[class_idx])}
            else: # Node
                return {
                    "type": "node",
                    "feature_idx": int(tree_.feature[node]),
                    "threshold": float(tree_.threshold[node]),
                    "left": recurse(tree_.children_left[node]),
                    "right": recurse(tree_.children_right[node])
                }
        trees_json.append(recurse(0))
        
    return {"trees": trees_json, "classes": [int(c) for c in rf.classes_]}

def train_rf(X_train, y_train, X_test, y_test, output_path):
    print("\n--- Training Random Forest ---")
    # Simplify to just 10 estimators for mobile device JSON parsing speed
    rf = RandomForestClassifier(n_estimators=10, max_depth=5, random_state=42)
    rf.fit(X_train, y_train)
    
    preds = rf.predict(X_test)
    acc = accuracy_score(y_test, preds)
    print(f"Random Forest Accuracy: {acc:.4f}")
    print("Classification Report:")
    print(classification_report(y_test, preds))
    
    # Export to JSON
    print(f"\n--- Exporting RF to JSON: {output_path} ---")
    rf_json = rf_to_json(rf, feature_names=["speed", "bearing", "distance_to_boundary", "movement_direction_difference"])
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump(rf_json, f)
    print("RF model exported to JSON successfully.")


def main():
    df = pd.read_csv("ml/datasets/synthetic/synthetic_gps_data.csv")
    
    # Preprocess
    print("Preprocessing data...")
    # Normalize features
    scaler = StandardScaler()
    feature_cols = ['latitude', 'longitude', 'speed', 'bearing', 'distance_to_boundary', 'movement_direction_difference']
    df[feature_cols] = scaler.fit_transform(df[feature_cols])
    
    # Save scaler params for Dart (mean and scale)
    scaler_params = {
        "means": scaler.mean_.tolist(),
        "scales": scaler.scale_.tolist(),
        "features": feature_cols
    }
    os.makedirs("assets/models", exist_ok=True)
    with open("assets/models/scaler_params.json", 'w') as f:
        json.dump(scaler_params, f)
        
    # Create sequences
    X_seq, y_lstm, X_rf, y_rf = create_sequences(df)
    
    print(f"Total sequences extracted: {len(X_seq)}")
    
    # Split data (We do a simple split, though normally we should split by trajectories to avoid leakage)
    X_train_seq, X_test_seq, y_train_lstm, y_test_lstm, X_train_rf, X_test_rf, y_train_rf, y_test_rf = train_test_split(
        X_seq, y_lstm, X_rf, y_rf, test_size=0.2, random_state=42)
    
    # Train & Export LSTM
    lstm_model = train_lstm(X_train_seq, y_train_lstm, X_test_seq, y_test_lstm)
    export_lstm_to_tflite(lstm_model, "assets/models/phase7-lstm-v1.tflite")
    
    # Train & Export RF
    train_rf(X_train_rf, y_train_rf, X_test_rf, y_test_rf, "assets/models/phase7-rf-v1.json")
    
    print("\n--- Verifying TFLite Inference ---")
    interpreter = tf.lite.Interpreter(model_path="assets/models/phase7-lstm-v1.tflite")
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"TFLite Input Shape: {input_details[0]['shape']}")
    print(f"TFLite Output Shape: {output_details[0]['shape']}")
    
    # Test inference with first test sequence
    test_seq = np.array([X_test_seq[0]], dtype=np.float32)
    interpreter.set_tensor(input_details[0]['index'], test_seq)
    interpreter.invoke()
    tflite_pred = interpreter.get_tensor(output_details[0]['index'])
    
    print(f"TFLite Test Prediction: {tflite_pred[0]}")
    print(f"Original Keras Prediction: {lstm_model.predict(test_seq)[0]}")
    
    print("\nPhase 7 ML pipeline completed successfully.")

if __name__ == "__main__":
    main()
