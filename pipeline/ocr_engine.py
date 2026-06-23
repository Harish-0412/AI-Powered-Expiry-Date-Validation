import cv2
import numpy as np
import easyocr
import math

# Task 6: Initialize with Hindi and English
try:
    reader = easyocr.Reader(['en', 'hi'], gpu=True)
except Exception as e:
    print(f"Warning: EasyOCR initialization failed. {e}")
    reader = None

def deskew(image):
    """Deskew correction for tilted labels up to ±15 degrees."""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image
    edges = cv2.Canny(gray, 50, 150, apertureSize=3)
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, 100, minLineLength=100, maxLineGap=10)
    
    if lines is not None:
        angles = []
        for line in lines:
            x1, y1, x2, y2 = line[0]
            angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
            if -15 <= angle <= 15:
                angles.append(angle)
        if angles:
            median_angle = np.median(angles)
            (h, w) = image.shape[:2]
            center = (w // 2, h // 2)
            M = cv2.getRotationMatrix2D(center, median_angle, 1.0)
            rotated = cv2.warpAffine(image, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
            return rotated
    return image

def preprocess_image(image, method='clahe'):
    """Various preprocessing methods"""
    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    else:
        gray = image

    if method == 'clahe':
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        return clahe.apply(gray)
    elif method == 'otsu':
        _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        return thresh
    elif method == 'invert':
        return cv2.bitwise_not(gray)
    elif method == 'deskew':
        return deskew(image)
    return gray

def extract_text(image):
    if reader is None:
        return "", 0.0
    try:
        results = reader.readtext(image)
        text = " ".join([res[1] for res in results])
        confidences = [res[2] for res in results]
        avg_conf = sum(confidences) / len(confidences) if confidences else 0.0
        return text, avg_conf
    except Exception as e:
        print(f"OCR Error: {e}")
        return "", 0.0

def try_all_preprocessings(image):
    """
    Try different preprocessing techniques and return the result with highest confidence.
    """
    best_text = ""
    best_conf = 0.0
    
    methods = ['none', 'clahe', 'otsu', 'invert', 'deskew']
    
    for method in methods:
        processed_img = preprocess_image(image, method)
        text, conf = extract_text(processed_img)
        if conf > best_conf:
            best_conf = conf
            best_text = text
            
    return best_text, best_conf
