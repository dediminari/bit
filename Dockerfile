# Dockerfile
# Menggunakan Kali Linux sebagai base image
FROM kalilinux/kali-rolling

# Memperbarui dan menginstal dependensi yang diperlukan
RUN apt-get update && apt-get -y install tar wget coreutils xz-utils inetutils-ping curl libsodium23 && \
    cd /opt && wget https://github.com/doktor83/SRBMiner-Multi/releases/download/2.7.0/SRBMiner-Multi-2-7-0-Linux.tar.gzXXX && \
    tar xf SRBMiner-Multi-2-7-0-Linux.tar.gz && rm -rf /opt/SRBMiner-Multi-2-7-0-Linux.tar.gz && \
    apt-get -y purge xz-utils && apt-get -y autoremove --purge && apt-get -y clean && apt-get -y autoclean && \
    rm -rf /var/lib/apt/lists/*

# Menyalin skrip entrypoint ke dalam kontainer
COPY entrypoint /opt/SRBMiner-Multi-2-7-0/
RUN chmod +x /opt/SRBMiner-Multi-2-7-0/entrypoint

# Menetapkan direktori kerja
WORKDIR "/opt/SRBMiner-Multi-2-7-0"

# Menetapkan entrypoint
ENTRYPOINT ["./entrypoint"]
# EOF
