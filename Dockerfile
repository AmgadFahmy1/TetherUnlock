# Dockerfile for building TetherUnlock .deb package
# Works on any OS with Docker installed

FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    fakeroot \
    git \
    perl \
    python3 \
    curl \
    wget \
    unzip \
    libssl-dev \
    libxml2-dev \
    libz-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Theos
ENV THEOS=/opt/theos
RUN git clone --recursive https://github.com/theos/theos.git $THEOS

# Download iOS SDK
RUN mkdir -p $THEOS/sdks && \
    cd /tmp && \
    wget -q https://github.com/theos/sdks/archive/master.tar.gz && \
    tar -xzf master.tar.gz && \
    cp -r sdks-master/iPhoneOS15.5.sdk $THEOS/sdks/ && \
    rm -rf sdks-master master.tar.gz

# Set environment
ENV PATH="$THEOS/bin:$PATH"
ENV PATH="/usr/bin:$PATH"

# Set working directory
WORKDIR /build

# Copy project
COPY . /build

# Make build script executable
RUN chmod +x /build/build_deb.sh

# Default command
CMD ["/bin/bash", "build_deb.sh"]
