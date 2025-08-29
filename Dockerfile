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

# --- DEBUGGING STEPS ---
# We are splitting the installation into multiple steps to pinpoint the exact failure.

# Step 6: Upgrade pip
RUN python -m pip install --no-cache-dir --upgrade pip

# Step 7: Install Python dependencies from requirements.txt
# If the build fails here, the error will be specific to the problematic package.
RUN python -m pip install --no-cache-dir --progress-bar off -r requirements.txt

# Step 8: Verify gunicorn installation after all other packages are installed
RUN python -c "import gunicorn"

# --- END DEBUGGING STEPS ---

# Step 9: Copy the application code
COPY . .

# Step 10: Create the downloads directory
RUN mkdir -p /app/downloads

# Step 11: Expose the port
EXPOSE 8000

# Step 12: Define the command to run the application
CMD ["python", "-m", "gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]

