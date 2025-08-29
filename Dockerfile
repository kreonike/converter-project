# Step 1: Use an official Python runtime as a parent image
FROM python:3.11-slim

# Step 2: Set environment variables for the virtual environment
# This tells subsequent commands to use the venv
ENV VENV_PATH=/opt/venv
ENV PATH="$VENV_PATH/bin:$PATH"

# Step 3: Create the virtual environment
RUN python -m venv $VENV_PATH

# Step 4: Set the working directory
WORKDIR /home/appuser/app

# Step 5: Copy requirements and install them into the venv
# pip will automatically use the activated venv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Step 6: Create a non-root user
RUN useradd -m appuser

# Step 7: Create downloads directory
RUN mkdir -p /home/appuser/app/downloads

# Step 8: Copy the rest of the application code
COPY . .

# Step 9: Change ownership of the entire directory to the new user
RUN chown -R appuser:appuser /home/appuser/app

# Step 10: Switch to the non-root user for security
USER appuser

# Step 11: Expose the port the app runs on
EXPOSE 8000

# Step 12: Define the command to run the application
# gunicorn is now in the PATH thanks to the ENV variable
CMD ["gunicorn", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000", "main:app"]

