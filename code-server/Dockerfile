# Custom code-server image with Docker CLI support
FROM codercom/code-server:latest

USER root

# Install Docker CLI
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh

# Add coder user to docker group for socket access
RUN usermod -aG docker coder

# Switch back to coder user
USER coder

# Set working directory
WORKDIR /home/coder
