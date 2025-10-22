# Custom code-server image with Docker CLI support
FROM codercom/code-server:latest

USER root

# Install Docker CLI, sudo, and gosu
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh && \
    apt-get update && \
    apt-get install -y sudo gosu && \
    rm -rf /var/lib/apt/lists/*

# Allow coder user to use sudo without password for docker group management
RUN echo "coder ALL=(root) NOPASSWD: /usr/sbin/groupmod, /usr/sbin/usermod" >> /etc/sudoers

# Create entrypoint script to fix docker socket permissions
RUN printf '#!/bin/bash\n\
set -e\n\
\n\
# Get the GID of the docker socket if it exists\n\
if [ -S /var/run/docker.sock ]; then\n\
  DOCKER_SOCK_GID=$(stat -c "%%g" /var/run/docker.sock)\n\
  # Update docker group GID to match socket GID\n\
  groupmod -g "$DOCKER_SOCK_GID" docker 2>/dev/null || true\n\
  # Add coder user to docker group\n\
  usermod -aG docker coder 2>/dev/null || true\n\
fi\n\
\n\
# Switch to coder user and execute the original entrypoint\n\
exec gosu coder /usr/bin/entrypoint.sh "$@"\n' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Set working directory
WORKDIR /home/coder
