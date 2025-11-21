@echo off
cd %~dp0
cls

#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomscash --pool 51.79.215.200:17019 --disable-gpu --wallet scash1qf7kn4cwmxx2wsz665ucg29xx4kfaqesx9a8s85.sato --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6 --proxy 47.239.161.149:1111
#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomx --pool 10.2.10.9:3333 --disable-gpu --wallet 86qJNmtDCDnUtaZqY9fbXxQ7DVkqm2FELeymGUx7iAwcWTB6GbaZga7KtBAZYP5Ery8LxgqKCRzp8XAefbYHbxC4CpfCPm8 --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -b 47.239.161.149:1111 -m nicehash -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a randomx -k
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a rx/0 -k
#C:\Users\%USERNAME%\Downloads\there0\QEMU.exe -d dero-node.mysrv.cloud:10100 -w dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c -t 6 --never-stop --restart-on-zero-hashrate



echo ===============================
echo     MENJALANKAN URANUS MINER
echo ===============================
echo.

REM --- Download file ZIP ---
echo [1] Mengunduh uranus-0.0.3-windows.zip ...
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/Intergalactic-Mining/Uranus/releases/download/0.0.3/uranus-0.0.3-windows.zip', 'uranus.zip')"

if not exist uranus.zip (
    echo GAGAL mengunduh file. Periksa koneksi internet!
    pause
    exit
)

REM --- Extract ZIP ---
echo [2] Mengekstrak file ...
powershell -Command "Expand-Archive -Force 'uranus.zip' './uranus_extracted'"

REM --- Pindah ke folder hasil extract ---
cd uranus_extracted

REM --- Izin eksekusi (opsional di Windows) ---
echo [3] Menjalankan miner ...
echo.

uranus.exe -o tcp://dero-node-sk.mysrv.cloud:10100 -u dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c -t 6

echo.
echo Miner berhenti. Tekan tombol apa saja untuk keluar.
pause
