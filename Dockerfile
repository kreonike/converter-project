# Step 1: Use an official Python runtime as a parent image
FROM python:3.11-slim

# Step 2: Set the working directory
WORKDIR /home/appuser/app

# Step 3: Copy requirements and install them globally as root
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Step 4: Copy the rest of the application code
COPY . .

# Step 5: Create a non-root user
RUN useradd -m appuser

# Step 6: Create downloads directory and set permissions for the whole app directory
RUN mkdir -p /home/appuser/app/downloads && chown -R appuser:appuser /home/appuser/app

# Step 7: Switch to the non-root user for security
USER appuser

# Step 8: Expose the port the app runs on
EXPOSE 8000

# Step 9: Define the command to run the application.
# Gunicorn is now in the global path and should be found.
CMD ["gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]

