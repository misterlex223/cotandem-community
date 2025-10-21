#!/bin/bash

# Script to build and manage the Flexy sandbox image
# This script can build, push, pull, and manage the Flexy sandbox Docker image

set -e  # Exit immediately if a command exits with a non-zero status

# Default values
KAI_DIR="$HOME/cotandem"
FLEXY_DIR="$KAI_DIR/Flexy"
IMAGE_NAME="flexy-dev-sandbox"
IMAGE_TAG="latest"
REGISTRY="docker.io"  # Default to Docker Hub

# Function to display usage
usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build [OPTIONS]         Build the Flexy sandbox image"
    echo "  push [OPTIONS]          Push the Flexy sandbox image to a registry"
    echo "  pull [OPTIONS]          Pull the Flexy sandbox image from a registry"
    echo "  tag [OPTIONS]           Tag the Flexy sandbox image"
    echo "  list-tags [OPTIONS]     List available tags for the Flexy image"
    echo "  clean [OPTIONS]         Clean up old Flexy images"
    echo ""
    echo "Options:"
    echo "  -d, --kai-dir DIR       Kai directory (default: $HOME/cotandem)"
    echo "  -n, --name NAME         Image name (default: $IMAGE_NAME)"
    echo "  -t, --tag TAG           Image tag (default: $IMAGE_TAG)"
    echo "  -r, --registry REG      Registry (default: $REGISTRY)"
    echo "  -u, --username USER     Registry username"
    echo "  --no-cache              Build without cache"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build                                    # Build Flexy image with default settings"
    echo "  $0 build --no-cache                       # Build Flexy image without cache"
    echo "  $0 push -u myuser                         # Push Flexy image to Docker Hub"
    echo "  $0 push -u myuser -r ghcr.io              # Push Flexy image to GitHub Container Registry"
    echo "  $0 pull -u myuser -r ghcr.io              # Pull Flexy image from GitHub Container Registry"
    exit 1
}

# Parse command
COMMAND="$1"
if [ -z "$COMMAND" ]; then
    usage
fi
shift

# Parse command line arguments
NO_CACHE=false
USERNAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--kai-dir)
            KAI_DIR="$2"
            FLEXY_DIR="$KAI_DIR/Flexy"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE=true
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

echo "Executing command: $COMMAND for Flexy image..."
echo "Kai directory: $KAI_DIR"
echo "Flexy directory: $FLEXY_DIR"
echo "Image name: $IMAGE_NAME"
echo "Image tag: $IMAGE_TAG"
echo "Registry: $REGISTRY"
if [ -n "$USERNAME" ]; then
    echo "Username: $USERNAME"
fi
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

    # Check if Kai directory exists
    if [ ! -d "$KAI_DIR" ]; then
        echo "Error: Kai directory does not exist: $KAI_DIR" >&2
        exit 1
    fi

    # Check if Flexy directory exists
    if [ ! -d "$FLEXY_DIR" ]; then
        echo "Error: Flexy directory does not exist: $FLEXY_DIR" >&2
        exit 1
    fi

    # Check if Dockerfile exists in Flexy directory
    if [ ! -f "$FLEXY_DIR/Dockerfile" ]; then
        echo "Error: Dockerfile not found in Flexy directory: $FLEXY_DIR" >&2
        exit 1
    fi

    echo "Prerequisites check passed."
    echo ""
}

# Function to build Flexy image
build_flexy_image() {
    echo "Building Flexy sandbox image..."
    
    cd "$FLEXY_DIR"
    
    # Construct the build command
    BUILD_CMD="docker build"
    
    if [ "$NO_CACHE" = true ]; then
        BUILD_CMD="$BUILD_CMD --no-cache"
    fi
    
    # Build the image
    $BUILD_CMD -t "$IMAGE_NAME:$IMAGE_TAG" .
    
    echo "Flexy sandbox image built successfully."
    echo ""
}

# Function to tag Flexy image for registry
tag_for_registry() {
    local full_image_name
    
    if [ "$REGISTRY" = "docker.io" ]; then
        if [ -n "$USERNAME" ]; then
            full_image_name="$USERNAME/$IMAGE_NAME:$IMAGE_TAG"
        else
            full_image_name="$IMAGE_NAME:$IMAGE_TAG"
        fi
    else
        if [ -n "$USERNAME" ]; then
            full_image_name="$REGISTRY/$USERNAME/$IMAGE_NAME:$IMAGE_TAG"
        else
            echo "Error: Username is required for non-Docker Hub registries" >&2
            exit 1
        fi
    fi
    
    echo "Tagging image as: $full_image_name"
    docker tag "$IMAGE_NAME:$IMAGE_TAG" "$full_image_name"
    
    echo "Image tagged successfully."
    echo ""
}

# Function to push Flexy image
push_flexy_image() {
    echo "Pushing Flexy sandbox image..."
    
    local full_image_name
    
    if [ "$REGISTRY" = "docker.io" ]; then
        if [ -n "$USERNAME" ]; then
            full_image_name="$USERNAME/$IMAGE_NAME:$IMAGE_TAG"
        else
            echo "Error: Username is required to push to Docker Hub" >&2
            exit 1
        fi
    else
        if [ -n "$USERNAME" ]; then
            full_image_name="$REGISTRY/$USERNAME/$IMAGE_NAME:$IMAGE_TAG"
        else
            echo "Error: Username is required to push to registry" >&2
            exit 1
        fi
    fi
    
    # Tag the image if needed
    if [ "$REGISTRY" != "docker.io" ] || [ -n "$USERNAME" ]; then
        docker tag "$IMAGE_NAME:$IMAGE_TAG" "$full_image_name"
    fi
    
    # Push the image
    docker push "$full_image_name"
    
    echo "Flexy sandbox image pushed successfully to $full_image_name"
    echo ""
}

# Function to pull Flexy image
pull_flexy_image() {
    echo "Pulling Flexy sandbox image..."
    
    local full_image_name
    
    if [ "$REGISTRY" = "docker.io" ]; then
        if [ -n "$USERNAME" ]; then
            full_image_name="$USERNAME/$IMAGE_NAME:$IMAGE_TAG"
        else
            full_image_name="$IMAGE_NAME:$IMAGE_TAG"
        fi
    else
        if [ -n "$USERNAME" ]; then
            full_image_name="$REGISTRY/$USERNAME/$IMAGE_NAME:$IMAGE_TAG"
        else
            echo "Error: Username is required for non-Docker Hub registries" >&2
            exit 1
        fi
    fi
    
    # Pull the image
    docker pull "$full_image_name"
    
    echo "Flexy sandbox image pulled successfully from $full_image_name"
    
    # Tag it locally for Kai to use
    docker tag "$full_image_name" "$IMAGE_NAME:$IMAGE_TAG"
    
    echo "Image tagged locally as $IMAGE_NAME:$IMAGE_TAG"
    echo ""
}

# Function to list available tags
list_tags() {
    echo "Listing available tags for $IMAGE_NAME..."
    
    if [ -n "$USERNAME" ]; then
        REPO_NAME="$USERNAME/$IMAGE_NAME"
    else
        REPO_NAME="$IMAGE_NAME"
    fi
    
    # For Docker Hub
    if [ "$REGISTRY" = "docker.io" ]; then
        if command -v curl &> /dev/null; then
            echo "Available tags for $REPO_NAME on Docker Hub:"
            curl -s "https://registry.hub.docker.com/v2/repositories/$REPO_NAME/tags/" | python3 -m json.tool | grep -o '"name":"[^"]*"' | sed 's/"name":"//' | sed 's/"$//' | head -20
        else
            echo "curl command not found. Please install curl to list Docker Hub tags."
        fi
    # For GitHub Container Registry
    elif [ "$REGISTRY" = "ghcr.io" ]; then
        if [ -n "$USERNAME" ]; then
            if command -v curl &> /dev/null; then
                echo "Available tags for $REPO_NAME on GitHub Container Registry:"
                # This requires GitHub authentication for private repos
                echo "Please visit: https://github.com/users/$USERNAME/packages/container/package/$IMAGE_NAME"
            else
                echo "curl command not found. Please install curl to list GHCR tags."
            fi
        else
            echo "Username required for GitHub Container Registry."
        fi
    else
        echo "Listing tags for other registries not implemented. Please check the registry's UI."
    fi
    
    echo ""
    
    # Also list locally available tags
    echo "Locally available tags:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | grep "$IMAGE_NAME"
    echo ""
}

# Function to clean up old Flexy images
clean_flexy_images() {
    echo "Cleaning up old Flexy sandbox images..."
    
    # List all flexy-dev-sandbox images
    echo "Current Flexy images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedAt}}" | grep "$IMAGE_NAME"
    
    # Remove dangling images (untagged)
    echo "Removing dangling images..."
    docker images -f "dangling=true" -f "reference=$IMAGE_NAME" -q | xargs -r docker rmi
    
    # Option to remove all but latest (commented out by default for safety)
    # Uncomment the following lines if you want to remove all but the latest tag
    # OLD_IMAGES=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" | grep "$IMAGE_NAME" | grep -v "$IMAGE_TAG" | awk '{print $3}')
    # if [ -n "$OLD_IMAGES" ]; then
    #     echo "Removing old images..."
    #     echo "$OLD_IMAGES" | xargs -r docker rmi
    # fi
    
    echo "Old Flexy images cleaned up."
    echo ""
}

# Main execution based on command
main() {
    echo "Managing Flexy sandbox image..."
    echo "================================="
    echo ""

    check_prerequisites

    case $COMMAND in
        "build")
            build_flexy_image
            ;;
        "push")
            push_flexy_image
            ;;
        "pull")
            pull_flexy_image
            ;;
        "tag")
            tag_for_registry
            ;;
        "list-tags")
            list_tags
            ;;
        "clean")
            clean_flexy_images
            ;;
        *)
            echo "Unknown command: $COMMAND"
            usage
            ;;
    esac

    echo "================================="
    echo "Flexy image management completed!"
    echo ""
    if [ "$COMMAND" = "build" ]; then
        echo "To use this image with Kai, make sure your Kai configuration uses:"
        echo "  Image name: $IMAGE_NAME"
        echo "  Tag: $IMAGE_TAG"
        echo ""
        echo "To push to a registry, run: $0 push -u <username>"
    fi
}

# Run main function
main