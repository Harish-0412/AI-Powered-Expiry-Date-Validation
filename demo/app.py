import streamlit as st
import os
import cv2
import pandas as pd
import sys
from pathlib import Path

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))

from pipeline.inference import run_pipeline
from pipeline.detector import detect_date_region

st.set_page_config(page_title="Zepto Expiry Validation", layout="wide")

def display_single_result(res):
    st.image(res['image'], caption="Detected Region", use_container_width=True)
    st.subheader("Result")
    
    color_map = {
        "valid": "green",
        "near_expiry": "orange",
        "expired": "red",
        "manual_review_required": "yellow",
        "undetected": "gray"
    }
    color = color_map.get(res['status'], "gray")
    
    st.markdown(f"### Status: <span style='color:{color}'>{res['status'].upper()}</span>", unsafe_allow_html=True)
    st.write(f"**Expiry Date:** {res['expiry_date']}")
    st.write(f"**Days Remaining:** {res['days_remaining']}")
    st.write(f"**OCR Confidence:** {res.get('ocr_confidence', 0):.2f}")
    if 'review_reason' in res:
        st.warning(f"Review Reason: {res['review_reason']}")

st.title("Zepto Expiry Validation System")
st.sidebar.header("Configuration")
threshold = st.sidebar.slider("Near Expiry Threshold (Days)", min_value=7, max_value=90, value=30)

tab1, tab2 = st.tabs(["📤 File Upload / Batch", "📸 Live Scanner"])

with tab1:
    uploaded_files = st.file_uploader("Upload Image(s)", type=['png', 'jpg', 'jpeg'], accept_multiple_files=True)

    if uploaded_files:
        if len(uploaded_files) > 20:
            st.warning("Please upload a maximum of 20 images for batch processing.")
            uploaded_files = uploaded_files[:20]

        results = []
        
        for file in uploaded_files:
            temp_path = f"temp_{file.name}"
            with open(temp_path, "wb") as f:
                f.write(file.getbuffer())
                
            res = run_pipeline(temp_path, near_expiry_threshold_days=threshold)
            img = cv2.imread(temp_path)
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            boxes = detect_date_region(temp_path)
            for (x1, y1, x2, y2, conf) in boxes:
                cv2.rectangle(img_rgb, (x1, y1), (x2, y2), (0, 255, 0), 2)
                
            res['filename'] = file.name
            res['image'] = img_rgb
            results.append(res)
            os.remove(temp_path)

        if len(results) == 1:
            display_single_result(results[0])
        else:
            st.subheader("Batch Results")
            df = pd.DataFrame(results)
            display_cols = ['filename', 'status', 'expiry_date', 'days_remaining', 'ocr_confidence']
            st.dataframe(df[display_cols])
            
            status_counts = df['status'].value_counts().reset_index()
            status_counts.columns = ['status', 'count']
            
            import plotly.express as px
            fig = px.pie(status_counts, values='count', names='status', title='Batch Summary')
            st.plotly_chart(fig)

with tab2:
    st.write("Hold the product up to your camera and click 'Take Photo' to scan the expiry date.")
    camera_photo = st.camera_input("Scan Product")
    
    if camera_photo:
        temp_path = "temp_camera.jpg"
        with open(temp_path, "wb") as f:
            f.write(camera_photo.getbuffer())
            
        with st.spinner("Scanning..."):
            res = run_pipeline(temp_path, near_expiry_threshold_days=threshold)
            img = cv2.imread(temp_path)
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            boxes = detect_date_region(temp_path)
            for (x1, y1, x2, y2, conf) in boxes:
                cv2.rectangle(img_rgb, (x1, y1), (x2, y2), (0, 255, 0), 2)
                
            res['filename'] = "camera_snapshot"
            res['image'] = img_rgb
            os.remove(temp_path)
            
            display_single_result(res)
