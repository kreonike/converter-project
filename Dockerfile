# Step 1: Use a stable base image
FROM python:3.11-bullseye

# Step 2: Set environment variables using the correct format
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Step 3: Install system dependencies required by Python packages
# docx2pdf requires LibreOffice to be installed.
RUN apt-get update && \
    apt-get install -y --no-install-recommends libreoffice && \
    rm -rf /var/lib/apt/lists/*

# Step 4: Set the working directory
WORKDIR /app

# Step 5: Copy requirements file
COPY requirements.txt .

# Step 6: Upgrade pip and install all dependencies
RUN python -m pip install --no-cache-dir --upgrade pip && \
    python -m pip install --no-cache-dir --progress-bar off -r requirements.txt

# Step 7: Copy the application code
COPY . .

# Step 8: Create the downloads directory
RUN mkdir -p /app/downloads

# Step 9: Expose the port
EXPOSE 8000

# Step 10: Define the command to run the application
CMD ["python", "-m", "gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]

