# Step 1: Use an official Python runtime as a parent image
FROM python:3.11-slim

# Step 2: Set the working directory
WORKDIR /app

# Step 3: Upgrade pip for compatibility
RUN pip install --no-cache-dir --upgrade pip

# Step 4: Copy requirements and install all dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Step 5: Copy the rest of the application code
COPY . .

# Step 6: Create the downloads directory
RUN mkdir -p /app/downloads

# Step 7: Expose the port the app runs on
EXPOSE 8000

# Step 8: Define the command to run the application.
# This runs gunicorn as a module, which is the most reliable way.
CMD ["python", "-m", "gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]

