# Step 1: Use a more stable and complete base image to avoid path issues
FROM python:3.11-bullseye

# Step 2: Set environment variables to ensure Python can find packages
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH="/usr/local/lib/python3.11/site-packages"

# Step 3: Set the working directory
WORKDIR /app

# Step 4: Copy requirements file first for better caching
COPY requirements.txt .

# Step 5: Upgrade pip and install dependencies using the most robust method
RUN python -m pip install --no-cache-dir --upgrade pip && \
    python -m pip install --no-cache-dir -r requirements.txt

# Step 6: Copy the rest of the application code
COPY . .

# Step 7: Create the downloads directory
RUN mkdir -p /app/downloads

# Step 8: Expose the port the app runs on
EXPOSE 8000

# Step 9: Define the command to run the application
# This runs gunicorn as a module, which is the most reliable way
CMD ["python", "-m", "gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]

