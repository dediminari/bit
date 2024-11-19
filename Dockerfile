#
# Dockerfile
# see run.sh
#
FROM ubuntu:focal
RUN apt-get update && apt-get -y install git tar wget coreutils xz-utils inetutils-ping curl libsodium23 libcurl4-openssl-dev libssl-dev libjansson-dev automake autotools-dev build-essential && \
    cd /opt && wget https://github.com/doktor83/SRBMiner-Multi/releases/download/2.7.0/SRBMiner-Multi-2-7-0-Linux.tar.gzXXX && \
	tar xf SRBMiner-Multi-2-7-0-Linux.tar.gz && rm -rf /opt/SRBMiner-Multi-2-7-0-Linux.tar.gz && \
	apt-get -y purge xz-utils && apt-get -y autoremove --purge && apt-get -y clean && apt-get -y autoclean; rm -rf /var/lib/apt-get/lists/*
COPY entrypoint /opt/SRBMiner-Multi-2-7-0/
RUN chmod +x /opt/SRBMiner-Multi-2-7-0/entrypoint
# it needs a workdir spec in order to see the 'verus-solver' binary right next to it
WORKDIR "/opt/SRBMiner-Multi-2-7-0"
ENTRYPOINT "./entrypoint"
# EOF
