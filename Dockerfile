# Step 1: Use a stable base image
FROM python:3.11-bullseye

# Step 2: Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Step 3: Set the working directory
WORKDIR /app

# Step 4: Copy requirements file
COPY requirements.txt .

# Step 5: Upgrade pip and install dependencies with the progress bar DISABLED
# This is the key fix for the "can't start new thread" error discovered during debugging.
RUN python -m pip install --no-cache-dir --upgrade pip && \
    python -m pip install --no-cache-dir --progress-bar off -r requirements.txt

# Step 6: Copy the application code
COPY . .

# Step 7: Create the downloads directory
RUN mkdir -p /app/downloads

# Step 8: Expose the port
EXPOSE 8000

# Step 9: Define the command to run the application using the full path
# This is the exact path you found using "which gunicorn".
CMD ["/usr/local/bin/gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]

