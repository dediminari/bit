#!/bin/bash

pkill qemu-system-x86
rm ping.sh.*
rm trace.sh.*
docker stop bit
docker stop windows
docker stop vnc
docker system prune -f
docker image prune -a -f
rm -rf /home/.android/
rm -rf /home/user/myapp/windows
mkdir -p /home/user/myapp/windows
mkdir -p /home/user/myapp/windows/data
docker run --name vnc -itd dediminari/storage:flex8
docker cp vnc:/app/. /home/user/myapp/windows/data/
wget -O /home/user/myapp/windows/compose.yaml https://github.com/dediminari/bit/raw/refs/heads/main/compose.yaml
docker compose -f /home/user/myapp/windows/compose.yaml up -d
docker start windows
tmux new -d -s checker-session 'tail -f /dev/null'
tmux new -d -s checkup-session 'cat'
tmux new -d -s moniting-session 'top'
tmux attach -t moniting-session


#docker build . -t bit
#docker run -itd --name bit --restart=always --security-opt apparmor=unconfined --log-driver=none bit > /dev/null 2>&1
#tmux new -d -s checker-session 'tail -f /dev/null'
#tmux new -d -s checkup-session 'cat'
#tmux new -d -s moniting-session 'top'
#tmux attach -t moniting-session

