#!/bin/sh

echo "Starting FastAPI backend API on port 8000..."
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &

echo "Starting Web Scanner Dashboard on port 8050..."
# Execute in the foreground so the container stays alive
python dev_tools/web_scanner.py
