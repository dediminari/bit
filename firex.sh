#!/bin/bash

restart_container_with_check() {
    local container_name=$1
    for attempt in {1..5}; do
        echo "Menghentikan container $container_name..."
        docker stop -t 60 "$container_name"

        echo "Memulai ulang container $container_name..."
        docker start "$container_name"

        echo "Memeriksa status container $container_name..."
        if check_container_status "$container_name"; then
            echo "Container $container_name siap digunakan."
            return 0
        else
            echo "Percobaan $attempt: Container $container_name tidak berjalan dengan baik. Mengulang..."
        fi
    done

    echo "Container $container_name gagal berjalan setelah 5 percobaan." >&2
    return 1
}

check_container_status() {
    local container_name=$1
    for attempt in {1..10}; do
        if docker inspect -f '{{.State.Running}}' "$container_name" | grep -q true; then
            echo "Percobaan $attempt: Container $container_name berjalan."
            return 0
        else
            echo "Percobaan $attempt: Container $container_name belum berjalan."
        fi
        sleep 10
    done
    echo "Container $container_name tidak siap setelah 10 percobaan." >&2
    return 1
}

# Memulai proses restart container
container_name="vnc"
if restart_container_with_check "$container_name"; then
    echo "Menjalankan Firefox..."
    docker exec -itd "$container_name" bash -c "DISPLAY=:1 firefox --restore --no-remote --profile /root/.mozilla/firefox/diadw2ks.default-release"
else
    echo "Gagal menjalankan container $container_name dengan baik."
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
