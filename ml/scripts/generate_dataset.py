import os
import pandas as pd
import numpy as np
import datetime
import math

def haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371000  # meters
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi/2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda/2.0)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return R * c

def initial_bearing(lat1, lon1, lat2, lon2):
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    lambda1, lambda2 = math.radians(lon1), math.radians(lon2)
    y = math.sin(lambda2 - lambda1) * math.cos(phi2)
    x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(lambda2 - lambda1)
    theta = math.atan2(y, x)
    return (math.degrees(theta) + 360) % 360

def generate_trajectory(scenario_id, num_points=20, start_lat=12.9716, start_lon=77.5946, 
                        lat_step=0, lon_step=0, speed_mps=1.5, boundary_lat=12.9750, boundary_lon=77.5950, risk_level="HIGH"):
    records = []
    current_lat, current_lon = start_lat, start_lon
    start_time = datetime.datetime.now() - datetime.timedelta(hours=1)
    
    for i in range(num_points):
        # Calculate derived features
        dist_to_boundary = haversine_distance(current_lat, current_lon, boundary_lat, boundary_lon)
        bear_to_boundary = initial_bearing(current_lat, current_lon, boundary_lat, boundary_lon)
        
        # Fake bearing of movement
        if lat_step == 0 and lon_step == 0:
            movement_bearing = 0
            speed = 0
        else:
            movement_bearing = initial_bearing(current_lat, current_lon, current_lat + lat_step, current_lon + lon_step)
            speed = speed_mps
            
        bearing_diff = abs(movement_bearing - bear_to_boundary)
        if bearing_diff > 180:
            bearing_diff = 360 - bearing_diff
            
        # Target logic for Risk classification based on deterministic rules for synthetic data
        # LOW if far, HIGH if close and moving toward
        is_moving_toward = bearing_diff <= 45
        
        # Risk logic
        if dist_to_boundary < 300:
            target_risk = 2  # HIGH
        elif dist_to_boundary < 1000:
            target_risk = 1 if is_moving_toward else 0  # MEDIUM if moving towards, else LOW
        else:
            target_risk = 0  # LOW
            
        records.append({
            'scenario_id': scenario_id,
            'timestamp': (start_time + datetime.timedelta(seconds=i*5)).isoformat(),
            'latitude': current_lat,
            'longitude': current_lon,
            'speed': speed,
            'bearing': movement_bearing,
            'accuracy': np.random.uniform(2.0, 10.0),
            'distance_to_boundary': dist_to_boundary,
            'bearing_to_boundary': bear_to_boundary,
            'movement_direction_difference': bearing_diff,
            'boundary_risk_level': risk_level,
            'target_risk': target_risk
        })
        
        current_lat += lat_step
        current_lon += lon_step
        
    return pd.DataFrame(records)

print("Generating synthetic GPS dataset...")
datasets = []

# Scenario A: Moving away from boundary (Southwards when boundary is North)
for i in range(50):
    datasets.append(generate_trajectory(f"A_{i}", lat_step=-0.0001, lon_step=0, boundary_lat=12.98, boundary_lon=77.5946))

# Scenario B: Moving parallel to boundary
for i in range(50):
    datasets.append(generate_trajectory(f"B_{i}", lat_step=0, lon_step=0.0001, boundary_lat=12.9750, boundary_lon=77.5946))

# Scenario C: Moving toward boundary
for i in range(50):
    datasets.append(generate_trajectory(f"C_{i}", lat_step=0.0002, lon_step=0, boundary_lat=12.98, boundary_lon=77.5946))

# Scenario D: Approaching boundary at different speeds
for i in range(50):
    datasets.append(generate_trajectory(f"D_{i}", lat_step=0.0005, lon_step=0, speed_mps=15.0, boundary_lat=12.98, boundary_lon=77.5946))

# Scenario E: Entering restricted area
for i in range(50):
    datasets.append(generate_trajectory(f"E_{i}", start_lat=12.9790, lat_step=0.0002, lon_step=0, boundary_lat=12.98, boundary_lon=77.5946))

# Scenario F: Stationary
for i in range(50):
    datasets.append(generate_trajectory(f"F_{i}", lat_step=0, lon_step=0, speed_mps=0.0, boundary_lat=12.98, boundary_lon=77.5946))

df = pd.concat(datasets, ignore_index=True)
os.makedirs("ml/datasets/synthetic", exist_ok=True)
output_path = "ml/datasets/synthetic/synthetic_gps_data.csv"
df.to_csv(output_path, index=False)
print(f"Generated {len(df)} records in {output_path}.")
