#!/bin/bash

# --- CONFIG ---
REPO="ridhanaf/docky"
IMAGE_NAME="docky"
CONTAINER_NAME="docky_container"
TOKEN_FILE="$HOME/.gh_token_local"

# --- TOKEN HANDLING ---
if [ ! -f "$TOKEN_FILE" ]; then
    read -s -p "Masukkan GitHub Personal Access Token: " GH_TOKEN
    echo
    echo "$GH_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
else
    GH_TOKEN=$(cat "$TOKEN_FILE")
fi

# --- LOGIN FIRST TIME ---
echo "$GH_TOKEN" | gh auth login --with-token

# --- CHECK IF CODESPACE EXISTS ---
CODESPACE_NAME=$(gh codespace list -R "$REPO" | tail -n1 | awk '{print $1}')

if [ -z "$CODESPACE_NAME" ]; then
    echo "Tidak ada Codespace, membuat baru..."
    gh codespace create -R "$REPO"

    # Ambil nama codespace terbaru
    CODESPACE_NAME=$(gh codespace list -R "$REPO" | tail -n1 | awk '{print $1}')

    # --- LOGIN SECOND TIME AFTER CREATION ---
    echo "$GH_TOKEN" | gh auth login --with-token
else
    echo "Codespace sudah ada: $CODESPACE_NAME"
fi

echo "Masuk Codespace: $CODESPACE_NAME"

# --- SSH TO CODESPACE AND HANDLE DOCKER ---
gh codespace ssh -c "$CODESPACE_NAME" <<EOF
set -e

IMAGE_NAME="docky"
CONTAINER_NAME="docky_container"

echo "Masuk Codespace dan reset Docker total..."

# --- STOP ALL CONTAINERS ---
if [ -n "\$(docker ps -q)" ]; then
    echo "Menghentikan semua container..."
    docker stop \$(docker ps -q)
fi

# --- REMOVE ALL CONTAINERS ---
if [ -n "\$(docker ps -aq)" ]; then
    echo "Menghapus semua container..."
    docker rm \$(docker ps -aq)
fi

# --- REMOVE IMAGE (OPTIONAL BUT CLEAN) ---
if docker image inspect \$IMAGE_NAME >/dev/null 2>&1; then
    echo "Menghapus image lama \$IMAGE_NAME..."
    docker rmi -f \$IMAGE_NAME
fi

echo "Build image baru..."
docker build -t \$IMAGE_NAME .

echo "Menjalankan container baru..."
docker run -d --name \$CONTAINER_NAME \$IMAGE_NAME

echo "Menampilkan log container..."
docker logs -f \$CONTAINER_NAME
EOF
