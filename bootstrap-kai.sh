#!/bin/bash

# Minimal bootstrap script to set up the Kai system
# Downloads only the essential scripts without requiring a full git clone

set -e  # Exit immediately if a command exits with a non-zero status

# Default values
KAI_BASE_DIR="$HOME/KaiBase"
INSTALL_DIR="$HOME/kai-scripts"
GITHUB_USER="misterlex223"

# GitHub Container Registry image names
BACKEND_IMAGE_NAME="cotandem-backend"
FRONTEND_IMAGE_NAME="cotandem-frontend"
FLEXY_IMAGE_NAME="flexy-dev-sandbox"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --dir DIR           Directory to install scripts (default: $INSTALL_DIR)"
    echo "  -b, --base-dir DIR      Base directory for Kai projects (default: $KAI_BASE_DIR)"
    echo "  -u, --user USER         GitHub username (default: $GITHUB_USER)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Install with default settings"
    echo "  $0 --dir /opt/kai       # Install scripts in /opt/kai"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -b|--base-dir)
            KAI_BASE_DIR="$2"
            shift 2
            ;;
        -u|--user)
            GITHUB_USER="$2"
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

echo "Setting up Kai system with minimal bootstrap..."
echo "Scripts directory: $INSTALL_DIR"
echo "Base directory: $KAI_BASE_DIR"
echo "GitHub user: $GITHUB_USER"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is not installed" >&2
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

# Function to download scripts
download_scripts() {
    echo "Downloading Kai management scripts..."
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Download essential scripts
    SCRIPTS=(
        "setup-kai.sh"
        "start-kai.sh"
        "stop-kai.sh"
        "update-kai.sh"
        "manage-flexy-image.sh"
    )
    
    for script in "${SCRIPTS[@]}"; do
        echo "Downloading $script..."
        curl -s -o "$script" "https://raw.githubusercontent.com/$GITHUB_USER/cotandem-community/main/scripts/$script"
        chmod +x "$script"
    done
    
    echo "Scripts downloaded successfully."
    echo ""
}

# Function to create base directory
setup_base_directory() {
    echo "Setting up base directory: $KAI_BASE_DIR"
    
    mkdir -p "$KAI_BASE_DIR"
    echo "Base directory created at: $KAI_BASE_DIR"
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

# Function to pull images from GHCR
pull_images_from_ghcr() {
    echo "Pulling images from GitHub Container Registry..."

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

    echo "Images pulled successfully."
    echo ""
}

# Function to create environment configuration
create_env_config() {
    echo "Creating environment configuration..."
    
    # Create backend .env file
    cat > .env.local << EOF
# Kai Backend Configuration
PORT=9900
DOCKER_NETWORK=kai-net
IMAGE_NAME=flexy-dev-sandbox:latest
KAI_BASE_ROOT=${KAI_BASE_DIR}
EOF
    echo "Created .env.local"
    
    echo "Environment configuration created."
    echo ""
}

# Main execution
main() {
    echo "Starting minimal Kai system setup..."
    echo "====================================="
    echo ""

    check_prerequisites
    setup_base_directory
    download_scripts
    create_docker_network
    pull_images_from_ghcr
    create_env_config

    echo "====================================="
    echo "Minimal Kai system setup completed!"
    echo ""
    echo "To start the system, run:"
    echo "  cd $INSTALL_DIR && ./start-kai.sh"
    echo ""
    echo "Access the system at:"
    echo "  Frontend: http://localhost:9901"
    echo "  Backend:  http://localhost:9900"
    echo ""
    echo "To update the system in the future, run:"
    echo "  cd $INSTALL_DIR && ./update-kai.sh"
    echo ""
    echo "All scripts are located in: $INSTALL_DIR"
}

# Run main function
main