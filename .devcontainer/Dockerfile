FROM ubuntu:24.04

# Avoid interactive prompts during apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Create a user 'shuk'
RUN useradd -m -s /bin/bash shuk

# Ensure the projects directory exists in the home folder
RUN mkdir -p /home/shuk/projects && chown shuk:shuk /home/shuk/projects

# Set the default user
USER shuk
WORKDIR /home/shuk/projects/env_setup

