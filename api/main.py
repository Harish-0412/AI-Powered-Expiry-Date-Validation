from fastapi import FastAPI, UploadFile, File
from typing import List
import shutil
import os
import sys
from pathlib import Path

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))

from pipeline.inference import run_pipeline

app = FastAPI(title="Zepto Expiry Validation API")

@app.post("/validate")
async def validate(image: UploadFile = File(...)):
    temp_path = f"temp_{image.filename}"
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)
        
    result = run_pipeline(temp_path)
    os.remove(temp_path)
    return result

@app.post("/validate/batch")
async def validate_batch(images: List[UploadFile] = File(...)):
    results = []
    for image in images:
        temp_path = f"temp_{image.filename}"
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        res = run_pipeline(temp_path)
        res['filename'] = image.filename
        results.append(res)
        os.remove(temp_path)
    return results
