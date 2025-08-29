# Step 1: Use an official Python runtime as a parent image
FROM python:3.11-slim

# Step 2: Set the working directory
WORKDIR /app

# Step 3: Copy requirements and install them globally as root
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Step 4: Copy the rest of the application code
COPY . .

# Step 5: Create the downloads directory
RUN mkdir -p /app/downloads

# Step 6: Expose the port the app runs on
EXPOSE 8000

# Step 7: Define the command to run the application.
# We run gunicorn as a Python module to bypass all PATH issues.
CMD ["python", "-m", "gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]

