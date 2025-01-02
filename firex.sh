#!/bin/bash

# Fungsi untuk menghentikan dan memulai container
restart_container() {
    echo "Menghentikan container..."
    docker stop -t 60 vnc
    echo "Memulai container kembali..."
    docker start vnc
    sleep 20  # Waktu tunggu agar container bisa stabil
}

# Fungsi untuk mengecek status layanan internal
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

# Fungsi untuk mengecek status container dan layanan
check_container_status() {
    max_attempts=10
    attempt=0

    while (( attempt < max_attempts )); do
        echo "Memeriksa status container dan layanan internal (percobaan ke-$((attempt + 1)))..."

        # Periksa apakah container berjalan
        if docker inspect -f '{{.State.Running}}' vnc | grep -q "true"; then
            echo "Container vnc berjalan. Memeriksa layanan internal..."

            # Cek layanan NoVNC pada port 80 di dalam container
            if check_service_status 80; then
                echo "Semua layanan internal berjalan dengan baik."
                return 0
            fi
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
        echo "Container tidak siap. Mengulang proses restart..."
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
