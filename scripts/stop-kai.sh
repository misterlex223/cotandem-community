#!/bin/bash

# Script to stop the Kai system
# This script will stop the Kai services using Docker commands directly

set -e  # Exit immediately if a command exits with a non-zero status

# Function to display usage
usage() {
    echo "Usage: $0"
    echo ""
    echo "Examples:"
    echo "  $0                      # Stop Kai with default settings"
    exit 1
}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

echo "Stopping Kai system..."
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

    echo "Prerequisites check passed."
    echo ""
}

# Function to stop Kai services
stop_kai_services() {
    echo "Stopping Kai services..."
    
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
    
    echo ""
}

# Function to show system status after stopping
show_status() {
    echo "Kai services status after stopping:"
    echo "===================================="
    
    running_containers=$(docker ps --filter name=kai- --format "table {{.Names}}\t{{.Status}}")
    
    if [ -z "$running_containers" ]; then
        echo "No Kai services are currently running."
    else
        echo "$running_containers"
    fi
    
    echo ""
    echo "Kai system has been stopped."
    echo ""
}

# Main execution
main() {
    echo "Stopping Kai system..."
    echo "=============================="
    echo ""

    check_prerequisites
    stop_kai_services
    show_status

    echo "=============================="
    echo "Kai system stopped successfully!"
    echo ""
    echo "To start the system again, run:"
    echo "  ./start-kai.sh"
}

# Run main function
main