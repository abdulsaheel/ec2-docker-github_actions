# **Automated Flask App Deployment on AWS EC2 with Docker and GitHub Actions**

Welcome to the **Flask App Deployment** repository! This guide will walk you through deploying a simple Flask application to an EC2 instance using Docker and GitHub Actions. By the end of this guide, you'll have a streamlined CI/CD pipeline that automatically builds, tests, and deploys your application.

## **Table of Contents**

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
  - [1. Repository Setup](#1-repository-setup)
  - [2. Dockerfile](#2-dockerfile)
  - [3. GitHub Actions Workflow](#3-github-actions-workflow)
  - [4. EC2 Setup](#4-ec2-setup)
- [Deployment Steps](#deployment-steps)
- [Images](#images)
- [Contributing](#contributing)
- [License](#license)

## **Project Overview**

This project demonstrates a Continuous Integration and Continuous Deployment (CI/CD) pipeline for a Flask application. It uses Docker to containerize the application and GitHub Actions for automated building and deployment. The application is deployed to an AWS EC2 instance, ensuring scalability and reliability. The setup also includes functionality for handling private Docker images with login capabilities and automatically detects and stops previous containers if they exist.

## **Prerequisites**

Before you start, ensure you have the following:

- **AWS EC2 Instance**: Set up with Docker installed.
- **GitHub Repository**: Where your code and GitHub Actions workflow will reside.
- **Docker Hub Account**: For pushing and pulling Docker images.
- **GitHub Secrets**: For securely storing credentials and configurations.

## **Setup Instructions**

### 1. Repository Setup

1. **Clone or Fork the Repository**:
    - You can Fork this repo by clicking the Fork button  
   ```bash
   https://github.com/abdulsaheel/ec2-docker-github_actions.git
   cd ec2-docker-github_actions
   ```

2. **Update GitHub Secrets**:

   To securely store credentials and configurations, you need to add secrets to your GitHub repository. Follow these steps:

### **2. Update GitHub Secrets**

Navigate to your GitHub repository's **Settings** > **Secrets and variables** > **Actions**. Click **New repository secret** to add each of the following secrets:

- **DOCKER_USERNAME**: Your Docker Hub username.
  - **Name**: `DOCKER_USERNAME`
  - **Value**: Your Docker Hub username (e.g., `your_docker_username`).

- **DOCKER_PASSWORD**: Your Docker Hub password or Personal Access Token (PAT).
  - **Name**: `DOCKER_PASSWORD`
  - **Value**: Your Docker Hub password or PAT. 
    - **Personal Access Token (PAT)**: If you prefer using a PAT instead of a password, generate one from Docker Hub.
      - **To generate a PAT**:
        1. Log in to [Docker Hub](https://hub.docker.com/).
        2. Click on your profile icon at the top-right corner and select **Account Settings**.
        3. Go to the **Security** tab.
        4. Click **New Access Token** and follow the instructions to generate a token.
        5. Copy the token and use it as the value for `DOCKER_PASSWORD`.

- **SSH_PRIVATE_KEY**: The private SSH key for accessing your EC2 instance.
  - **Name**: `SSH_PRIVATE_KEY`
  - **Value**: Your private SSH key (ensure this key has the necessary permissions to access your EC2 instance).

- **SSH_HOST**: The public DNS or IP address of your EC2 instance.
  - **Name**: `SSH_HOST`
  - **Value**: Your EC2 instance's public DNS or IP address (e.g., `ec2-13-238-175-180.ap-south-1.compute.amazonaws.com`).

- **USER_NAME**: The SSH username for your EC2 instance.
  - **Name**: `USER_NAME`
  - **Value**: The SSH username for your EC2 instance (e.g., `ec2-user` or `ubuntu`).

### 2. Dockerfile

Ensure you have a `Dockerfile` in the root of your repository. Here's a sample `Dockerfile` for a Flask application:

```dockerfile
# Use the official Python image from the Docker Hub
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements.txt file into the container
COPY requirements.txt requirements.txt

# Install the dependencies
RUN pip install -r requirements.txt

# Copy the source code into the container
COPY app.py app.py

# Expose port 5000 to the outside world
EXPOSE 5000

# Command to run the application
CMD ["python", "app.py"]
```

### 3. GitHub Actions Workflow

Create a GitHub Actions workflow file at `.github/workflows/main.yml`:

```yaml
name: CI/CD Pipeline
on:
  push:
    branches:
      - main
jobs:
  build_and_push:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: 3.11
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
    - name: Run tests
      run: |
        pytest
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    - name: Log in to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    - name: Build Docker image
      run: |
        docker build -t ${{ secrets.DOCKER_USERNAME }}/my-flask-app:latest .
    - name: Push Docker image
      run: |
        docker push ${{ secrets.DOCKER_USERNAME }}/my-flask-app:latest
  deploy:
    name: Deploy to EC2
    runs-on: ubuntu-latest
    needs: build_and_push
    steps:
    - name: Set up SSH
      env:
        PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
        HOSTNAME: ${{ secrets.SSH_HOST }}
        USER_NAME: ${{ secrets.USER_NAME }}
      run: |
        echo "$PRIVATE_KEY" > private_key
        chmod 600 private_key
    - name: Deploy Docker container to EC2
      env:
        HOSTNAME: ${{ secrets.SSH_HOST }}
        USER_NAME: ${{ secrets.USER_NAME }}
        DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
        DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
      run: |
        ssh -o StrictHostKeyChecking=no -i private_key ${USER_NAME}@${HOSTNAME} << EOF
          # Log in to Docker Hub
          echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
          
          # Check for existing containers and remove them
          if docker ps -a --format '{{.Names}}' | grep -q '^my-flask-app$'; then
            echo "Stopping and removing existing container..."
            docker stop my-flask-app || true
            docker rm my-flask-app || true
          fi
          
          # Pull the latest Docker image
          echo "Pulling latest image..."
          sudo docker pull $DOCKER_USERNAME/my-flask-app:latest
          
          # Run the new Docker container
          echo "Starting new container..."
          sudo docker run -d --name my-flask-app -p 5000:5000 $DOCKER_USERNAME/my-flask-app:latest || echo "Failed to start the new container."
        EOF
```

### 4. EC2 Setup

1. **Install Docker on EC2**:
   Follow [Docker's official guide](https://docs.docker.com/engine/install/) to install Docker on your EC2 instance.

2. **Configure Security Groups**:
   Ensure that your EC2 instance's security group allows inbound traffic on port 5000 (or any other port you’re using).

## **Deployment Steps**

1. **Push Code to GitHub**:
   - Commit and push your changes to the `main` branch of your GitHub repository.

   ```bash
   git add .
   git commit -m "Set up CI/CD pipeline"
   git push origin main
   ```

2. **Monitor the GitHub Actions Workflow**:
   - Go to the **Actions** tab of your GitHub repository to see the pipeline in action. The workflow will build the Docker image, push it to Docker Hub, and deploy it to your EC2 instance.

3. **Verify Deployment**:
   - Access your application via the public IP or DNS of your EC2 instance at port 5000 (e.g., `http://<EC2_PUBLIC_IP>:5000`).

