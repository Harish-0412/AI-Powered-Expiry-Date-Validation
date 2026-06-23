import os
import cv2
import numpy as np
import random
from datetime import datetime, timedelta
import csv

def generate_test_images(output_dir="tests/test_data", num_images=50):
    os.makedirs(output_dir, exist_ok=True)
    gt_csv_path = os.path.join(output_dir, "ground_truth.csv")
    
    gt_data = []
    
    fonts = [
        cv2.FONT_HERSHEY_SIMPLEX,
        cv2.FONT_HERSHEY_COMPLEX,
        cv2.FONT_HERSHEY_DUPLEX,
        cv2.FONT_HERSHEY_TRIPLEX
    ]
    
    prefixes = ["EXP:", "Expiry:", "Use by:", "Best Before: ", "BB: ", ""]
    
    formats = [
        "%Y-%m-%d", "%d/%m/%Y", "%m/%Y", "%d %b %Y", "%Y/%m/%d"
    ]
    
    today = datetime.now()
    
    for i in range(num_images):
        # Create a synthetic label background
        bg_color = (random.randint(200, 255), random.randint(200, 255), random.randint(200, 255))
        img = np.full((400, 600, 3), bg_color, dtype=np.uint8)
        
        # Add some noise/texture to make it realistic
        noise = np.random.randint(0, 50, (400, 600, 3), dtype=np.uint8)
        img = cv2.add(img, noise)
        
        # Determine date
        days_offset = random.randint(-100, 200) # Past and future dates
        exp_date = today + timedelta(days=days_offset)
        
        fmt = random.choice(formats)
        date_str = exp_date.strftime(fmt)
        prefix = random.choice(prefixes)
        
        full_text = f"{prefix}{date_str}"
        
        # Add text
        font = random.choice(fonts)
        font_scale = random.uniform(0.8, 1.5)
        thickness = random.randint(2, 4)
        text_color = (random.randint(0, 50), random.randint(0, 50), random.randint(0, 50))
        
        # Random position
        x = random.randint(20, 200)
        y = random.randint(100, 300)
        
        # Draw text
        cv2.putText(img, full_text, (x, y), font, font_scale, text_color, thickness)
        
        # Add some random lines or "other text" to simulate a real label
        cv2.putText(img, "NET WT: 500g", (x, y - 50), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,0,0), 2)
        cv2.putText(img, "Batch: A1X9", (x, y + 50), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,0,0), 2)
        
        # Random slight rotation to simulate real camera angle
        angle = random.uniform(-10, 10)
        M = cv2.getRotationMatrix2D((300, 200), angle, 1.0)
        img = cv2.warpAffine(img, M, (600, 400), borderValue=bg_color)
        
        filename = f"test_img_{i:03d}.jpg"
        cv2.imwrite(os.path.join(output_dir, filename), img)
        
        # Ground truth standard format: YYYY-MM-DD
        gt_standard = exp_date.strftime("%Y-%m-%d")
        # For YYYY/MM we just append -01
        if fmt == "%m/%Y":
            gt_standard = exp_date.strftime("%Y-%m-01")
            
        gt_data.append({
            "filename": filename,
            "expiry_date": gt_standard
        })
        
    # Write CSV
    with open(gt_csv_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=["filename", "expiry_date"])
        writer.writeheader()
        writer.writerows(gt_data)
        
    print(f"Generated {num_images} test images and ground_truth.csv in {output_dir}")

if __name__ == "__main__":
    generate_test_images()
