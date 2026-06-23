import cv2
import sys
import os
from pathlib import Path

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))

from pipeline.inference import run_pipeline

def start_live_scanner():
    # Initialize the webcam (0 is usually the default laptop camera)
    cap = cv2.VideoCapture(0)
    
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        return

    print("=======================================")
    print("🎥 Live Scanner Started!")
    print("Press 's' to SNAP & SCAN the current frame.")
    print("Press 'q' to QUIT.")
    print("=======================================")
    
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame")
            break
            
        # Draw instructions on the live feed
        cv2.putText(frame, "Aim at Expiry Date", (10, 30), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
        cv2.putText(frame, "Press 's' to SCAN | 'q' to QUIT", (10, 60), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
                    
        cv2.imshow("Zepto OpenCV Scanner", frame)
        
        key = cv2.waitKey(1) & 0xFF
        
        if key == ord('q'):
            break
        elif key == ord('s'):
            print("\nScanning... (Please wait a few seconds)")
            
            # Show a "Scanning..." overlay so the user knows it's working
            scan_overlay = frame.copy()
            cv2.putText(scan_overlay, "SCANNING...", (200, 240), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 255), 4)
            cv2.imshow("Zepto OpenCV Scanner", scan_overlay)
            cv2.waitKey(1) # Force UI update
            
            # Save temp frame for the pipeline
            temp_path = "temp_scan.jpg"
            cv2.imwrite(temp_path, frame)
            
            # Run the heavy ML pipeline
            res = run_pipeline(temp_path)
            
            # Map status to color (BGR format in OpenCV)
            status = res['status'].upper()
            if status == "VALID":
                color = (0, 255, 0)      # Green
            elif status == "NEAR_EXPIRY":
                color = (0, 165, 255)    # Orange
            elif status == "EXPIRED":
                color = (0, 0, 255)      # Red
            else:
                color = (128, 128, 128)  # Gray
            
            # Draw the results on the frozen frame
            result_frame = frame.copy()
            cv2.putText(result_frame, f"STATUS: {status}", (10, 120), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 3)
            cv2.putText(result_frame, f"DATE: {res.get('expiry_date', 'None')}", (10, 160), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 3)
            cv2.putText(result_frame, f"DAYS REM: {res.get('days_remaining', 'N/A')}", (10, 200), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 3)
            cv2.putText(result_frame, "Press ANY KEY to resume...", (10, 250), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
            
            # Show result and wait for user to press a key to continue
            cv2.imshow("Zepto OpenCV Scanner", result_frame)
            cv2.waitKey(0) 
            
            # Cleanup
            if os.path.exists(temp_path):
                os.remove(temp_path)
            
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    start_live_scanner()
