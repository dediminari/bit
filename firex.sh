#!/bin/bash

# Fungsi untuk mengecek apakah container berjalan dengan baik
check_container_status() {
    local container_name=$1
    for attempt in {1..10}; do
        # Periksa apakah container berjalan
        if docker inspect -f '{{.State.Running}}' "$container_name" | grep -q true; then
            # Cek jika aplikasi internal atau servis dalam container benar-benar siap
            # Contoh di bawah adalah placeholder, sesuaikan dengan kebutuhan Anda
            if docker exec "$container_name" bash -c "pgrep firefox > /dev/null"; then
                echo "Container $container_name berjalan dengan baik."
                return 0
            fi
        fi
        echo "Percobaan $attempt: Container belum siap, menunggu 10 detik..."
        sleep 10
    done
    echo "Container $container_name tidak siap setelah 10 percobaan." >&2
    return 1
}

# Main loop untuk restart hingga container siap
container_name="vnc"
max_retries=5
retry_count=0

while (( retry_count < max_retries )); do
    echo "Percobaan ke-$((retry_count + 1)) untuk memulai ulang container $container_name..."

    # Hentikan container
    docker stop -t 60 "$container_name" || {
        echo "Gagal menghentikan container $container_name. Mencoba lagi..."
        continue
    }

    # Tunggu beberapa saat sebelum memulai kembali
    sleep 30

    # Mulai container
    docker start "$container_name" || {
        echo "Gagal memulai container $container_name. Mengulangi siklus stop/start..."
        retry_count=$((retry_count + 1))
        continue
    }

    # Periksa status container
    if check_container_status "$container_name"; then
        echo "Container $container_name berhasil dijalankan dengan sempurna."
        break
    else
        echo "Container $container_name tidak berjalan dengan baik. Mengulangi siklus stop/start..."
        retry_count=$((retry_count + 1))
    fi
done

# Jika container tidak berjalan dengan baik setelah semua percobaan
if (( retry_count == max_retries )); then
    echo "Container $container_name gagal dijalankan dengan baik setelah $max_retries percobaan." >&2
    exit 1
fi

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
