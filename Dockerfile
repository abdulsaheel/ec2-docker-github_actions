# Use the official Python image from the Docker Hub
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements.txt file into the container
COPY requirements.txt requirements.txt

# Install the dependencies
RUN pip install -r requirements.txt
 
#Copying the source code into the container
COPY app.py app.py

# Exposing port 5000 to the outside world
EXPOSE 5000

# command to run the application
CMD ["python", "app.py"]
