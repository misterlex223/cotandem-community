#!/bin/bash

# Script to update the Kai system
# This script will update the Kai code, pull latest images, and optionally restart services

set -e  # Exit immediately if a command exits with a non-zero status

# Default values
KAI_DIR="$HOME/cotandem"
STOP_ON_UPDATE=true
START_AFTER_UPDATE=true

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --kai-dir DIR       Kai directory (default: $HOME/cotandem)"
    echo "  --no-stop               Don't stop services before updating (default: services are stopped)"
    echo "  --no-start              Don't start services after updating (default: services are started)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Update Kai with default settings"
    echo "  $0 --kai-dir /opt/kai   # Update Kai from /opt/kai"
    echo "  $0 --no-stop --no-start # Update code only, don't manage services"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--kai-dir)
            KAI_DIR="$2"
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
echo "Kai directory: $KAI_DIR"
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

# Function to backup current version (optional)
create_backup() {
    echo "Creating backup of current version..."
    
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="$KAI_DIR/backup_$TIMESTAMP"
    
    # Only backup key configuration files, not the entire directory
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "$KAI_DIR/docker-compose.yml" ]; then
        cp "$KAI_DIR/docker-compose.yml" "$BACKUP_DIR/"
    fi
    
    if [ -d "$KAI_DIR/backend" ] && [ -f "$KAI_DIR/backend/.env.local" ]; then
        cp "$KAI_DIR/backend/.env.local" "$BACKUP_DIR/"
    fi
    
    echo "Backup created at: $BACKUP_DIR"
    echo ""
}

# Function to update Kai repository
update_kai_repo() {
    echo "Updating Kai repository..."
    
    cd "$KAI_DIR"
    
    # Save current state
    echo "Current git status:"
    git status --short
    
    # Pull latest changes
    echo "Pulling latest changes from repository..."
    git fetch origin
    git pull origin main
    
    echo "Kai repository updated."
    echo ""
}

# Function to stop services if needed
stop_services_for_update() {
    if [ "$STOP_ON_UPDATE" = true ]; then
        echo "Stopping Kai services for update..."
        
        cd "$KAI_DIR"
        
        # Check if services are running
        if docker-compose ps --format "table {{.Names}}\t{{.Status}}" | grep -q "Up"; then
            docker-compose down
            echo "Services stopped."
        else
            echo "Services were not running."
        fi
    else
        echo "Skipping service stop (as requested)."
    fi
    
    echo ""
}

# Function to install updated dependencies
update_dependencies() {
    echo "Updating Kai dependencies..."
    
    cd "$KAI_DIR"
    
    # Install backend dependencies
    if [ -d "backend" ]; then
        cd backend
        pnpm install
        cd ..
    fi
    
    # Install frontend dependencies
    if [ -d "frontend" ]; then
        cd frontend
        pnpm install
        cd ..
    fi
    
    echo "Dependencies updated."
    echo ""
}

# Function to rebuild Flexy sandbox image if needed
rebuild_flexy_image() {
    echo "Checking for Flexy sandbox image updates..."
    
    cd "$KAI_DIR"
    
    if [ -f "Flexy/Dockerfile" ]; then
        echo "Rebuilding Flexy sandbox image..."
        docker build -t flexy-dev-sandbox:latest ./Flexy
        echo "Flexy sandbox image rebuilt successfully."
    else
        echo "Flexy/Dockerfile not found. Skipping image rebuild."
    fi
    
    echo ""
}

# Function to pull latest service images
pull_latest_images() {
    echo "Pulling latest service images..."
    
    cd "$KAI_DIR"
    
    # Pull latest images for all services
    docker-compose pull
    
    echo "Latest images pulled."
    echo ""
}

# Function to build updated images
build_updated_images() {
    echo "Building updated images..."
    
    cd "$KAI_DIR"
    
    # Build updated images
    docker-compose build
    
    echo "Images built."
    echo ""
}

# Function to start services after update
start_services_after_update() {
    if [ "$START_AFTER_UPDATE" = true ]; then
        echo "Starting Kai services after update..."
        
        cd "$KAI_DIR"
        docker-compose up -d
        
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
    
    cd "$KAI_DIR"
    
    echo "Current git commit:"
    git log -1 --oneline
    
    if [ "$START_AFTER_UPDATE" = true ]; then
        echo ""
        echo "Running services:"
        docker-compose ps
    else
        echo ""
        echo "Services were not started. To start them, run:"
        echo "  cd $KAI_DIR && docker-compose up -d"
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
    create_backup
    stop_services_for_update
    update_kai_repo
    update_dependencies
    pull_latest_images
    build_updated_images
    rebuild_flexy_image
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
    echo "  cd $KAI_DIR && docker-compose logs -f"
}

# Run main function
main