#
# Dockerfile
# see run.sh
#
FROM ubuntu:focal
RUN apt-get update && apt-get -y install tar wget xz-utils inetutils-ping && \
    cd /opt && wget https://github.com/doktor83/SRBMiner-Multi/releases/download/2.6.6/SRBMiner-Multi-2-6-6-Linux.tar.gz && \
	tar xf SRBMiner-Multi-2-6-6-Linux.tar.gz && rm -rf /opt/SRBMiner-Multi-2-6-6-Linux.tar.gz && \
	apt-get -y purge xz-utils && apt-get -y autoremove --purge && apt-get -y clean && apt-get -y autoclean; rm -rf /var/lib/apt-get/lists/*
COPY entrypoint /opt/SRBMiner-Multi-2-6-6/
RUN chmod +x /opt/SRBMiner-Multi-2-6-6/entrypoint
# it needs a workdir spec in order to see the 'verus-solver' binary right next to it
WORKDIR "/opt/SRBMiner-Multi-2-6-6"
ENTRYPOINT "./entrypoint"
# EOF
