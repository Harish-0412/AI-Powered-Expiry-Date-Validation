"""
services/paddle_ocr_service.py
Sprint 3 — Raw OCR text extraction using PaddleOCR.

Responsibilities:
    - Load PaddleOCR reader exactly once (module-level singleton).
    - Expose extract_text(image_path) → {"raw_text": "...", "confidence": 0.91}
"""

from __future__ import annotations

import os
import logging
from typing import Optional

logger = logging.getLogger(__name__)

# ── Singleton ─────────────────────────────────────────────────────────────────
_reader: Optional[any] = None


def _get_reader():
    """
    Lazy-initialise and return the shared PaddleOCR Reader.
    """
    global _reader
    if _reader is None:
        from paddleocr import PaddleOCR
        
        # Try new PaddleOCR (PaddleX style) arguments: device='cpu', enable_mkldnn=False
        try:
            _reader = PaddleOCR(
                use_textline_orientation=False,
                lang='en',
                device='cpu',
                enable_mkldnn=False
            )
            logger.info("Successfully initialized PaddleOCR with new (PaddleX-style) arguments.")
        except Exception as e:
            logger.debug(f"Failed to initialize PaddleOCR with new arguments: {e}. Trying classic fallback...")
            
            # Try classic PaddleOCR arguments
            try:
                _reader = PaddleOCR(
                    use_angle_cls=True,
                    lang='en',
                    use_gpu=False,
                    show_log=False
                )
                logger.info("Successfully initialized PaddleOCR with classic arguments.")
            except Exception as e2:
                logger.debug(f"Failed to initialize PaddleOCR with classic arguments: {e2}. Trying minimal arguments...")
                
                # Try minimal/default arguments
                _reader = PaddleOCR(lang='en')
                logger.info("Successfully initialized PaddleOCR with minimal arguments.")
                
    return _reader


# ── Public API ────────────────────────────────────────────────────────────────

def extract_text(image_path: str) -> dict:
    """
    Run PaddleOCR on a single image and return aggregated raw text.

    Returns:
        {
            "raw_text":   "MFG 01/05/2026 EXP 01/11/2026 BATCH A123",
            "confidence": 0.93,
            "line_count": 3,
            "image_path": "/abs/path"
        }
    """
    image_path = os.path.abspath(image_path)

    if not os.path.isfile(image_path):
        raise FileNotFoundError(f"Image not found: {image_path}")

    ocr = _get_reader()

    # Run OCR. Some versions of PaddleOCR/PaddleX don't accept the 'cls' parameter during prediction.
    try:
        results = ocr.ocr(image_path, cls=True)
    except TypeError:
        results = ocr.ocr(image_path)

    if not results or not results[0]:
        return {
            "raw_text":   "",
            "confidence": 0.0,
            "line_count": 0,
            "image_path": image_path,
        }

    clean_texts: list[str] = []
    clean_scores: list[float] = []

    # Handle the two different formats returned by PaddleOCR:
    # 1. New/PaddleX format: a list containing a dict: [{'rec_texts': [...], 'rec_scores': [...], ...}]
    # 2. Classic format: a list containing a list of lines: [[[box_coords], (text, confidence)], ...]
    first_page = results[0]
    if isinstance(first_page, dict):
        rec_texts = first_page.get("rec_texts", [])
        rec_scores = first_page.get("rec_scores", [])
        for text, confidence in zip(rec_texts, rec_scores):
            if text and text.strip():
                clean_texts.append(text.strip())
                clean_scores.append(float(confidence))
    elif isinstance(first_page, list):
        for line in first_page:
            if line and len(line) >= 2:
                box = line[0]
                text, confidence = line[1]
                if text and text.strip():
                    clean_texts.append(text.strip())
                    clean_scores.append(float(confidence))

    raw_text   = "\n".join(clean_texts)
    confidence = round(sum(clean_scores) / len(clean_scores), 4) if clean_scores else 0.0

    return {
        "raw_text":   raw_text,
        "confidence": confidence,
        "line_count": len(clean_texts),
        "image_path": image_path,
    }
