https://docs.google.com/spreadsheets/d/14yGBX_eqEPxeOIwDHg0sltCl89koVO970wjXm34-Syg/edit?pli=1


docker run --name vnc -itd dediminari/storage:ytn6x && \
mkdir -p "$(pwd)/windows/data" && \
docker cp vnc:/app/. "$(pwd)/windows/data/" && \
wget -O "$(pwd)/windows/docker-compose.yaml" "https://github.com/dediminari/bit/raw/refs/heads/main/tiny10x64.yaml" && \
docker compose -f "$(pwd)/windows/docker-compose.yaml" up -d && \
docker start windows
