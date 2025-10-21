#!/bin/bash

# Script to start the Kai system
# This script will start the Kai services using docker-compose

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
    echo "  $0                      # Start Kai with default settings"
    echo "  $0 --kai-dir /opt/kai   # Start Kai from /opt/kai"
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

echo "Starting Kai system..."
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

# Function to start Kai services
start_kai_services() {
    echo "Starting Kai services..."
    
    cd "$KAI_DIR"
    
    # Check if services are already running
    if docker-compose ps | grep -q "Up"; then
        echo "Warning: Some Kai services appear to be already running."
        read -p "Do you want to continue and restart them? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            exit 0
        fi
    fi
    
    # Start the services
    docker-compose up -d
    
    echo "Kai services started successfully."
    echo ""
}

# Function to wait for services to be ready
wait_for_services() {
    echo "Waiting for services to be ready..."
    
    cd "$KAI_DIR"
    
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
    
    cd "$KAI_DIR"
    docker-compose ps
    
    echo ""
    echo "Access the system at:"
    echo "  Frontend: http://localhost:9901"
    echo "  Backend:  http://localhost:9900"
    echo "  Code Server: http://localhost:8443"
    echo ""
    echo "To view logs, run: cd $KAI_DIR && docker-compose logs -f"
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
    echo "  $0 stop-kai.sh --kai-dir $KAI_DIR"
    echo ""
    echo "To view logs, run:"
    echo "  cd $KAI_DIR && docker-compose logs -f"
}

# Run main function
main