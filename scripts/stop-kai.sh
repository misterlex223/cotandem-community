#!/bin/bash

# Script to stop the Kai system
# This script will stop the Kai services using docker-compose

set -e  # Exit immediately if a command exits with a non-zero status

# Default values
KAI_DIR="$HOME/cotandem"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --kai-dir DIR       Kai directory (default: $HOME/cotandem)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Stop Kai with default settings"
    echo "  $0 --kai-dir /opt/kai   # Stop Kai from /opt/kai"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--kai-dir)
            KAI_DIR="$2"
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

echo "Stopping Kai system..."
echo "Kai directory: $KAI_DIR"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Error: docker is not installed" >&2
        exit 1
    fi

    # Check if docker-compose is installed
    if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
        echo "Error: docker-compose is not installed" >&2
        exit 1
    fi

    # Check if docker daemon is running
    if ! docker info &> /dev/null; then
        echo "Error: Docker daemon is not running. Please start Docker Desktop or Docker service." >&2
        exit 1
    fi

    # Check if Kai directory exists
    if [ ! -d "$KAI_DIR" ]; then
        echo "Error: Kai directory does not exist: $KAI_DIR" >&2
        exit 1
    fi

    # Check if docker-compose.yml exists in Kai directory
    if [ ! -f "$KAI_DIR/docker-compose.yml" ]; then
        echo "Error: docker-compose.yml not found in Kai directory: $KAI_DIR" >&2
        exit 1
    fi

    echo "Prerequisites check passed."
    echo ""
}

# Function to stop Kai services
stop_kai_services() {
    echo "Stopping Kai services..."
    
    cd "$KAI_DIR"
    
    # Check if services are running
    if docker-compose ps --format "table {{.Names}}\t{{.Status}}" | grep -q "Up"; then
        echo "Found running Kai services:"
        docker-compose ps --format "table {{.Names}}\t{{.Status}}"
        echo ""
        
        # Stop the services
        docker-compose down
        
        echo "Kai services stopped successfully."
    else
        echo "No Kai services appear to be running."
        echo "Current status:"
        docker-compose ps
    fi
    
    echo ""
}

# Function to show system status after stopping
show_status() {
    echo "Kai services status after stopping:"
    echo "===================================="
    
    cd "$KAI_DIR"
    docker-compose ps
    
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
    echo "  $0 start-kai.sh --kai-dir $KAI_DIR"
    echo ""
    echo "To completely remove containers and volumes, run:"
    echo "  cd $KAI_DIR && docker-compose down -v"
}

# Run main function
main