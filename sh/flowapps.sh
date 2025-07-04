#!/bin/bash

# 1️⃣ Delay 2 detik
sleep 2

# 2️⃣ Tutup Firefox (kalau sedang berjalan)
pkill firefox
sleep 2  # Tunggu proses benar-benar mati

# 3️⃣ Hapus session restore (file recovery)
FF_PROFILE=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default*" | head -n 1)

if [ -d "$FF_PROFILE" ]; then
  rm -f "$FF_PROFILE"/sessionstore.jsonlz4
  rm -f "$FF_PROFILE"/recovery.jsonlz4
  rm -f "$FF_PROFILE"/recovery.bak
  echo "Session restore file dihapus."
else
  echo "Profil Firefox tidak ditemukan."
fi

# 4️⃣ Buka URL pertama di jendela baru
firefox --new-window "https://idx.google.com/u/0/flow-apps-25016571" &

# 5️⃣ Tunggu sebentar supaya jendela pertama kebuka dulu
sleep 2

# 6️⃣ Buka URL lain di jendela berbeda
firefox --new-window \
  "https://idx.google.com/u/1/yabbyleans-15963263" \
  "https://idx.google.com/u/1/volehops-04394543" \
  "https://idx.google.com/u/1/quollglides-14773299" \
  "https://idx.google.com/u/1/indianpythonshakes-89109680" \
  "https://idx.google.com/u/1/zorseanswers-57066419" \
  "https://idx.google.com/u/1/viperfishbreaks-95068107" \
  "https://idx.google.com/u/1/mandrillcools-67078439" \
  "https://idx.google.com/u/1/camelhits-71563397" \
  "https://idx.google.com/u/1/foxsorts-09844137" \
  "https://idx.google.com/u/1/hawkthrows-20986441" &
