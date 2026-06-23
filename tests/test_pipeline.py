import pytest
import os
import sys
from pathlib import Path

# Add project root to path
sys.path.append(str(Path(__file__).parent.parent))

from pipeline.inference import run_pipeline

def test_pipeline_import():
    assert callable(run_pipeline)
