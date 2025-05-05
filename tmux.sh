#!/bin/bash

#!/bin/bash

# Hentikan proses qemu dan kontainer Docker terkait
pkill qemu-system-x86
docker stop bit
docker stop windows
docker stop vnc

# Bersihkan sistem Docker
docker system prune -f
docker image prune -a -f

# Hapus folder yang tidak diperlukan
rm -rf /home/.android/
rm -rf /home/user/flutter/
rm -rf /home/user/.gradle/
rm -rf /home/user/.android/
rm -rf /home/user/.androidsdkroot/

# Cek dan buat folder serta unduh dari Mega jika folder belum ada
if [ ! -d "/home/user/myapp/windows" ]; then
  rm -rf /home/user/myapp/windows
  mkdir -p /home/user/myapp/windows/data
  mega-login tebingcinah@gmail.com 2603@Udan
  mega-get / /home/user/myapp/windows/data
  mv "/home/user/myapp/windows/data/Cloud Drive/"* /home/user/myapp/windows/data/
  rmdir "/home/user/myapp/windows/data/Cloud Drive"
  wget -O /home/user/myapp/windows/compose.yaml https://github.com/dediminari/bit/raw/refs/heads/main/compose.yaml
  docker compose -f /home/user/myapp/windows/compose.yaml up -d
fi

# Mulai ulang kontainer
docker start windows

# Jalankan sesi tmux
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

