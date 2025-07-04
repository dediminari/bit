#!/bin/bash

# Delay 2 detik
sleep 2

# Paksa kill Firefox pelan & pastikan lock file hilang
pkill firefox
sleep 2

while pgrep firefox > /dev/null; do
  echo "Menunggu Firefox mati..."
  sleep 1
done

# Hapus session restore (semua profil default)
for FF_PROFILE in $(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default*" ); do
  echo "Membersihkan $FF_PROFILE"
  rm -f "$FF_PROFILE"/sessionstore.jsonlz4
  rm -f "$FF_PROFILE"/recovery.jsonlz4
  rm -f "$FF_PROFILE"/recovery.bak
done

echo "Session restore file dihapus."

# Buka URL pertama di instance terisolasi
firefox --new-instance --new-window "https://idx.google.com/u/0/flow-apps-25016571" &

# Tunggu jendela benar-benar ready
sleep 5

# Buka sisanya di window baru di instance yang sama
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
