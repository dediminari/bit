#!/bin/bash

# --- CONFIG ---
REPO="dediminari/docky"
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
echo "Masuk Codespace dan mulai Docker..."

# Build image jika belum ada
if ! docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
    echo "Image $IMAGE_NAME belum ada, membangun image..."
    docker build -t $IMAGE_NAME .
else
    echo "Image $IMAGE_NAME sudah ada"
fi

# Jalankan container jika belum berjalan
RUNNING_CONTAINER=\$(docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" -q)
if [ -z "\$RUNNING_CONTAINER" ]; then
    echo "Menjalankan container $CONTAINER_NAME..."
    docker run -t --name $CONTAINER_NAME $IMAGE_NAME
else
    echo "Container $CONTAINER_NAME sudah berjalan, menampilkan log..."
    docker logs -f $CONTAINER_NAME
fi
EOF
