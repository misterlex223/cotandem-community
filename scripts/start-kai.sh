#!/bin/bash

# Script to start the Kai system
# This script will start the Kai services using Docker run commands directly

set -e  # Exit immediately if a command exits with a non-zero status

# Default values
KAI_BASE_DIR="$HOME/KaiBase"
CODE_SERVER_PASSWORD="kai-dev"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -b, --base-dir DIR      Base directory for Kai projects (default: $KAI_BASE_DIR)"
    echo "  -p, --password         Password for code-server (default: $CODE_SERVER_PASSWORD)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Start Kai with default settings"
    echo "  $0 --base-dir /data/kai-base   # Start with custom base directory"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--base-dir)
            KAI_BASE_DIR="$2"
            shift 2
            ;;
        -p|--password)
            CODE_SERVER_PASSWORD="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

echo "Starting Kai system..."
echo "Base directory: $KAI_BASE_DIR"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Error: docker is not installed" >&2
        exit 1
    fi

    # Check if docker daemon is running
    if ! docker info &> /dev/null; then
        echo "Error: Docker daemon is not running. Please start Docker Desktop or Docker service." >&2
        exit 1
    fi

    # Check if required images exist
    if ! docker images | grep -q "cotandem-backend\|cotandem-frontend\|flexy-dev-sandbox"; then
        echo "Error: Required images not found. Please run setup script first to pull images from GHCR." >&2
        exit 1
    fi

    echo "Prerequisites check passed."
    echo ""
}

# Function to start Kai services
start_kai_services() {
    echo "Starting Kai services..."
    
    # Export the variable to make it available in the docker run command
    export KAI_BASE_ROOT="$KAI_BASE_DIR"
    
    # Stop existing containers if they're running
    for container in kai-backend kai-frontend kai-code-server; do
        if [ "$(docker ps -q -f name=$container)" ]; then
            echo "Stopping existing $container container..."
            docker stop $container
        fi
        
        # Remove container if it exists but is stopped
        if [ "$(docker ps -a -q -f name=$container)" ]; then
            echo "Removing existing $container container..."
            docker rm $container
        fi
    done
    
    # Get current user's UID and GID
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)

    # Start backend service
    echo "Starting backend service (as UID:GID $USER_ID:$GROUP_ID)..."
    docker run -d \
        --name kai-backend \
        --network kai-net \
        --privileged \
        -p 9900:9900 \
        -e NODE_ENV=production \
        -e PORT=9900 \
        -e DOCKER_NETWORK=kai-net \
        -e IMAGE_NAME=flexy-dev-sandbox:latest \
        -e KAI_BASE_ROOT="$KAI_BASE_ROOT" \
        -e USER_ID="$USER_ID" \
        -e GROUP_ID="$GROUP_ID" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$KAI_BASE_ROOT:/base-root" \
        cotandem-backend:latest
    
    # Create code-server persistence directories
    mkdir -p "$KAI_BASE_ROOT/.kai/code-server"/{config,local}

    # Determine which code-server image to use
    if docker images | grep -q "kai-code-server"; then
        CODE_SERVER_IMAGE="kai-code-server:latest"
    else
        CODE_SERVER_IMAGE="codercom/code-server:latest"
        echo "Warning: Using official code-server image (Docker CLI not available)"
        echo "To enable Docker CLI in code-server, run: ./scripts/setup-kai.sh"
    fi

    # Start code-server service
    echo "Starting code-server service (as UID:GID $USER_ID:$GROUP_ID)..."
    docker run -d \
        --name kai-code-server \
        --network kai-net \
        --privileged \
        -p 8443:8080 \
        -e PASSWORD="$CODE_SERVER_PASSWORD" \
        -e USER_ID="$USER_ID" \
        -e GROUP_ID="$GROUP_ID" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$KAI_BASE_ROOT:/base-root" \
        -v "$KAI_BASE_ROOT/.kai/code-server/config:/home/coder/.config" \
        -v "$KAI_BASE_ROOT/.kai/code-server/local:/home/coder/.local" \
        "$CODE_SERVER_IMAGE" \
        --bind-addr 0.0.0.0:8080
    
    # Start frontend service
    echo "Starting frontend service..."
    docker run -d \
        --name kai-frontend \
        --network kai-net \
        -p 9901:80 \
        -e API_BASE_URL= \
        cotandem-frontend:latest
    
    echo "Kai services started successfully."
    echo ""
}

# Function to wait for services to be ready
wait_for_services() {
    echo "Waiting for services to be ready..."
    
    # Wait for backend to be ready
    echo -n "Waiting for backend (port 9900)..."
    timeout 120 bash -c 'until curl -s -f -o /dev/null http://localhost:9900/api/health; do sleep 2; echo -n "."; done' 2>/dev/null
    if [ $? -eq 0 ]; then
        echo " OK"
    else
        echo " TIMEOUT - Backend might take longer to start"
    fi
    
    # Wait for frontend to be ready
    echo -n "Waiting for frontend (port 9901)..."
    timeout 60 bash -c 'until curl -s -f -o /dev/null http://localhost:9901; do sleep 2; echo -n "."; done' 2>/dev/null
    if [ $? -eq 0 ]; then
        echo " OK"
    else
        echo " TIMEOUT - Frontend might take longer to start"
    fi
    
    echo ""
}

# Function to show service status
show_status() {
    echo "Kai services status:"
    echo "===================="
    
    docker ps --filter name=kai- --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "Access the system at:"
    echo "  Frontend: http://localhost:9901"
    echo "  Backend:  http://localhost:9900"
    echo "  Code Server: http://localhost:8443"
    echo ""
    echo "To view logs, run: docker logs <container-name> or docker logs -f <container-name>"
}

# Main execution
main() {
    echo "Starting Kai system..."
    echo "=============================="
    echo ""

    check_prerequisites
    start_kai_services
    wait_for_services
    show_status

    echo "=============================="
    echo "Kai system started successfully!"
    echo ""
    echo "To stop the system, run:"
    echo "  ./stop-kai.sh"
    echo ""
    echo "To view logs, run:"
    echo "  docker logs kai-backend -f"
    echo "  docker logs kai-frontend -f"
    echo "  docker logs kai-code-server -f"
}

# Run main function
main