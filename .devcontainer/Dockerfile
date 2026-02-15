FROM ubuntu:24.04

# Install essential packages including sudo
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    curl \
    git \
    openssh-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create shuk user with home directory and bash shell
RUN useradd -m -s /bin/bash shuk \
    && echo "shuk ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers



# Copy workspace into shuk's home
RUN mkdir -p /home/shuk/projects && chown -R shuk:shuk /home/shuk/projects


# Set default user
USER shuk
WORKDIR /home/shuk
