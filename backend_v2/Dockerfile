# Start from the official Python base image
FROM python:3.12-slim

# Install system dependencies needed for OpenCV, PaddleOCR, and compiling C binaries
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory inside the container
WORKDIR /app

# Copy requirements file first to utilize Docker build cache layers
COPY requirements.txt .

# Install python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose ports:
# - 8000: FastAPI backend API
# - 8050: Web scanner file upload dashboard
EXPOSE 8000
EXPOSE 8050

RUN chmod +x start.sh
CMD ["./start.sh"]
