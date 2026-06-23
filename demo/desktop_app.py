import tkinter as tk
from tkinter import font as tkfont
import cv2
from PIL import Image, ImageTk
import sys
import threading
import os
from pathlib import Path

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))

from pipeline.inference import run_pipeline

class ZeptoScannerApp:
    def __init__(self, window):
        self.window = window
        self.window.title("Zepto Warehouse Scanner")
        self.window.geometry("1100x650")
        self.window.configure(bg="#1E1E2E") # Dark theme
        
        self.cap = cv2.VideoCapture(0)
        self.scanning = False
        self.current_frame = None
        
        # UI Setup
        self.setup_ui()
        
        # Start video loop
        self.update_video()
        
        # Key binding
        self.window.bind('<s>', lambda event: self.scan_item())
        self.window.bind('<q>', lambda event: self.window.destroy())

    def setup_ui(self):
        # Header
        header = tk.Frame(self.window, bg="#3b0764", height=70) # Dark Purple (Zepto brand hint)
        header.pack(fill=tk.X)
        header_lbl = tk.Label(header, text="ZEPTO OPERATIONS - EXPIRY SCANNER", bg="#3b0764", fg="#FFFFFF", font=("Segoe UI", 22, "bold"))
        header_lbl.pack(pady=15)

        # Main layout
        main_frame = tk.Frame(self.window, bg="#1E1E2E")
        main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Video feed (Left)
        video_container = tk.Frame(main_frame, bg="#000000", bd=5, relief=tk.RIDGE)
        video_container.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        self.vid_lbl = tk.Label(video_container, bg="#000000")
        self.vid_lbl.pack(expand=True)
        
        # Status Panel (Right)
        status_panel = tk.Frame(main_frame, bg="#282A36", width=350, bd=2, relief=tk.SUNKEN)
        status_panel.pack(side=tk.RIGHT, fill=tk.Y, padx=(20, 0))
        status_panel.pack_propagate(False)
        
        # Status labels
        tk.Label(status_panel, text="SCAN STATUS", bg="#282A36", fg="#8be9fd", font=("Segoe UI", 16, "bold")).pack(pady=(30, 10))
        
        self.lbl_status_val = tk.Label(status_panel, text="READY", bg="#282A36", fg="#50FA7B", font=("Segoe UI", 28, "bold"))
        self.lbl_status_val.pack(pady=15)
        
        # Info Box
        info_frame = tk.Frame(status_panel, bg="#44475A", padx=10, pady=10)
        info_frame.pack(fill=tk.X, padx=20, pady=20)
        
        self.lbl_date = tk.Label(info_frame, text="Expiry Date: --", bg="#44475A", fg="#FFFFFF", font=("Segoe UI", 14))
        self.lbl_date.pack(anchor=tk.W, pady=5)
        
        self.lbl_days = tk.Label(info_frame, text="Days Remaining: --", bg="#44475A", fg="#FFFFFF", font=("Segoe UI", 14))
        self.lbl_days.pack(anchor=tk.W, pady=5)
        
        self.lbl_conf = tk.Label(info_frame, text="OCR Confidence: --", bg="#44475A", fg="#FFFFFF", font=("Segoe UI", 14))
        self.lbl_conf.pack(anchor=tk.W, pady=5)
        
        # Scan Button
        self.btn_scan = tk.Button(status_panel, text="📸 SCAN PRODUCT [S]", font=("Segoe UI", 16, "bold"), 
                                  bg="#ff004f", fg="white", activebackground="#c4003c", activeforeground="white",
                                  command=self.scan_item, relief=tk.FLAT, height=2, cursor="hand2")
        self.btn_scan.pack(side=tk.BOTTOM, fill=tk.X, pady=20, padx=20)

    def update_video(self):
        if not self.scanning:
            ret, frame = self.cap.read()
            if ret:
                self.current_frame = frame.copy()
                
                # Draw targeting HUD
                h, w = frame.shape[:2]
                box_w, box_h = 400, 150
                x1, y1 = (w - box_w) // 2, (h - box_h) // 2
                x2, y2 = x1 + box_w, y1 + box_h
                
                # Draw corners
                length = 30
                thick = 4
                color = (0, 255, 255)
                # Top Left
                cv2.line(frame, (x1, y1), (x1+length, y1), color, thick)
                cv2.line(frame, (x1, y1), (x1, y1+length), color, thick)
                # Top Right
                cv2.line(frame, (x2, y1), (x2-length, y1), color, thick)
                cv2.line(frame, (x2, y1), (x2, y1+length), color, thick)
                # Bottom Left
                cv2.line(frame, (x1, y2), (x1+length, y2), color, thick)
                cv2.line(frame, (x1, y2), (x1, y2-length), color, thick)
                # Bottom Right
                cv2.line(frame, (x2, y2), (x2-length, y2), color, thick)
                cv2.line(frame, (x2, y2), (x2, y2-length), color, thick)
                
                cv2.putText(frame, "ALIGN EXPIRY DATE HERE", (x1 + 60, y1 - 15), cv2.FONT_HERSHEY_SIMPLEX, 0.6, color, 2)
                
                # Convert to Tkinter format
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                img = Image.fromarray(frame_rgb)
                imgtk = ImageTk.PhotoImage(image=img)
                self.vid_lbl.imgtk = imgtk
                self.vid_lbl.configure(image=imgtk)
                
        self.window.after(30, self.update_video)
        
    def scan_item(self):
        if self.scanning or self.current_frame is None:
            return
            
        self.scanning = True
        self.lbl_status_val.config(text="SCANNING...", fg="#F1FA8C")
        self.btn_scan.config(state=tk.DISABLED, text="PROCESSING...")
        self.window.update()
        
        # Run in thread so UI doesn't freeze
        threading.Thread(target=self.process_scan).start()
        
    def process_scan(self):
        temp_path = "temp_scan.jpg"
        cv2.imwrite(temp_path, self.current_frame)
        
        # Run heavy pipeline
        res = run_pipeline(temp_path, near_expiry_threshold_days=30)
        
        if os.path.exists(temp_path):
            os.remove(temp_path)
            
        # Update UI back in main thread
        self.window.after(0, self.display_result, res)
        
    def display_result(self, res):
        status = res['status'].upper()
        
        color = "#6272A4" # Default gray
        display_text = status
        
        if status == "VALID":
            color = "#50FA7B" # Green
        elif status == "NEAR_EXPIRY":
            color = "#FFB86C" # Orange
            display_text = "NEAR EXPIRY"
        elif status == "EXPIRED":
            color = "#FF5555" # Red
        elif status == "MANUAL_REVIEW_REQUIRED":
            color = "#F1FA8C" # Yellow
            display_text = "NEEDS REVIEW"
            
        self.lbl_status_val.config(text=display_text, fg=color)
        self.lbl_date.config(text=f"Expiry Date: {res.get('expiry_date', 'None')}")
        self.lbl_days.config(text=f"Days Remaining: {res.get('days_remaining', 'None')}")
        self.lbl_conf.config(text=f"OCR Confidence: {res.get('ocr_confidence', 0):.2f}")
        
        self.btn_scan.config(state=tk.NORMAL, text="📸 SCAN PRODUCT [S]")
        
        # Wait 3 seconds then clear the screen for next scan
        self.window.after(4000, self.reset_scanner)
        
    def reset_scanner(self):
        self.lbl_status_val.config(text="READY", fg="#50FA7B")
        self.lbl_date.config(text="Expiry Date: --")
        self.lbl_days.config(text="Days Remaining: --")
        self.lbl_conf.config(text="OCR Confidence: --")
        self.scanning = False

if __name__ == "__main__":
    root = tk.Tk()
    app = ZeptoScannerApp(root)
    root.mainloop()
