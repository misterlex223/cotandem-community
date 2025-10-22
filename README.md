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

There are two ways to get started with the Kai system:

### Option 1: Full Repository Clone (Recommended)
This approach gives you access to all scripts, documentation, and future updates:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/misterlex223/cotandem-community.git
   cd cotandem-community
   ```

2. **Set up the Kai system:**
   ```bash
   ./scripts/setup-kai.sh
   ```

3. **Start the system:**
   ```bash
   ./scripts/start-kai.sh
   ```

### Option 2: Minimal Bootstrap (Lightweight)
If you prefer a minimal setup without cloning the full repository:

1. **Download and run the bootstrap script:**
   ```bash
   curl -s -o bootstrap-kai.sh https://raw.githubusercontent.com/misterlex223/cotandem-community/main/bootstrap-kai.sh
   chmod +x bootstrap-kai.sh
   ./bootstrap-kai.sh
   ```

2. **Start the system:**
   ```bash
   cd $HOME/kai-scripts && ./start-kai.sh
   ```

Both approaches will set up the complete Kai system with all functionality. The bootstrap option downloads only the essential scripts, while the full repository clone includes documentation, examples, and all management scripts.

## Detailed Usage

### Setting up the Kai System

The setup script will:
- Install necessary dependencies
- Create the base directory for projects
- Pull images from GitHub Container Registry
- Create the required Docker network
- Set up environment configuration

#### Full Repository Approach:
```bash
# Set up with default settings
./scripts/setup-kai.sh

# Set up with custom GitHub user
./scripts/setup-kai.sh --user mygithubuser
```

#### Minimal Bootstrap Approach:
```bash
# The bootstrap script handles setup automatically
./bootstrap-kai.sh

# With custom directories
./bootstrap-kai.sh --base-dir /data/kai-base --dir /opt/kai-scripts
```

### Starting and Stopping the System

Start the system:
```bash
# Start with default settings
./scripts/start-kai.sh

# Start with custom base directory
./scripts/start-kai.sh --base-dir /data/kai-base
```

**Note:** The frontend uses runtime configuration via the `API_BASE_URL` environment variable. By default, it runs in **proxy mode** (empty value), where the frontend's Nginx proxies API requests to the backend. For most use cases, including reverse proxy setups, no configuration is needed. If you need to connect to a backend on a different host, set `API_BASE_URL` to the explicit backend URL:

```bash
# Proxy mode (default, recommended) - no configuration needed
docker run -d \
  --name kai-frontend \
  --network kai-net \
  -p 9901:80 \
  cotandem-frontend:latest

# Direct mode - for separate backend host
docker run -d \
  --name kai-frontend \
  --network kai-net \
  -p 9901:80 \
  -e API_BASE_URL=https://backend.yourdomain.com \
  cotandem-frontend:latest
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

## Runtime Configuration

The Kai frontend supports runtime configuration, allowing you to change the API URL without rebuilding the Docker image.

### How It Works

- The frontend uses `API_BASE_URL` environment variable for runtime configuration
- At container startup, `entrypoint.sh` generates `/usr/share/nginx/html/runtime-config.js` with the configured API URL
- The frontend reads `window.__KAI_CONFIG__.apiBaseUrl` from this file at runtime

### Two Operation Modes

**1. Proxy Mode (Default, Recommended)**
- Leave `API_BASE_URL` empty or unset
- Frontend uses relative paths (`/api/*`)
- Nginx in frontend container proxies requests to backend
- Works seamlessly with reverse proxies

```bash
# No configuration needed - this is the default
docker run -d \
  --name kai-frontend \
  --network kai-net \
  -p 9901:80 \
  cotandem-frontend:latest
```

**2. Direct Mode**
- Set `API_BASE_URL` to explicit backend URL
- Frontend makes absolute API calls directly to backend
- Use for testing or distributed deployments

```bash
docker run -d \
  --name kai-frontend \
  --network kai-net \
  -p 9901:80 \
  -e API_BASE_URL=https://api.yourdomain.com \
  cotandem-frontend:latest
```

### Use Cases

1. **Behind Reverse Proxy (Recommended):** Use proxy mode (no config needed)
2. **Separate Hosts:** Set `API_BASE_URL` to point to backend server
3. **Testing:** Set `API_BASE_URL` to test against different backends
4. **Custom Domain with SSL/TLS:** Use reverse proxy + proxy mode for best results

## Code-Server with Docker CLI

The Kai system includes a custom code-server image with Docker CLI support, allowing you to manage containers directly from the IDE terminal.

### Features

- **Docker CLI Access:** Run Docker commands from code-server terminal
- **Container Management:** View, inspect, and manage Flexy sandboxes
- **Persistence:** Settings and extensions persist across restarts
- **Efficient:** Shares host Docker daemon (no duplication)

### Setup

The setup script automatically handles code-server image acquisition:

```bash
./scripts/setup-kai.sh
```

The script will:
1. **Try to pull from GHCR first:** Attempts to pull the pre-built `kai-code-server:latest` image
2. **Fall back to local build:** If pull fails, builds the image locally from `code-server/Dockerfile`
3. **Use official image:** If Dockerfile not found, uses official `codercom/code-server:latest` (without Docker CLI)

This approach ensures fast setup when the image is available in GHCR, while maintaining the ability to build locally when needed.

### Using Docker from Code-Server

1. Access code-server at `http://localhost:8443`
2. Open the integrated terminal
3. Run Docker commands:

```bash
# List running containers
docker ps

# View backend logs
docker logs kai-backend -f

# Inspect a Flexy sandbox
docker inspect flexy-your-project

# Execute commands in backend container
docker exec -it kai-backend bash
```

### Persistence

Code-server settings and extensions are stored in:
- `$KAI_BASE_ROOT/.kai/code-server/config` - Configuration files
- `$KAI_BASE_ROOT/.kai/code-server/local` - Extensions and data

These directories are automatically created by the start script.

### Fallback Mode

If the custom image is not built, the start script will use the official `codercom/code-server:latest` image (without Docker CLI). You'll see a warning message:

```
Warning: Using official code-server image (Docker CLI not available)
To enable Docker CLI in code-server, run: ./scripts/setup-kai.sh
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

## Two Ways to Use Kai Scripts

This repository offers two approaches for managing your Kai system:

### Full Repository Clone (Default)
- Includes all scripts, documentation, and examples
- Easiest to update with `git pull`
- Best for active development and contribution
- Scripts located in `scripts/` directory

### Minimal Bootstrap (New in v2.0)
- Lightweight setup that downloads only essential scripts
- No git required - just download the bootstrap script
- Perfect for production environments or minimal setups
- Scripts located in a dedicated directory (default: `$HOME/kai-scripts`)

Both approaches provide the same core functionality. Choose the full repository clone if you want complete access to all tools and documentation, or the minimal bootstrap if you prefer a lightweight setup.

## Contributing

If you have suggestions for improving these community scripts, feel free to contribute by:

1. Forking the repository
2. Making your changes
3. Submitting a pull request

## License

These community scripts are provided under the same license as the main Kai project. Please check the main repository for specific licensing information.