FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV GODOT_VERSION=4.4.1
ENV GODOT_RELEASE=stable

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    ca-certificates \
    libfontconfig1 \
    libgl1 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libxi6 \
    && rm -rf /var/lib/apt/lists/*

# Download and install Godot
RUN wget -q https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64.zip \
    && unzip Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64.zip -d /usr/local/bin/ \
    && mv /usr/local/bin/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64.zip

# Set working directory
WORKDIR /project

# Run as root for simplicity (volume permissions handled by host)

# Default command
CMD ["godot", "--headless", "--help"]
