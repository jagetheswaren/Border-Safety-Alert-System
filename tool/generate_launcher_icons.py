"""
Generate official BSAS Android launcher icons across all mipmap densities.
Employs the BSAS visual identity:
Location Pin + Safety Shield + Geofence Radar Rings + Alert Star.
"""
import os
import math
from PIL import Image, ImageDraw

DENSITIES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

RES_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'android', 'app', 'src', 'main', 'res'))

def draw_bsas_icon(size):
    # Render at 4x for clean supersampling
    scale = 4
    canvas_size = size * scale
    img = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background Rounded Tile
    # Deep obsidian blue
    bg_color = (11, 19, 32, 255) # #0B1320
    border_color = (40, 61, 94, 255) # #283D5E
    pad = int(canvas_size * 0.05)
    radius = int(canvas_size * 0.22)
    draw.rounded_rectangle(
        [pad, pad, canvas_size - pad, canvas_size - pad],
        radius=radius,
        fill=bg_color,
        outline=border_color,
        width=int(2 * scale)
    )

    cx = canvas_size / 2.0
    cy = canvas_size / 2.0

    # 2. Outer Geofence Ring (Dashed/Subtle Cyan)
    geofence_r = canvas_size * 0.35
    geofence_color = (2, 132, 199, 120) # Sky 600 subtle
    draw.ellipse(
        [cx - geofence_r, cy - geofence_r, cx + geofence_r, cy + geofence_r],
        outline=geofence_color,
        width=int(2 * scale)
    )

    # Inner Radar Ring
    inner_r = canvas_size * 0.25
    inner_color = (56, 189, 248, 160) # Sky 400
    draw.ellipse(
        [cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
        outline=inner_color,
        width=int(1.5 * scale)
    )

    # 3. Safety Shield Outline
    shield_w = canvas_size * 0.28
    shield_top = cy - canvas_size * 0.22
    shield_bottom = cy + canvas_size * 0.24
    
    shield_points = [
        (cx - shield_w, shield_top),
        (cx + shield_w, shield_top),
        (cx + shield_w * 0.85, cy + canvas_size * 0.08),
        (cx, shield_bottom),
        (cx - shield_w * 0.85, cy + canvas_size * 0.08),
    ]
    draw.polygon(shield_points, fill=(19, 31, 51, 230), outline=(2, 132, 199, 255))

    # 4. Location Pin / Alert Core
    pin_r = canvas_size * 0.08
    pin_cy = cy - canvas_size * 0.04
    # Center emerald/cyan alert beacon
    beacon_color = (13, 148, 136, 255) # Safe Green / Teal
    draw.ellipse(
        [cx - pin_r, pin_cy - pin_r, cx + pin_r, pin_cy + pin_r],
        fill=beacon_color,
        outline=(255, 255, 255, 255),
        width=int(1.5 * scale)
    )

    # Alert Diamond Star in center
    star_r = canvas_size * 0.045
    star_pts = [
        (cx, pin_cy - star_r),
        (cx + star_r * 0.7, pin_cy),
        (cx, pin_cy + star_r),
        (cx - star_r * 0.7, pin_cy),
    ]
    draw.polygon(star_pts, fill=(255, 255, 255, 255))

    # Downward Anchor Point of pin
    anchor_pts = [
        (cx - pin_r * 0.7, pin_cy + pin_r * 0.5),
        (cx + pin_r * 0.7, pin_cy + pin_r * 0.5),
        (cx, pin_cy + pin_r * 1.8),
    ]
    draw.polygon(anchor_pts, fill=beacon_color)

    # Downsample with Lanczos filter for premium sharpness
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img

def main():
    print("Generating BSAS Android Launcher Icons...")
    for folder, size in DENSITIES.items():
        out_dir = os.path.join(RES_DIR, folder)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, 'ic_launcher.png')
        icon = draw_bsas_icon(size)
        icon.save(out_path, format='PNG')
        print(f"Generated {folder}/ic_launcher.png ({size}x{size})")

    # Generate 512x512 high-res store/launcher asset
    high_res_dir = os.path.join(RES_DIR, 'mipmap-xxxhdpi')
    high_res_icon = draw_bsas_icon(512)
    high_res_path = os.path.join(RES_DIR, 'ic_launcher_512.png')
    high_res_icon.save(high_res_path, format='PNG')
    print(f"Generated {high_res_path} (512x512)")
    print("All BSAS launcher icons successfully generated!")

if __name__ == '__main__':
    main()
