# Cotandem Community Scripts

This repository contains community scripts to help you set up, deploy, manage, and update the Kai system with Flexy sandbox containers.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Available Scripts](#available-scripts)
4. [Image Naming Mapping](#image-naming-mapping)
5. [Quick Start](#quick-start)
6. [Detailed Usage](#detailed-usage)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## Overview

The Kai system is a sandbox orchestration platform that manages multiple Flexy development sandboxes. These scripts provide an easy way for the community to:

- Set up the Kai system from scratch using pre-built images from GitHub Container Registry (GHCR)
- Start and stop the system directly with Docker run commands
- Update the system to the latest version by pulling images from GHCR
- Manage the Flexy sandbox Docker images

## Prerequisites

Before using these scripts, ensure you have:

1. **Git** installed
2. **Docker** (Docker Desktop recommended)
3. **Node.js** (LTS version recommended)

## Available Scripts

All scripts are located in the `scripts/` directory:

### System Scripts

- `setup-kai.sh` - Set up the entire Kai system by pulling images from GHCR and configuring environment
- `start-kai.sh` - Start the Kai system services directly with Docker run commands
- `stop-kai.sh` - Stop the Kai system services
- `update-kai.sh` - Update the Kai system by pulling latest images from GHCR

### Flexy Image Management Scripts

- `manage-flexy-image.sh` - Build, push, pull, and manage Flexy sandbox images

## Image Naming Mapping

The GitHub Container Registry (GHCR) images are named differently from the internal service names. Here's the mapping:

| Kai Project Service (Internal Name) | GitHub Container Registry Image Name (ghcr.io/username/) |
|------------------------------------|---------------------------------------------------------|
| `kai-backend`                      | `cotandem-backend`                                      |
| `kai-frontend`                     | `cotandem-frontend`                                     |
| `flexy-dev-sandbox`                | `flexy-dev-sandbox` (same name)                         |

**Container Names in Docker:**
- Backend service: `kai-backend`
- Frontend service: `kai-frontend` 
- Code Server service: `kai-code-server`

**GitHub User:** `misterlex223`

## Quick Start

1. **Set up the Kai system:**
   ```bash
   ./scripts/setup-kai.sh
   ```

2. **Start the system:**
   ```bash
   ./scripts/start-kai.sh
   ```

3. **Access the system:**
   - Frontend: http://localhost:9901
   - Backend: http://localhost:9900
   - Code Server: http://localhost:8443

## Detailed Usage

### Setting up the Kai System

The setup script will:
- Install necessary dependencies
- Clone the Kai repository
- Create the base directory for projects
- Pull images from GitHub Container Registry
- Create the required Docker network
- Set up environment configuration

```bash
# Set up with default settings
./scripts/setup-kai.sh

# Set up with custom GitHub user
./scripts/setup-kai.sh --user mygithubuser
```

### Starting and Stopping the System

Start the system:
```bash
# Start with default settings
./scripts/start-kai.sh

# Start with custom base directory
./scripts/start-kai.sh --base-dir /data/kai-base
```

Stop the system:
```bash
# Stop with default settings
./scripts/stop-kai.sh
```

### Updating the System

Update to the latest version:
```bash
# Update with default settings (stops and restarts services)
./scripts/update-kai.sh

# Update with custom GitHub user
./scripts/update-kai.sh --user mygithubuser

# Update without stopping services during update
./scripts/update-kai.sh --no-stop

# Update images only, don't manage services
./scripts/update-kai.sh --no-stop --no-start
```

### Managing Flexy Sandbox Images

Build the Flexy image:
```bash
# Build with default settings
./scripts/manage-flexy-image.sh build

# Build without cache
./scripts/manage-flexy-image.sh build --no-cache
```

Push the image to a registry:
```bash
# Push to Docker Hub
./scripts/manage-flexy-image.sh push -u yourusername

# Push to GitHub Container Registry
./scripts/manage-flexy-image.sh push -u yourusername -r ghcr.io
```

Pull the image from a registry:
```bash
# Pull from Docker Hub
./scripts/manage-flexy-image.sh pull -u yourusername

# Pull from GitHub Container Registry
./scripts/manage-flexy-image.sh pull -u yourusername -r ghcr.io
```

List available image tags:
```bash
# List tags on Docker Hub
./scripts/manage-flexy-image.sh list-tags -u yourusername

# List tags on GitHub Container Registry
./scripts/manage-flexy-image.sh list-tags -u yourusername -r ghcr.io
```

Clean up old images:
```bash
./scripts/manage-flexy-image.sh clean
```

## Troubleshooting

### Common Issues

1. **Permission errors with Docker:**
   Make sure your user is in the `docker` group or run commands with `sudo` if needed.

2. **Port conflicts:**
   The system uses ports 9900 (backend), 9901 (frontend), and 8443 (code-server). Make sure these ports are available.

3. **Docker daemon not running:**
   Start Docker Desktop or the Docker service before running the scripts.

4. **GHCR authentication:**
   Make sure you are logged into GitHub Container Registry: `docker login ghcr.io`

5. **Missing images:**
   Run the setup script to ensure all required images are pulled from GHCR.

### Useful Commands

Check system status:
```bash
docker ps --filter name=kai-
```

View system logs:
```bash
docker logs kai-backend -f
docker logs kai-frontend -f
docker logs kai-code-server -f
```

Check if required network exists:
```bash
docker network ls | grep kai-net
```

Check if required images exist:
```bash
docker images | grep -E "(cotandem|flexy-dev-sandbox)"
```

## Best Practices

1. **Regular Updates:** Run `./scripts/update-kai.sh` periodically to keep your system current.

2. **Image Management:** Regularly clean up old Flexy images to free up disk space: `./scripts/manage-flexy-image.sh clean`

3. **Monitoring:** Check logs regularly to ensure system health:
   ```bash
   docker logs kai-backend --tail 100 -f
   docker logs kai-frontend --tail 100 -f
   docker logs kai-code-server --tail 100 -f
   ```

4. **Environment Configuration:** Review and customize the `.env.local` file in the backend directory to suit your deployment needs.

5. **Backup Strategy:** Consider implementing a backup strategy for your project data stored in the base directory.

## Contributing

If you have suggestions for improving these community scripts, feel free to contribute by:

1. Forking the repository
2. Making your changes
3. Submitting a pull request

## License

These community scripts are provided under the same license as the main Kai project. Please check the main repository for specific licensing information.