#!/bin/bash

# Script to update the Kai system
# This script will update the Kai code, pull latest images from GHCR, and optionally restart services

set -e  # Exit immediately if a command exits with a non-zero status

# Default values
GITHUB_USER="misterlex223"
STOP_ON_UPDATE=true
START_AFTER_UPDATE=true

# GitHub Container Registry image names
BACKEND_IMAGE_NAME="cotandem-backend"
FRONTEND_IMAGE_NAME="cotandem-frontend"
FLEXY_IMAGE_NAME="flexy-dev-sandbox"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -u, --user USER         GitHub username (default: $GITHUB_USER)"
    echo "  --no-stop               Don't stop services before updating (default: services are stopped)"
    echo "  --no-start              Don't start services after updating (default: services are started)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Update Kai with default settings"
    echo "  $0 --user myuser        # Update with custom GitHub user"
    echo "  $0 --no-stop --no-start # Update images only, don't manage services"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            GITHUB_USER="$2"
            shift 2
            ;;
        --no-stop)
            STOP_ON_UPDATE=false
            shift
            ;;
        --no-start)
            START_AFTER_UPDATE=false
            shift
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

echo "Updating Kai system..."
echo "GitHub user: $GITHUB_USER"
echo "Stop services during update: $STOP_ON_UPDATE"
echo "Start services after update: $START_AFTER_UPDATE"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo "Error: git is not installed" >&2
        exit 1
    fi

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

    echo "Prerequisites check passed."
    echo ""
}

# Function to pull latest service images from GHCR
pull_latest_images() {
    echo "Pulling latest service images from GitHub Container Registry..."
    
    # Login to GitHub Container Registry (if not already logged in)
    if ! docker info 2>/dev/null | grep -q "ghcr.io" && ! (docker system info 2>/dev/null | grep -q "ghcr.io"); then
        echo "Please log in to GitHub Container Registry:"
        echo "  docker login ghcr.io"
        echo "This step is required to pull images from GHCR."
        read -p "Press Enter to continue after logging in..."
    fi
    
    # Pull backend image
    echo "Pulling backend image..."
    docker pull "ghcr.io/$GITHUB_USER/$BACKEND_IMAGE_NAME:latest"
    docker tag "ghcr.io/$GITHUB_USER/$BACKEND_IMAGE_NAME:latest" "$BACKEND_IMAGE_NAME:latest"
    
    # Pull frontend image
    echo "Pulling frontend image..."
    docker pull "ghcr.io/$GITHUB_USER/$FRONTEND_IMAGE_NAME:latest"
    docker tag "ghcr.io/$GITHUB_USER/$FRONTEND_IMAGE_NAME:latest" "$FRONTEND_IMAGE_NAME:latest"
    
    # Pull Flexy image
    echo "Pulling Flexy sandbox image..."
    docker pull "ghcr.io/$GITHUB_USER/$FLEXY_IMAGE_NAME:latest"
    docker tag "ghcr.io/$GITHUB_USER/$FLEXY_IMAGE_NAME:latest" "$FLEXY_IMAGE_NAME:latest"
    
    echo "Latest images pulled."
    echo ""
}

# Function to stop services if needed
stop_services_for_update() {
    if [ "$STOP_ON_UPDATE" = true ]; then
        echo "Stopping Kai services for update..."
        
        # Define the container names
        containers=("kai-backend" "kai-frontend" "kai-code-server")
        
        # Stop each container if it's running
        for container in "${containers[@]}"; do
            if [ "$(docker ps -q -f name=$container)" ]; then
                echo "Stopping $container..."
                docker stop $container
                echo "$container stopped."
            else
                echo "$container is not running."
            fi
        done
        
        echo "Services stopped."
    else
        echo "Skipping service stop (as requested)."
    fi
    
    echo ""
}

# Function to start services after update
start_services_after_update() {
    if [ "$START_AFTER_UPDATE" = true ]; then
        echo "Starting Kai services after update..."
        
        # Run the start command (this will use the updated images)
        ./scripts/start-kai.sh
        
        echo "Services started."
    else
        echo "Skipping service start (as requested)."
    fi
    
    echo ""
}

# Function to show update summary
show_summary() {
    echo "Update completed!"
    echo "=================="
    
    if [ "$START_AFTER_UPDATE" = true ]; then
        echo ""
        echo "Running services:"
        docker ps --filter name=kai- --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    else
        echo ""
        echo "Services were not started. To start them, run:"
        echo "  ./start-kai.sh"
    fi
    
    echo ""
    echo "Update completed at: $(date)"
    echo ""
}

# Main execution
main() {
    echo "Starting Kai system update..."
    echo "=============================="
    echo ""

    check_prerequisites
    stop_services_for_update
    pull_latest_images
    start_services_after_update
    show_summary

    echo "=============================="
    echo "Kai system update completed!"
    echo ""
    echo "To verify the system is working, visit:"
    echo "  Frontend: http://localhost:9901"
    echo "  Backend:  http://localhost:9900"
    echo ""
    echo "To view logs, run:"
    echo "  docker logs kai-backend -f"
    echo "  docker logs kai-frontend -f"
    echo "  docker logs kai-code-server -f"
}

# Run main function
main