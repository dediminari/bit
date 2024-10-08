FROM ubuntu:focal

RUN apt-get update && apt-get -y install tar wget xz-utils inetutils-ping && \
    cd /opt && wget https://github.com/doktor83/SRBMiner-Multi/releases/download/2.6.7/SRBMiner-Multi-2-6-7-Linux.tar.gz && \
    tar xf SRBMiner-Multi-2-6-7-Linux.tar.gz && rm -rf /opt/SRBMiner-Multi-2-6-7-Linux.tar.gz && \
    apt-get -y purge xz-utils && apt-get -y autoremove --purge && apt-get -y clean && apt-get -y autoclean; rm -rf /var/lib/apt-get/lists/*

COPY entrypoint /opt/SRBMiner-Multi-2-6-7/
RUN chmod +x /opt/SRBMiner-Multi-2-6-7/entrypoint

WORKDIR "/opt/SRBMiner-Multi-2-6-7"

# Menjalankan entrypoint di latar belakang
ENTRYPOINT ["sh", "-c", "./entrypoint & tail -f /dev/null"]
