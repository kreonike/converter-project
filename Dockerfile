# Step 1: Use an official Python runtime as a parent image
FROM python:3.11-slim

# Step 2: Set the working directory in the container
WORKDIR /home/appuser/app

# Step 3: Create a non-root user
RUN useradd -m appuser

# Step 4: Create downloads directory and set permissions
# Эта новая строка решает проблему с правами доступа
RUN mkdir -p /home/appuser/app/downloads && chown -R appuser:appuser /home/appuser/app/downloads

# Step 5: Switch to the non-root user
USER appuser

# Step 6: Copy the requirements file and install dependencies
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Step 7: Copy the rest of the application code
COPY --chown=appuser:appuser . .

# Step 8: Expose the port the app runs on
EXPOSE 8000

# Step 9: Define the command to run the application
CMD ["gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]

