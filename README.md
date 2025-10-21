# Cotandem Community Scripts

This repository contains community scripts to help you set up, deploy, manage, and update the Kai system with Flexy sandbox containers.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Available Scripts](#available-scripts)
4. [Quick Start](#quick-start)
5. [Detailed Usage](#detailed-usage)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

## Overview

The Kai system is a sandbox orchestration platform that manages multiple Flexy development sandboxes. These scripts provide an easy way for the community to:

- Set up the Kai system from scratch
- Start and stop the system
- Update the system to the latest version
- Manage the Flexy sandbox Docker images

## Prerequisites

Before using these scripts, ensure you have:

1. **Git** installed
2. **Docker** with Docker Buildx (Docker Desktop recommended)
3. **Docker Compose** (v2.x or higher)
4. **Node.js** (LTS version recommended)
5. **pnpm** (package manager)

## Available Scripts

All scripts are located in the `scripts/` directory:

### System Scripts

- `setup-kai.sh` - Set up the entire Kai system from scratch
- `start-kai.sh` - Start the Kai system services
- `stop-kai.sh` - Stop the Kai system services
- `update-kai.sh` - Update the Kai system to the latest version

### Flexy Image Management Scripts

- `manage-flexy-image.sh` - Build, push, pull, and manage Flexy sandbox images

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
- Build the Flexy sandbox image
- Create the required Docker network
- Set up environment configuration

```bash
# Set up with default settings
./scripts/setup-kai.sh

# Set up in a custom directory
./scripts/setup-kai.sh --kai-dir /opt/kai --base-dir /data/kai-base
```

### Starting and Stopping the System

Start the system:
```bash
# Start with default settings
./scripts/start-kai.sh

# Start from a custom directory
./scripts/start-kai.sh --kai-dir /opt/kai
```

Stop the system:
```bash
# Stop with default settings
./scripts/stop-kai.sh

# Stop from a custom directory
./scripts/stop-kai.sh --kai-dir /opt/kai
```

### Updating the System

Update to the latest version:
```bash
# Update with default settings (stops and restarts services)
./scripts/update-kai.sh

# Update without stopping services during update
./scripts/update-kai.sh --no-stop

# Update code only, don't manage services
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

4. **Git permission errors:**
   Make sure you have proper access to the Kai repository if using a private fork.

### Useful Commands

Check system status:
```bash
cd $HOME/cotandem && docker-compose ps
```

View system logs:
```bash
cd $HOME/cotandem && docker-compose logs -f
```

View logs for a specific service:
```bash
cd $HOME/cotandem && docker-compose logs -f backend  # or frontend, code-server
```

## Best Practices

1. **Regular Updates:** Run `./scripts/update-kai.sh` periodically to keep your system current.

2. **Backups:** The update script automatically creates a backup before updating, but consider implementing your own backup strategy for important data.

3. **Custom Directories:** Consider using custom directories (`--kai-dir`, `--base-dir`) for better organization, especially in production environments.

4. **Image Management:** Regularly clean up old Flexy images to free up disk space: `./scripts/manage-flexy-image.sh clean`

5. **Monitoring:** Check logs regularly to ensure system health:
   ```bash
   cd $HOME/cotandem && docker-compose logs --tail=100 -f
   ```

6. **Environment Configuration:** Review and customize the `.env.local` file in the backend directory to suit your deployment needs.

## Contributing

If you have suggestions for improving these community scripts, feel free to contribute by:

1. Forking the repository
2. Making your changes
3. Submitting a pull request

## License

These community scripts are provided under the same license as the main Kai project. Please check the main repository for specific licensing information.