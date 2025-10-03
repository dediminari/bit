[ -f rp.env ] || wget -O rp.env https://github.com/dediminari/bit/raw/refs/heads/main/rp.env
docker run --env-file rp.env -d --restart=always --name rpkt repocket/repocket
docker run -i --restart=always --name tm traffmonetizer/cli_v2 start accept --token hafcEX5LcrmMO+qTEf4JxmAq+HbfO5+RbEBj4K0Qd+Y=
