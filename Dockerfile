FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Install system dependencies required for speech recognition (Whisper) and image processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend script
COPY backend.py .

# Expose the port that the application runs on
EXPOSE 7860

# Run the application
CMD ["python", "backend.py"]
