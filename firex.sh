#!/bin/bash

# Fungsi untuk menghentikan dan memulai ulang container
restart_container() {
    echo "Memulai container kembali..."
    docker restart -t 60 vnc
    docker exec -it vnc bash -c "Xvfb :99 -screen 0 1024x768x16 & openbox & lxpanel --profile LXDE & pcmanfm & x11vnc -display :99 -forever -shared & novnc --vnc localhost:5900 &"
    docker exec -it vnc bash -c "Xvfb :99 -screen 0 1024x768x16 & openbox & lxpanel --profile LXDE & pcmanfm & x11vnc -display :99 -forever -shared & novnc --vnc localhost:5900 &"
    docker exec -it vnc bash -c "Xvfb :99 -screen 0 1024x768x16 & openbox & lxpanel --profile LXDE & pcmanfm & x11vnc -display :99 -forever -shared & novnc --vnc localhost:5900 &"
    sleep 20  # Waktu tunggu agar container bisa stabil
}

# Fungsi untuk mengecek status kesehatan container
check_health_status() {
    echo "Memeriksa status kesehatan container..."
    health_status=$(docker inspect -f '{{.State.Health.Status}}' vnc 2>/dev/null)

    case "$health_status" in
        "healthy")
            echo "Container dalam status sehat."
            return 0
            ;;
        "unhealthy")
            echo "Container dalam status tidak sehat!"
            return 1
            ;;
        "starting")
            echo "Container sedang dalam status 'starting', menunggu hingga status berubah..."
            return 2
            ;;
        *)
            echo "Container tidak memiliki status kesehatan atau belum siap."
            return 3
            ;;
    esac
}

# Fungsi untuk mengecek status layanan internal berdasarkan port
check_service_status() {
    local port=$1

    echo "Memeriksa status layanan pada port $port..."

    if docker exec vnc bash -c "netstat -tuln | grep :$port" > /dev/null 2>&1; then
        echo "Port $port dalam container aktif."
        return 0
    else
        echo "Port $port dalam container tidak aktif."
        return 1
    fi
}

# Fungsi untuk mengecek keseluruhan status container
check_container_status() {
    max_attempts=10
    attempt=0

    while (( attempt < max_attempts )); do
        echo "Memeriksa status container dan layanan internal (percobaan ke-$((attempt + 1)))..."

        # Periksa apakah container berjalan
        if docker inspect -f '{{.State.Running}}' vnc | grep -q "true"; then
            echo "Container vnc berjalan. Memeriksa layanan internal dan kesehatan..."

            # Cek status kesehatan container
            check_health_status
            health_code=$?
            if [[ $health_code -eq 0 ]]; then
                # Cek layanan NoVNC pada port 80 di dalam container
                if check_service_status 80; then
                    echo "Semua layanan internal berjalan dengan baik."
                    return 0
                fi
            elif [[ $health_code -eq 2 ]]; then
                echo "Container masih 'starting'. Menunggu status berubah..."
            fi
        else
            echo "Container tidak berjalan."
        fi

        echo "Percobaan ke-$((attempt + 1)): Container atau layanan internal belum siap."
        (( attempt++ ))
        sleep 10
    done

    echo "Container tidak siap setelah $max_attempts percobaan."
    return 1
}

# Main loop untuk memastikan container berjalan
while true; do
    echo "Memulai proses pengecekan container..."
    restart_container  # Mulai dengan menghentikan dan memulai ulang container

    if check_container_status; then
        echo "Container siap. Melanjutkan ke langkah berikutnya..."
        break  # Keluar dari loop jika container berhasil siap
    else
        echo "Container tidak siap atau dalam keadaan unhealthy. Mengulang proses restart..."
    fi
done

# Skrip berikutnya setelah container siap
echo "Container berjalan dengan baik. Lanjutkan tugas lainnya."
			docker exec -itd vnc bash -c "echo 'user_pref(\"browser.sessionstore.resume_session_once\", false);' >> /root/.mozilla/firefox/diadw2ks.default-release/prefs.js && \
			echo 'user_pref(\"browser.sessionstore.restore_on_demand\", false);' >> /root/.mozilla/firefox/diadw2ks.default-release/prefs.js && \
			echo 'user_pref(\"browser.startup.page\", 3);' >> /root/.mozilla/firefox/diadw2ks.default-release/prefs.js"
			sleep 10
   			docker exec -itd vnc bash -c "pkill firefox"
			sleep 15
			docker exec -itd vnc bash -c "DISPLAY=:1 firefox --restore --no-remote --profile /root/.mozilla/firefox/diadw2ks.default-release"
    sleep 5m
   			docker exec -itd vnc bash -c "pkill firefox"
			sleep 15
			docker exec -itd vnc bash -c "DISPLAY=:1 firefox --restore --no-remote --profile /root/.mozilla/firefox/diadw2ks.default-release"
    sleep 90m
   			docker exec -itd vnc bash -c "pkill firefox"
			sleep 15
			docker exec -itd vnc bash -c "DISPLAY=:1 firefox --restore --no-remote --profile /root/.mozilla/firefox/diadw2ks.default-release"
