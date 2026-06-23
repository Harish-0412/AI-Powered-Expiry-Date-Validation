@echo off
title Zepto Master Launcher
color 0A

echo ==============================================
echo        LAUNCHING ZEPTO ML SYSTEM
echo ==============================================
cd /d "%~dp0"

echo [1/3] Starting FastAPI Backend on port 8000...
start "Zepto API Backend" cmd /c "python -m uvicorn api.main:app --host 0.0.0.0 --port 8000"
timeout /t 2 /nobreak > NUL

echo [2/3] Starting Streamlit Dashboard on port 8501...
start "Zepto Dashboard" cmd /c "python -m streamlit run demo/app.py --server.port 8501"
timeout /t 3 /nobreak > NUL

echo [3/3] Starting Desktop Scanner UI...
start "Zepto Live Scanner" cmd /c "python demo\desktop_app.py"

echo.
echo ==============================================
echo All systems successfully launched! 
echo Close the newly opened terminal windows to shut down the servers.
echo ==============================================
pause
