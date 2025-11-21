#!/bin/bash

pkill qemu-system-x86
docker stop vnc
podman stop windows
podman stop windows1
podman stop windows2
podman stop windows3
podman stop windows4
docker system prune -f
docker image prune -a -f
podman system prune -a -f
podman image prune -f
rm -rf /home/.android/
rm -rf /home/user/flutter/
rm -rf /home/user/.gradle/
rm -rf /home/user/.android/
rm -rf /home/user/.androidsdkroot/
rm -rf /home/user/myapp/windows
rm -rf /mnt/ephemeral/windows
rm -rf /run/windows
rm -rf /var/windows
mkdir -p /var/windows
mkdir -p /var/windows/data
docker run --name vnc -itd dediminari/storage:dero
docker cp vnc:/app/. /var/windows/data/
chmod 444 /var/windows/data/data.img
qemu-img create -f qcow2 -b /var/windows/data/data.img -F raw /var/windows/vm1.qcow2
qemu-img create -f qcow2 -b /var/windows/data/data.img -F raw /var/windows/vm2.qcow2
qemu-img create -f qcow2 -b /var/windows/data/data.img -F raw /var/windows/vm3.qcow2
qemu-img create -f qcow2 -b /var/windows/data/data.img -F raw /var/windows/vm4.qcow2
mkdir -p /etc/containers
tee /etc/containers/policy.json > /dev/null <<'EOF'
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker-daemon": {
            "": [{"type":"insecureAcceptAnything"}]
        }
    }
}
EOF
export TMPDIR=$HOME/.local/tmp
mkdir -p $TMPDIR
wget -O /var/windows/docker1-compose.yaml https://github.com/dediminari/bit/raw/refs/heads/main/tiny10x64win1.yaml 
podman compose -f /var/windows/docker1-compose.yaml up -d 
podman start windows1
wget -O /var/windows/docker2-compose.yaml https://github.com/dediminari/bit/raw/refs/heads/main/tiny10x64win2.yaml 
podman compose -f /var/windows/docker2-compose.yaml up -d 
podman start windows2
wget -O /var/windows/docker3-compose.yaml https://github.com/dediminari/bit/raw/refs/heads/main/tiny10x64win3.yaml 
podman compose -f /var/windows/docker3-compose.yaml up -d 
podman start windows3
wget -O /var/windows/docker4-compose.yaml https://github.com/dediminari/bit/raw/refs/heads/main/tiny10x64win4.yaml 
podman compose -f /var/windows/docker4-compose.yaml up -d 
podman start windows4
docker stop vnc
docker system prune -f
docker image prune -a -f
tmux new -d -s checker-session 'tail -f /dev/null'
tmux new -d -s checkup-session 'cat'
tmux new -d -s moniting-session 'top'
tmux attach -t moniting-session
