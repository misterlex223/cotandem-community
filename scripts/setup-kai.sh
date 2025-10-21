#!/bin/bash

# Script to set up the Kai system for the community
# This script will install prerequisites, download Kai, build images, and set up the environment

set -e  # Exit immediately if a command exits with a non-zero status

# Default values
KAI_BASE_DIR="$HOME/KaiBase"
KAI_GITHUB_REPO="https://github.com/misterlex/cotandem.git"
KAI_DIR="$HOME/cotandem"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --kai-dir DIR       Directory to install Kai (default: $HOME/cotandem)"
    echo "  -b, --base-dir DIR      Base directory for Kai projects (default: $HOME/KaiBase)"
    echo "  -r, --repo URL          GitHub repository URL (default: $KAI_GITHUB_REPO)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Setup with default settings"
    echo "  $0 --kai-dir /opt/kai   # Setup Kai in /opt/kai"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--kai-dir)
            KAI_DIR="$2"
            shift 2
            ;;
        -b|--base-dir)
            KAI_BASE_DIR="$2"
            shift 2
            ;;
        -r|--repo)
            KAI_GITHUB_REPO="$2"
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

echo "Setting up Kai system..."
echo "Kai directory: $KAI_DIR"
echo "Base directory: $KAI_BASE_DIR"
echo "GitHub repository: $KAI_GITHUB_REPO"
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

    # Check if node is installed
    if ! command -v node &> /dev/null; then
        echo "Error: node is not installed" >&2
        exit 1
    fi

    # Check if pnpm is installed
    if ! command -v pnpm &> /dev/null; then
        echo "Warning: pnpm is not installed, installing..."
        npm install -g pnpm
    fi

    # Check if docker daemon is running
    if ! docker info &> /dev/null; then
        echo "Error: Docker daemon is not running. Please start Docker Desktop or Docker service." >&2
        exit 1
    fi

    echo "Prerequisites check passed."
    echo ""
}

# Function to clone or update Kai repository
setup_kai_repo() {
    echo "Setting up Kai repository..."
    
    if [ -d "$KAI_DIR" ]; then
        echo "Kai directory already exists. Updating..."
        cd "$KAI_DIR"
        git pull origin main
    else
        echo "Cloning Kai repository..."
        git clone "$KAI_GITHUB_REPO" "$KAI_DIR"
        cd "$KAI_DIR"
    fi

    echo "Kai repository setup complete."
    echo ""
}

# Function to create base directory
setup_base_directory() {
    echo "Setting up base directory: $KAI_BASE_DIR"
    
    mkdir -p "$KAI_BASE_DIR"
    echo "Base directory created at: $KAI_BASE_DIR"
    echo ""
}

# Function to install dependencies
install_dependencies() {
    echo "Installing Kai dependencies..."
    
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
    
    echo "Dependencies installed."
    echo ""
}

# Function to build Flexy sandbox image
build_flexy_image() {
    echo "Building Flexy sandbox image..."
    
    cd "$KAI_DIR"
    
    if [ -f "Flexy/Dockerfile" ]; then
        docker build -t flexy-dev-sandbox:latest ./Flexy
        echo "Flexy sandbox image built successfully."
    else
        echo "Warning: Flexy/Dockerfile not found. Skipping Flexy image build."
    fi
    
    echo ""
}

# Function to create Docker network
create_docker_network() {
    echo "Creating Docker network..."
    
    # Create the kai-net network if it doesn't exist
    if ! docker network ls | grep -q "kai-net"; then
        docker network create kai-net
        echo "Docker network 'kai-net' created."
    else
        echo "Docker network 'kai-net' already exists."
    fi
    
    echo ""
}

# Function to create environment configuration
create_env_config() {
    echo "Creating environment configuration..."
    
    cd "$KAI_DIR"
    
    # Create backend .env file if it doesn't exist
    if [ ! -f "backend/.env.local" ]; then
        cat > backend/.env.local << EOF
# Kai Backend Configuration
PORT=9900
DOCKER_NETWORK=kai-net
IMAGE_NAME=flexy-dev-sandbox:latest
KAI_BASE_ROOT=${KAI_BASE_DIR}
EOF
        echo "Created backend/.env.local"
    fi
    
    echo "Environment configuration created."
    echo ""
}

# Main execution
main() {
    echo "Starting Kai system setup..."
    echo "=============================="
    echo ""

    check_prerequisites
    setup_base_directory
    setup_kai_repo
    install_dependencies
    build_flexy_image
    create_docker_network
    create_env_config

    echo "=============================="
    echo "Kai system setup completed!"
    echo ""
    echo "To start the system, run:"
    echo "  cd $KAI_DIR"
    echo "  docker-compose up -d"
    echo ""
    echo "Access the system at:"
    echo "  Frontend: http://localhost:9901"
    echo "  Backend:  http://localhost:9900"
    echo ""
    echo "For more information on managing your Kai system, see the documentation:"
    echo "  cd $KAI_DIR && ls scripts/"
}

# Run main function
main