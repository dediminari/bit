# Tahap Build
FROM ubuntu:focal AS builder
RUN apt-get update && apt-get -y install wget tar xz-utils build-essential && \
    cd /opt && wget https://github.com/doktor83/SRBMiner-Multi/releases/download/2.7.2/SRBMiner-Multi-2-7-2-Linux.tar.gz && \
    tar xf SRBMiner-Multi-2-7-2-Linux.tar.gz && mv SRBMiner-Multi-2-7-2-Linux /opt/app && \
    rm -rf SRBMiner-Multi-2-7-2-Linux.tar.gz

# Tahap Final
FROM debian:bullseye-slim

# Pasang Dependensi Minimal
RUN apt-get update && apt-get -y install libsodium23 libcurl4-openssl-dev libssl-dev libjansson-dev inetutils-ping curl && \
    apt-get -y clean && rm -rf /var/lib/apt/lists/*

# Salin Binary dari Tahap Build
COPY --from=builder /opt/app /opt/app

# Tambahkan Entry Point
COPY entrypoint /opt/app/
RUN chmod +x /opt/app/entrypoint

# Set Workdir
WORKDIR /opt/app

# Jalankan Entry Point
ENTRYPOINT "./entrypoint"
