#!/bin/bash
			docker restart --time=60 vnc
			sleep 60
			docker exec -itd vnc bash -c "echo 'user_pref(\"browser.sessionstore.resume_session_once\", false);' >> /root/.mozilla/firefox/diadw2ks.default-release/prefs.js && \
			echo 'user_pref(\"browser.sessionstore.restore_on_demand\", false);' >> /root/.mozilla/firefox/diadw2ks.default-release/prefs.js && \
			echo 'user_pref(\"browser.startup.page\", 3);' >> /root/.mozilla/firefox/diadw2ks.default-release/prefs.js"
			sleep 70
			docker exec -itd vnc bash -c "pkill firefox; DISPLAY=:1 firefox --restore --no-remote --profile /root/.mozilla/firefox/diadw2ks.default-release"
    sleep 5m
			docker restart --time=60 vnc
			sleep 60
			docker exec -itd vnc bash -c "pkill firefox; DISPLAY=:1 firefox --restore --no-remote --profile /root/.mozilla/firefox/diadw2ks.default-release"
    sleep 90m
			docker restart --time=60 vnc
			sleep 60
			docker exec -itd vnc bash -c "pkill firefox; DISPLAY=:1 firefox --restore --no-remote --profile /root/.mozilla/firefox/diadw2ks.default-release"
