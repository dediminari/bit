# -*- coding: utf-8 -*-
"""AI Product Commercial Studio + Auto Video Editor
Fase 1: Product Studio (Agnes AI) — 4 gambar + 4 video, approval bertahap
Fase 2: Video Editor (Gemini caption + FFmpeg render) — alur lama
"""

import os, sys, subprocess, shutil, json, math, datetime, zipfile, tempfile
import urllib.request, hashlib, re, time, signal
from pathlib import Path
from urllib.parse import quote

# ============================================================
# SYSTEM PREPARATION
# ============================================================
subprocess.run(
    [sys.executable, "-m", "pip", "install", "-q", "-U",
     "gradio>=5,<7", "librosa", "soundfile", "requests",
     "beautifulsoup4", "google-genai"],
    check=False,
)

import gradio as gr

ROOT = Path("./AutoVideoEditor")
INPUT_DIR = ROOT / "input"
MUSIC_DIR = ROOT / "music"
OUTPUT_DIR = ROOT / "output"
TEMP_DIR = ROOT / "temp"
LOG_DIR = ROOT / "logs"
STUDIO_DIR = ROOT / "studio"          # baru: hasil Product Studio
FRAMES_DIR = STUDIO_DIR / "frames"
VIDEOS_DIR = STUDIO_DIR / "videos"
for d in (INPUT_DIR, MUSIC_DIR, OUTPUT_DIR, TEMP_DIR, LOG_DIR,
          STUDIO_DIR, FRAMES_DIR, VIDEOS_DIR):
    d.mkdir(parents=True, exist_ok=True)

GITHUB_MUSIC_URL = "https://github.com/dediminari/fypsoundtt"
GITHUB_BRANCH = "main"
AUDIO_EXTS = {".mp3", ".wav", ".m4a", ".aac", ".flac", ".ogg", ".opus"}
FFMPEG = shutil.which("ffmpeg") or "ffmpeg"
FFPROBE = shutil.which("ffprobe") or "ffprobe"

print("Root:", ROOT)
print("FFmpeg:", FFMPEG)

# ============================================================
# MUSIC LIBRARY SYNC (sama seperti kode lama)
# ============================================================
def sync_github_music():
    if not GITHUB_MUSIC_URL.strip():
        return 0, "GitHub music sync skipped."
    repo = GITHUB_MUSIC_URL.rstrip("/")
    if repo.endswith(".git"):
        repo = repo[:-4]
    zip_url = f"{repo}/archive/refs/heads/{GITHUB_BRANCH}.zip"
    copied = 0
    with tempfile.TemporaryDirectory(prefix="hh_music_") as td:
        zpath = Path(td) / "music.zip"
        try:
            urllib.request.urlretrieve(zip_url, zpath)
            with zipfile.ZipFile(zpath) as z:
                z.extractall(Path(td) / "src")
        except Exception as e:
            return 0, f"GitHub sync failed: {e}"
        src_root = Path(td) / "src"
        files = [p for p in src_root.rglob("*")
                 if p.is_file() and p.suffix.lower() in AUDIO_EXTS]
        for src in files:
            dst = MUSIC_DIR / src.name
            if dst.exists():
                continue
            shutil.copy2(src, dst)
            copied += 1
    return copied, f"GitHub music sync: {copied} new track(s)."


copied, sync_msg = sync_github_music()
print(sync_msg)

# ============================================================
# AGNES AI — IMAGE & VIDEO (Fase 1)
# ============================================================
AGNES_API_KEY = os.environ.get("AGNES_API_KEY", "").strip()
AGNES_BASE = "https://apihub.agnes-ai.com/v1"
AGNES_IMAGE_MODEL = "agnes-image-2.5-flash"      # gratis, image-to-image
AGNES_VIDEO_MODEL = "agnes-video-2.5-flash"      # gratis sementara, 720P, keyframe

_STUDIO_LOG = LOG_DIR / "studio.log"


def studio_log(msg):
    line = f"[{datetime.datetime.now().strftime('%H:%M:%S')}] {msg}"
    try:
        with open(_STUDIO_LOG, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass
    try:
        print(line, flush=True)
    except Exception:
        pass


def read_studio_log():
    p = _STUDIO_LOG
    if not p.exists():
        return ""
    try:
        c = p.read_text(encoding="utf-8", errors="replace")
        return c[-4000:] if len(c) > 4000 else c
    except Exception:
        return ""


def reset_studio_log():
    try:
        _STUDIO_LOG.write_text("", encoding="utf-8")
    except Exception:
        pass


# ---------- upload gambar sementara (untuk first_frame video) ----------
def upload_to_temp_host(image_path):
    """Upload gambar ke host sementara publik, return URL.
    Mengikuti pendekatan CLI Agnes: litterbox → tmpfiles → uguu → x0.at.
    """
    import requests
    p = Path(image_path)
    if not p.exists():
        raise RuntimeError(f"Image not found: {p}")

    # 1. Litterbox (catbox sementara)
    try:
        with open(p, "rb") as f:
            r = requests.post(
                "https://litterbox.catbox.moe/resources/internals/api.php",
                data={"reqtype": "fileupload", "time": "1h"},
                files={"fileToUpload": (p.name, f, "image/png")},
                timeout=60,
            )
        if r.ok and r.text.strip().startswith("https://"):
            return r.text.strip()
    except Exception as e:
        studio_log(f"Litterbox upload gagal: {e}")

    # 2. tmpfiles.org
    try:
        with open(p, "rb") as f:
            r = requests.post(
                "https://tmpfiles.org/api/v1/upload",
                files={"file": (p.name, f, "image/png")},
                timeout=60,
            )
        if r.ok:
            data = r.json()
            url = data.get("data", {}).get("url", "")
            if url:
                # tmpfiles memberikan halaman, ubah ke direct
                return url.replace("tmpfiles.org/", "tmpfiles.org/dl/")
    except Exception as e:
        studio_log(f"tmpfiles upload gagal: {e}")

    # 3. uguu.se
    try:
        with open(p, "rb") as f:
            r = requests.post(
                "https://uguu.se/upload.php",
                files={"files[]": (p.name, f, "image/png")},
                timeout=60,
            )
        if r.ok:
            data = r.json()
            files = data.get("files", [])
            if files and files[0].get("url"):
                return files[0]["url"]
    except Exception as e:
        studio_log(f"uguu upload gagal: {e}")

    # 4. x0.at
    try:
        with open(p, "rb") as f:
            r = requests.post(
                "https://x0.at",
                files={"file": (p.name, f, "image/png")},
                timeout=60,
            )
        if r.ok and r.text.strip().startswith("https://"):
            return r.text.strip()
    except Exception as e:
        studio_log(f"x0.at upload gagal: {e}")

    raise RuntimeError("Semua host sementara gagal. Coba lagi atau ganti jaringan.")


# ---------- Agnes Image ----------
def agnes_generate_image(prompt, reference_image_path=None, out_name="frame"):
    import requests
    if not AGNES_API_KEY:
        raise RuntimeError("AGNES_API_KEY belum diatur.")

    headers = {
        "Authorization": f"Bearer {AGNES_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": AGNES_IMAGE_MODEL,
        "prompt": prompt,
        "size": "1K",                          # 或 "768x1024"
        "extra_body": {
            "response_format": "url",
            "ratio": "9:16",                   # ✅ 移入 extra_body
        },
    }

    if reference_image_path:
        ref_url = upload_to_temp_host(reference_image_path)
        payload["extra_body"]["image"] = [ref_url]   # ✅ 放在 extra_body 内
        studio_log(f"Reference image uploaded: {ref_url[:60]}...")

    studio_log(f"Agnes image request → {AGNES_IMAGE_MODEL}")
    r = requests.post(f"{AGNES_BASE}/images/generations",
                      headers=headers, json=payload, timeout=180)
    if not r.ok:
        raise RuntimeError(f"Agnes image HTTP {r.status_code}: {r.text[:300]}")
    data = r.json()
    items = data.get("data", [])
    if not items:
        raise RuntimeError(f"Agnes image kosong: {data}")
    image_url = items[0].get("url")
    if not image_url:
        raise RuntimeError("Agnes image tidak mengembalikan URL.")

    out_path = FRAMES_DIR / f"{out_name}_{int(time.time())}.png"
    img_data = requests.get(image_url, timeout=120).content
    out_path.write_bytes(img_data)
    studio_log(f"Frame saved: {out_path.name} ({out_path.stat().st_size/1e6:.2f} MB)")
    return str(out_path)

# ---------- Agnes Video ----------
def agnes_generate_video(first_frame_path, prompt, out_name="video"):
    """Image-to-video via Agnes, async polling.
    Return: path file lokal.
    """
    import requests
    if not AGNES_API_KEY:
        raise RuntimeError("AGNES_API_KEY belum diatur.")

    frame_url = upload_to_temp_host(first_frame_path)
    studio_log(f"First frame uploaded: {frame_url[:60]}...")

    headers = {
        "Authorization": f"Bearer {AGNES_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": AGNES_VIDEO_MODEL,
        "prompt": prompt,
        "seconds": "6",
        "mode": "keyframe",
        "size": "720P",
        "aspect_ratio": "9:16",
        "first_frame": frame_url,
    }

    studio_log(f"Agnes video request → {AGNES_VIDEO_MODEL}")
    r = requests.post(f"{AGNES_BASE}/videos",
                      headers=headers, json=payload, timeout=60)
    if not r.ok:
        raise RuntimeError(f"Agnes video HTTP {r.status_code}: {r.text[:300]}")
    data = r.json()
    video_id = data.get("video_id") or data.get("id") or data.get("task_id")
    if not video_id:
        raise RuntimeError(f"Agnes video tidak mengembalikan video_id: {data}")

    studio_log(f"Video task created: {video_id}. Polling...")

    poll_url = (f"https://apihub.agnes-ai.com/agnesapi"
                f"?video_id={video_id}&model_name={AGNES_VIDEO_MODEL}")
    last_status = ""
    for attempt in range(180):  # max 15 menit
        time.sleep(5)
        try:
            s = requests.get(poll_url, headers=headers, timeout=30).json()
        except Exception as e:
            studio_log(f"Poll error: {e}")
            continue

        status = str(s.get("status", "")).lower()
        if status != last_status:
            studio_log(f"Video status: {status} (progress {s.get('progress', '?')}%)")
            last_status = status

        if status == "completed":
            video_url = s.get("url")
            if not video_url:
                raise RuntimeError("Status completed tapi url kosong.")
            out_path = VIDEOS_DIR / f"{out_name}_{int(time.time())}.mp4"
            vid_data = requests.get(video_url, timeout=180).content
            out_path.write_bytes(vid_data)
            studio_log(f"Video saved: {out_path.name} ({out_path.stat().st_size/1e6:.2f} MB)")
            return str(out_path)

        if status == "failed":
            raise RuntimeError(f"Agnes video failed: {s.get('error') or s}")

    raise RuntimeError("Agnes video timeout setelah 15 menit.")

# ============================================================
# PRODUCT ANALYSIS + PROMPT BUILDER + WORKFLOW ENGINE (Fase 1)
# ============================================================

WORKFLOW_STAGES = [
    ("Frame 1", "image", 1),
    ("Video 1", "video", 1),
    ("Frame 2", "image", 2),
    ("Video 2", "video", 2),
    ("Frame 3", "image", 3),
    ("Video 3", "video", 3),
    ("Frame 4", "image", 4),
    ("Video 4", "video", 4),
]


def analyze_product_image(image_path):
    """Gunakan agnes-2.5-flash untuk menganalisis gambar produk, menghasilkan Product Identity Profile.
    Return: dict dengan field shape/colors/materials/texture/details, serta string deskripsi.
    """
    import requests
    if not AGNES_API_KEY:
        raise RuntimeError("AGNES_API_KEY belum diatur.")

    # Upload gambar sebagai data URI (vision chat mendukung data URI)
    import base64
    p = Path(image_path)
    suffix = p.suffix.lower().lstrip(".") or "png"
    if suffix == "jpg":
        suffix = "jpeg"
    b64 = base64.b64encode(p.read_bytes()).decode("ascii")
    data_uri = f"data:image/{suffix};base64,{b64}"

    prompt = (
        "Analisis gambar produk ini secara detail. Kembalikan HANYA JSON valid "
        "dengan field berikut (string, bahasa Indonesia):\n"
        '{"shape":"bentuk produk", '
        '"proportions":"proporsi relatif", '
        '"colors":"warna asli yang terlihat", '
        '"materials":"material yang tampak", '
        '"texture":"tekstur permukaan", '
        '"logos_text":"logo/teks/tipografi yang terlihat (kosongkan jika tidak ada)", '
        '"details":"ciri desain khas", '
        '"handling":"cara memegang logis untuk produk ini", '
        '"description":"deskripsi ringkas 1-2 kalimat untuk prompt gambar"}\n'
        "Jangan mengarang spesifikasi yang tidak terlihat di gambar."
    )

    headers = {
        "Authorization": f"Bearer {AGNES_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "agnes-2.5-flash",
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": data_uri}},
            ],
        }],
        "temperature": 0.3,
    }
    studio_log("Menganalisis produk via agnes-2.5-flash...")
    r = requests.post(f"{AGNES_BASE}/chat/completions",
                      headers=headers, json=payload, timeout=120)
    if not r.ok:
        raise RuntimeError(f"Analisis produk HTTP {r.status_code}: {r.text[:300]}")
    content = r.json()["choices"][0]["message"]["content"].strip()

    # Ekstrak JSON (kadang dibungkus ```json)
    m = re.search(r"\{.*\}", content, re.DOTALL)
    if not m:
        raise RuntimeError(f"Respons analisis bukan JSON: {content[:300]}")
    profile = json.loads(m.group(0))
    studio_log(f"Profil produk: {profile.get('description', '')[:100]}...")
    return profile


def build_image_prompt(profile, frame_index):
    """Bangun prompt gambar Agnes sesuai arahan visual master prompt."""
    desc = profile.get("description", "produk")
    shape = profile.get("shape", "")
    colors = profile.get("colors", "")
    materials = profile.get("materials", "")
    texture = profile.get("texture", "")
    logos = profile.get("logos_text", "")
    details = profile.get("details", "")
    handling = profile.get("handling", "")

    fidelity = (
        f"Produk: {desc}. "
        f"Pertahankan PERSIS: bentuk ({shape}), warna asli ({colors}), "
        f"material ({materials}), tekstur ({texture}). "
    )
    if logos.strip():
        fidelity += f"Logo/teks yang terlihat: {logos} — jangan diubah. "
    if details.strip():
        fidelity += f"Ciri desain: {details}. "

    return (
        "Fotorealistis, produk showcase sudut pandang orang pertama (POV) perempuan. "
        "Sudut kamera sekitar 30 derajat ke bawah, jarak sekitar 40 cm dari produk. "
        f"Produk dipegang secara alami di depan pandangan. {fidelity}"
        f"Cara memegang: {handling}. "
        "Tangan: tampilan feminin, anatomi alami, jumlah jari benar, jari ramping, "
        "kulit bersih cerah, kuku oval pendek-sedang dengan cat kuku dusty pink mengilap, "
        "tanpa nail art. Hanya tampilkan tangan, pergelangan sangat sedikit, dan produk. "
        "JANGAN tampilkan wajah, kepala, rambut, badan, pakaian, atau kaki. "
        "Latar: taman tropis Indonesia yang tenang, rumput hijau, pohon besar, "
        "cahaya alami, bangku kosong, jalur setapak. Tanpa orang, hewan, atau kendaraan. "
        f"Variasi halus untuk frame {frame_index} dari 4: hanya pada detail latar belakang. "
        "Komposisi portrait 9:16. Kualitas fotorealistis tinggi."
    )


def build_video_prompt():
    """Prompt gerak video sesuai master prompt."""
    return (
        "Animasikan gambar pertama yang diberikan menjadi video product showcase fotorealistis. "
        "Tangan perempuan dengan lembut menggerakkan produk sedikit ke satu sisi, "
        "lalu kembali secara alami ke posisi semula. Tangan dan produk bergerak "
        "sebagai satu kesatuan. Pegangan dan posisi jari tetap stabil. "
        "Produk tetap terlihat jelas dan mempertahankan tampilan aslinya persis. "
        "Kamera tetap diam. Hanya gerakan halus alami di latar taman tropis. "
        "Gerakan sederhana, mulus, realistis, dan natural secara fisik. "
        "Jangan mengubah anatomi tangan, jumlah jari, atau bentuk produk."
    )


# ============================================================
# WORKFLOW STATE HELPERS
# ============================================================
def fresh_workflow_state():
    return {
        "step": 0,                 # 0..7, index ke WORKFLOW_STAGES
        "approved_frames": [],     # list 4 path gambar yang disetujui
        "approved_videos": [],     # list 4 path video yang disetujui
        "current_output": None,    # path output aktif (belum disetujui)
        "current_type": None,      # "image" / "video"
        "current_index": 0,        # 1..4
        "profile": None,           # Product Identity Profile
        "status": "idle",          # idle / generating / awaiting_approval / done
    }


def stage_label(step):
    if step >= len(WORKFLOW_STAGES):
        return "Selesai"
    name, kind, idx = WORKFLOW_STAGES[step]
    return f"{name} ({'Gambar' if kind == 'image' else 'Video'})"


def workflow_progress_text(state):
    """Teks progres untuk kolom kiri."""
    lines = ["**Progres Workflow**", ""]
    if state.get("profile"):
        lines.append("✅ Analisis Produk")
    else:
        lines.append("⬜ Analisis Produk")
    for i, (name, kind, idx) in enumerate(WORKFLOW_STAGES):
        if i < state["step"]:
            lines.append(f"✅ {name}")
        elif i == state["step"]:
            lines.append(f"🔄 {name} — aktif")
        else:
            lines.append(f"⬜ {name}")
    return "\n".join(lines)


def validate_agnes_config():
    if not AGNES_API_KEY:
        return (
            "⚠️ **AGNES_API_KEY belum diatur.**\n\n"
            "Set environment variable:\n"
            "```\nexport AGNES_API_KEY='sk-...'\n```\n"
            "Dapatkan key gratis di https://agnes-ai.com"
        )
    return ""

# ============================================================
# FUNGSI LAMA YANG DIPERLUKAN TAB 2 (disederhanakan, logika sama)
# ============================================================
import numpy as np
import librosa
import queue

_LOG_QUEUE = queue.Queue()
_LIVE_LOG = LOG_DIR / "live.log"


class RenderFailure(RuntimeError):
    def __init__(self, message, lines):
        super().__init__(message)
        self.lines = list(lines)


def now():
    return datetime.datetime.now().strftime("%H:%M:%S")


def log(lines, msg):
    line = f"[{now()}] {msg}"
    lines.append(line)
    try:
        with open(_LIVE_LOG, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass
    try:
        _LOG_QUEUE.put(line)
    except Exception:
        pass


def reset_live_log():
    try:
        _LIVE_LOG.write_text("", encoding="utf-8")
    except Exception:
        pass


def read_live_log():
    p = _LIVE_LOG
    if not p.exists():
        return ""
    try:
        c = p.read_text(encoding="utf-8", errors="replace")
        return c[-8000:] if len(c) > 8000 else c
    except Exception:
        return ""


def run(cmd, timeout=1800):
    return subprocess.run(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, errors="replace", timeout=timeout,
    )


def has_nvenc():
    try:
        r = subprocess.run(
            [FFMPEG, "-hide_banner", "-loglevel", "error",
             "-f", "lavfi", "-i", "testsrc=size=64x64:rate=1:duration=1",
             "-c:v", "h264_nvenc", "-f", "null", "-"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=15, text=True, errors="replace",
        )
        return r.returncode == 0
    except Exception:
        return False


NVENC = has_nvenc()


def duration(path):
    r = run([FFPROBE, "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", str(path)], 120)
    if r.returncode != 0 or not r.stdout.strip():
        raise RuntimeError("FFprobe failed: " + r.stderr.strip())
    return float(r.stdout.strip())


def decode_music(src, lines):
    src = Path(src)
    if not src.exists() or src.stat().st_size == 0:
        raise RuntimeError("Music file is missing or empty.")
    out = TEMP_DIR / f"music_{src.stem}_decoded.wav"
    hint = {".mp3": "mp3", ".wav": "wav", ".m4a": "mov", ".aac": "aac",
            ".flac": "flac", ".ogg": "ogg", ".opus": "ogg"}.get(src.suffix.lower())
    cmd = [FFMPEG, "-hide_banner", "-nostdin", "-y"]
    if hint:
        cmd += ["-f", hint]
    cmd += ["-i", "pipe:0", "-vn", "-ac", "2", "-ar", "44100",
            "-c:a", "pcm_s16le", str(out)]
    log(lines, "Music decode: sequential FFmpeg stdin (no seeking).")
    with open(src, "rb") as f:
        r = subprocess.run(cmd, stdin=f, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, timeout=900)
    if r.returncode or not out.exists() or out.stat().st_size == 0:
        raise RuntimeError("Music decode failed:\n" +
                           r.stderr.decode("utf-8", "replace").strip())
    return out


def detect_beat(wav, lines):
    y, sr = librosa.load(str(wav), sr=22050, mono=True)
    _, beats = librosa.beat.beat_track(y=y, sr=sr, units="time")
    beats = np.asarray(beats, dtype=float)
    dif = np.diff(beats)
    dif = dif[(dif >= 0.25) & (dif <= 2.5)]
    if len(dif) < 2:
        raise RuntimeError("Not enough reliable beats detected.")
    beat = float(np.median(dif))
    log(lines, f"Beat interval: {beat:.3f}s ({60 / beat:.1f} BPM)")
    return beat


def choose_segments(ds, beat, music_duration, min_total=11.0):
    import random
    total_src = sum(ds)
    available = min(total_src, music_duration)
    if available <= 0:
        raise RuntimeError("No usable video/music duration.")
    if available <= min_total:
        target = available
    else:
        headroom = available - min_total
        target = min_total + random.uniform(0.0, headroom * 0.7)
        target = min(target, available)
    n = len(ds)
    if n == 0:
        raise RuntimeError("No video files.")
    min_seg = max(2 * beat, 1.5)
    max_seg_cap = 6.5
    base = target / n
    base = max(min_seg, min(base, max_seg_cap))
    seg = []
    remaining = target
    for i, d in enumerate(ds):
        if i == n - 1:
            want = max(min_seg, min(d, remaining))
        else:
            jitter = random.uniform(0.35, 2.2)
            want = base * jitter
            want = max(min_seg, min(want, max_seg_cap, d))
            remaining_after = remaining - want
            min_needed = min_seg * (n - i - 1)
            if remaining_after < min_needed:
                want = max(min_seg, remaining - min_needed)
        mult = max(2, round(want / beat))
        if random.random() < 0.5:
            mult += random.choice([-1, 0, 1])
        mult = max(2, mult)
        s = mult * beat
        s = max(min_seg, min(s, d, max_seg_cap))
        seg.append(s)
        remaining = max(0.0, remaining - s)
    if sum(ds) >= min_total and sum(seg) < min_total:
        for i in range(len(seg)):
            while (sum(seg) + 1e-6 < min_total
                   and seg[i] + beat <= min(ds[i], max_seg_cap)):
                seg[i] += beat
            if sum(seg) + 1e-6 >= min_total:
                break
    return seg


def enc_args():
    if NVENC:
        return ["-c:v", "h264_nvenc", "-preset", "p4", "-cq", "23"]
    return ["-c:v", "libx264", "-preset", "veryfast", "-crf", "23"]


def cut(src, dst, sec):
    r = run([FFMPEG, "-hide_banner", "-nostdin", "-y", "-i", str(src),
             "-t", f"{sec:.6f}",
             "-vf", "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30",
             *enc_args(), "-c:a", "aac", "-b:a", "160k", "-pix_fmt", "yuv420p",
             "-map_metadata", "-1", "-map_chapters", "-1", str(dst)], 1800)
    if r.returncode:
        raise RuntimeError("Cut failed: " + r.stderr.strip())


def concat(cuts, out):
    txt = TEMP_DIR / "concat.txt"
    txt.write_text(
        "".join("file '" + str(Path(x).resolve()).replace("'", "'\\''") + "'\n"
                for x in cuts),
        encoding="utf-8",
    )
    r = run([FFMPEG, "-hide_banner", "-nostdin", "-y",
             "-f", "concat", "-safe", "0", "-i", str(txt),
             *enc_args(), "-c:a", "aac", "-b:a", "160k",
             "-pix_fmt", "yuv420p", "-map_metadata", "-1", str(out)], 1800)
    if r.returncode:
        raise RuntimeError("Concat failed: " + r.stderr.strip())


def mux(video, music, out):
    r = run([FFMPEG, "-hide_banner", "-nostdin", "-y",
             "-i", str(video), "-i", str(music),
             "-map", "0:v:0", "-map", "1:a:0",
             "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
             "-shortest", "-map_metadata", "-1", "-map_chapters", "-1",
             "-movflags", "+faststart", str(out)], 1800)
    if r.returncode:
        raise RuntimeError("Audio mux failed: " + r.stderr.strip())


def save_log(lines):
    p = LOG_DIR / ("render_" +
                   datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f') + ".log")
    p.write_text("\n".join(lines), encoding="utf-8")
    return p


def format_duration(seconds):
    try:
        s = int(round(float(seconds)))
    except (TypeError, ValueError):
        return "0:00"
    if s < 0:
        s = 0
    h, rem = divmod(s, 3600)
    m, sec = divmod(rem, 60)
    if h > 0:
        return f"{h}:{m:02d}:{sec:02d}"
    return f"{m}:{sec:02d}"


def music_files():
    return sorted([p for p in MUSIC_DIR.iterdir()
                   if p.is_file() and p.suffix.lower() in AUDIO_EXTS],
                  key=lambda p: p.name.lower())


def music_choices():
    choices = []
    for p in music_files():
        try:
            d = duration(p)
            label = f"{format_duration(d)} - {p.name}"
        except Exception:
            label = p.name
        choices.append((label, str(p)))
    return choices


def normalize_video_files(value):
    if value is None:
        return []
    if isinstance(value, (str, Path)):
        return [str(value)]
    return [str(x) for x in value]


def combine_video_files(current_files, new_files):
    current = normalize_video_files(current_files)
    new = normalize_video_files(new_files)
    combined = list(current) + list(new)
    seen = set()
    result = []
    for f in combined:
        if f not in seen:
            seen.add(f)
            result.append(f)
    return result if result else None


def clear_video_files():
    return None


def add_uploaded_music(upload):
    if not upload:
        choices = music_choices()
        return gr.update(choices=choices), None, None
    paths = upload if isinstance(upload, list) else [upload]
    added = []
    for p in paths:
        srcp = Path(p)
        if srcp.exists() and srcp.suffix.lower() in AUDIO_EXTS:
            dst = MUSIC_DIR / srcp.name
            if dst.exists():
                stem, suf = dst.stem, dst.suffix
                i = 2
                while dst.exists():
                    dst = MUSIC_DIR / f"{stem} ({i}){suf}"
                    i += 1
            shutil.copy2(srcp, dst)
            added.append(dst.name)
    choices = music_choices()
    selected = str(MUSIC_DIR / added[-1]) if added else None
    return gr.update(choices=choices, value=selected), None, selected


def select_music(path):
    return path if path else None


def sanitize_filename(name):
    name = str(name or '').strip()
    name = Path(name).stem
    name = re.sub(r'[\\/:*?"<>|\r\n]+', '_', name)
    name = re.sub(r'\s+', ' ', name).strip(' .')
    return name[:180] or (f"AutoVideo_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}")


def update_render_button(filename):
    return gr.update(interactive=bool(str(filename or '').strip()))

# Gemini caption — sama seperti kode lama, disingkat bagian log-nya
def generate_ai_caption(product_link, product_title, shop_name,
                        prompt_reference="", lines=None):
    raw_keys = os.environ.get("GEMINI_API_KEYS", "").strip()
    if raw_keys:
        api_keys = [k.strip() for k in re.split(r"[,;\n]+", raw_keys) if k.strip()]
    else:
        single_key = os.environ.get("GEMINI_API_KEY", "").strip()
        api_keys = [single_key] if single_key else []
    api_keys = list(dict.fromkeys(api_keys))
    if not api_keys:
        raise RuntimeError("API key Gemini belum diatur.")

    title = str(product_title or "").strip()
    shop = str(shop_name or "").strip()
    link = str(product_link or "").strip()
    reference = str(prompt_reference or "").strip()

    page_text = ""
    if not reference and link.startswith(("https://", "http://")):
        try:
            import requests
            from bs4 import BeautifulSoup
            headers = {"User-Agent": "Mozilla/5.0 (Linux; Android 12)"}
            r = requests.get(link, timeout=10, headers=headers)
            soup = BeautifulSoup(r.text, "html.parser")
            for tag in soup(["script", "style", "nav", "footer", "noscript"]):
                tag.decompose()
            page_text = re.sub(r"\s+", " ", soup.get_text(separator=" ", strip=True))[:4000]
        except Exception:
            page_text = ""

    if reference:
        source_text, source_label = reference, "PROMPT_REFERENSI"
    elif page_text:
        source_text, source_label = page_text, "HALAMAN_PRODUK"
    else:
        source_text, source_label = "", "JUDUL_TOKO_SAJA"

    if not title and not shop and not source_text:
        raise RuntimeError("Informasi produk kosong.")

    context = (f"Sumber data: {source_label}\nJudul: {title}\nToko: {shop}\n"
               f"Link: {link}\nInfo:\n{source_text[:12000] or '(kosong)'}")

    instruction = """Kamu copywriter TikTok Indonesia. Buat SATU caption final.
- Bahasa santai, natural, gaul. Panjang 150–300 karakter termasuk hashtag.
- 2–4 emoji relevan. Tepat 3 hashtag di akhir.
- Fokus pengalaman/manfaat, bukan spesifikasi.
- Jangan mengarang fitur/harga/diskon. Jangan sertakan URL atau CTA "cek bio".
- Output hanya caption final."""

    try:
        from google import genai
        model_name = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash").strip()
        last_error = None
        for index, api_key in enumerate(api_keys, start=1):
            try:
                client = genai.Client(api_key=api_key)
                response = client.models.generate_content(
                    model=model_name,
                    contents=instruction + "\n\nDATA:\n" + context,
                )
                caption = str(getattr(response, "text", "") or "").strip().strip(' "\'`')
                if not caption:
                    raise RuntimeError("Gemini caption kosong.")
                if lines is not None:
                    log(lines, f"AI caption ok (key {index}).")
                return caption
            except Exception as e:
                last_error = e
                if lines is not None:
                    log(lines, f"Gemini key {index} gagal: {type(e).__name__}")
                continue
        raise last_error or RuntimeError("Semua key Gemini gagal.")
    except Exception as e:
        raise RuntimeError(f"Gagal caption AI: {type(e).__name__}: {e}") from e

def build_tiktok_url(output_path, caption):
    p = Path(output_path)
    if not p.exists():
        raise RuntimeError("Output tidak ditemukan.")
    clean = re.sub(r"\s+", " ", str(caption or "")).strip()
    if not clean:
        raise RuntimeError("Caption kosong.")
    meta = {"duration": int(round(duration(p) * 1000)),
            "extension": p.suffix.lstrip('.') or "mp4",
            "name": p.stem, "size": str(p.stat().st_size)}
    file_meta = quote(json.dumps(meta, ensure_ascii=False, separators=(',', ':')), safe='')
    return ("https://www.tiktok.com/tiktokstudio/upload?from=capcut_pc_top"
            f"&file_meta={file_meta}&allow_comment=1&allow_content_reuse=0"
            f"&disclose_your_brand=0&disclose_branded_content=0"
            f"&title={quote(clean, safe='')}")


def make_clickable_tiktok_link(url):
    if not url:
        return ""
    return f"[Post TikTok](<{url}>)"


def render_video(videos, music_path, output_name, caption, duration_choice="21s"):
    lines = []
    try:
        vids = normalize_video_files(videos)
        if not vids:
            raise RuntimeError("Upload minimal 1 video.")
        if not music_path:
            raise RuntimeError("Pilih musik.")
        if not str(caption or '').strip():
            raise RuntimeError("Caption kosong.")

        local_vids = []
        for idx, v in enumerate(vids, 1):
            srcv = Path(v)
            if not srcv.exists():
                raise RuntimeError(f"Video tidak ada: {srcv}")
            dstv = INPUT_DIR / srcv.name
            if dstv.resolve() != srcv.resolve():
                if dstv.exists() and dstv.stat().st_size != srcv.stat().st_size:
                    dstv = INPUT_DIR / f"{srcv.stem}_{idx}{srcv.suffix}"
                shutil.copy2(srcv, dstv)
            local_vids.append(dstv)

        music = Path(music_path)
        if not music.exists():
            raise RuntimeError(f"Musik tidak ada: {music}")

        log(lines, "Mulai render.")
        ds = [duration(v) for v in local_vids]
        decoded = decode_music(music, lines)
        mdur = duration(decoded)
        beat = detect_beat(decoded, lines)
        min_total = 21.0 if str(duration_choice).strip().startswith("21") else 11.0
        segs = choose_segments(ds, beat, mdur, min_total=min_total)

        for p in list(TEMP_DIR.glob("cut_*.mp4")) + list(TEMP_DIR.glob("concat_*.mp4")):
            try:
                p.unlink()
            except Exception:
                pass

        cuts = []
        for i, (srcv, sec) in enumerate(zip(local_vids, segs), 1):
            dst = TEMP_DIR / f"cut_{i:02d}.mp4"
            cut(srcv, dst, sec)
            cuts.append(dst)

        joined = TEMP_DIR / f"concat_{datetime.datetime.now().strftime('%H%M%S%f')}.mp4"
        concat(cuts, joined)

        base = sanitize_filename(output_name)
        out = OUTPUT_DIR / f"{base}.mp4"
        if out.exists():
            stamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
            out = OUTPUT_DIR / f"{base}_{stamp}.mp4"

        mux(joined, decoded, out)
        tiktok_url = build_tiktok_url(out, caption)

        preview_proxy = TEMP_DIR / f"preview_{out.stem}.mp4"
        pr = run([FFMPEG, "-hide_banner", "-nostdin", "-y", "-i", str(out),
                  "-vf", "scale=480:-2", "-c:v", "libx264", "-crf", "30",
                  "-preset", "ultrafast", "-c:a", "aac", "-b:a", "64k",
                  "-movflags", "+faststart", "-map_metadata", "-1",
                  str(preview_proxy)], 600)
        if pr.returncode != 0 or not preview_proxy.exists():
            preview_proxy = out

        log(lines, f"✅ DONE → {out.name}")
        save_log(lines)
        return str(preview_proxy), str(out), tiktok_url

    except Exception as e:
        log(lines, f"❌ ERROR: {e}")
        save_log(lines)
        return None, None, None


def generate_render(videos, music_path, output_name, caption_text, duration_choice,
                    prompt_reference="", product_link="", product_title="", shop_name=""):
    lines = []
    try:
        reset_live_log()
        log(lines, "=== GENERATE START ===")
        caption_final = generate_ai_caption(
            product_link=product_link, product_title=product_title,
            shop_name=shop_name, prompt_reference=prompt_reference, lines=lines,
        )
        if not caption_final:
            raise RuntimeError("AI caption kosong.")

        preview_path, download_path, tiktok_url = render_video(
            videos, music_path, output_name, caption_final, duration_choice
        )
        combined_log = read_live_log()
        if not preview_path:
            return combined_log, None, None, "", caption_final
        return (combined_log, preview_path, download_path,
                make_clickable_tiktok_link(tiktok_url) if tiktok_url else "",
                caption_final)
    except Exception as e:
        log(lines, f"❌ GENERATE ERROR: {type(e).__name__}: {e}")
        save_log(lines)
        return read_live_log(), None, None, "", ""


def clear_caption_and_log():
    reset_live_log()
    return "", ""

# ============================================================
# UI UTAMA
# ============================================================
initial_music = music_choices()
initial_music_value = initial_music[0][1] if initial_music else None

with gr.Blocks(title="AI Product Commercial Studio + Video Editor") as app:

    with gr.Tab("1. Product Studio"):
        gr.Markdown(
            "## AI Product Commercial Studio\n"
            "Upload **1 foto produk** → Analisis → 4 Frame + 4 Video, "
            "setiap tahap perlu **Approve & Continue**."
        )
        agnes_warn = gr.Markdown(validate_agnes_config())

        with gr.Row(equal_height=False):
            # ---------- KOLOM KIRI ----------
            with gr.Column(scale=1, min_width=280):
                gr.Markdown("### Produk & Workflow")
                product_image = gr.Image(
                    label="Upload Foto Produk", type="filepath",
                    height=220,
                )
                analyze_btn = gr.Button("🔍 Analyze Product", variant="secondary")
                analysis_status = gr.Textbox(
                    label="Status Analisis", lines=4, interactive=False,
                )
                workflow_status = gr.Markdown(
                    workflow_progress_text(fresh_workflow_state()),
                )

            # ---------- KOLOM TENGAH ----------
            with gr.Column(scale=2, min_width=420):
                gr.Markdown("### Preview")
                current_stage = gr.Textbox(
                    label="Tahap Aktif", value="Belum mulai",
                    interactive=False, lines=1,
                )
                current_preview = gr.Image(
                    label="Preview Gambar", visible=True, height=380,
                )
                current_video = gr.Video(
                    label="Preview Video", visible=False, height=380,
                )
                gr.Markdown("**Hasil Sebelumnya:**")
                approved_gallery = gr.Gallery(
                    label="", columns=4, height=120,
                    object_fit="cover", interactive=False,
                )

            # ---------- KOLOM KANAN ----------
            with gr.Column(scale=1, min_width=300):
                gr.Markdown("### Generator")
                gen_section = gr.Markdown("**Nano Banana 2 — Image Generator** (Agnes)")
                gen_status = gr.Textbox(
                    label="Status Generator", lines=3, interactive=False,
                )
                generate_btn = gr.Button(
                    "⚡ Generate", variant="primary", size="lg",
                )
                regenerate_btn = gr.Button(
                    "🔄 Regenerate", variant="secondary", visible=False,
                )
                approve_btn = gr.Button(
                    "✅ Approve & Continue", variant="primary", visible=False,
                )
                send_to_editor_btn = gr.Button(
                    "📤 Kirim 4 Video ke Video Editor",
                    variant="secondary", visible=False,
                )
                studio_logbox = gr.Textbox(
                    label="Log Studio", lines=8, interactive=False,
                )
                studio_timer = gr.Timer(value=2.0)
                studio_timer.tick(read_studio_log, inputs=[], outputs=studio_logbox)

        # State
        wf_state = gr.State(fresh_workflow_state())

        # ---------- HANDLER: ANALYZE ----------
        def on_analyze(image_path, state):
            state = dict(state or fresh_workflow_state())
            if not image_path:
                return state, "❌ Upload gambar dulu.", workflow_progress_text(state), "", gr.update(), gr.update(), gr.update(), gr.update(), gr.update()
            if not AGNES_API_KEY:
                return state, "❌ AGNES_API_KEY belum diatur.", workflow_progress_text(state), "", gr.update(), gr.update(), gr.update(), gr.update(), gr.update()
            try:
                reset_studio_log()
                profile = analyze_product_image(image_path)
                state["profile"] = profile
                state["status"] = "analyzed"
                return (
                    state,
                    f"✅ Profil produk siap.\n{profile.get('description', '')}",
                    workflow_progress_text(state),
                    f"Profil: {profile.get('description', '')[:200]}",
                    gr.update(visible=False), gr.update(visible=False),
                    gr.update(visible=False), gr.update(visible=False),
                    gr.update(visible=True),
                )
            except Exception as e:
                return (
                    state, f"❌ Analisis gagal: {e}",
                    workflow_progress_text(state), str(e),
                    gr.update(), gr.update(), gr.update(), gr.update(), gr.update(),
                )

        analyze_btn.click(
            on_analyze, inputs=[product_image, wf_state],
            outputs=[wf_state, analysis_status, workflow_status, gen_status,
                     current_video, regenerate_btn, approve_btn,
                     send_to_editor_btn, generate_btn],
        )

        # ---------- HANDLER: GENERATE / REGENERATE ----------
        def on_generate(state, force_regenerate=False):
            state = dict(state or fresh_workflow_state())
            if not state.get("profile"):
                return (state, "❌ Lakukan Analyze Product dulu.",
                        workflow_progress_text(state), None, None,
                        gr.update(visible=False), gr.update(visible=False),
                        gr.update(visible=False), gr.update(visible=True),
                        gr.update(visible=False))
            step = state["step"]
            if step >= len(WORKFLOW_STAGES):
                return (state, "✅ Semua tahap selesai.",
                        workflow_progress_text(state), None, None,
                        gr.update(visible=False), gr.update(visible=False),
                        gr.update(visible=True), gr.update(visible=False),
                        gr.update(visible=False))
            name, kind, idx = WORKFLOW_STAGES[step]
            state["status"] = "generating"
            try:
                if kind == "image":
                    prompt = build_image_prompt(state["profile"], idx)
                    ref = state["approved_frames"][0] if state["approved_frames"] else None
                    out = agnes_generate_image(prompt, reference_image_path=ref,
                                               out_name=f"frame{idx}")
                    state["current_type"] = "image"
                    state["current_output"] = out
                    state["current_index"] = idx
                    return (
                        state, f"✅ {name} siap. Review lalu Approve atau Regenerate.",
                        workflow_progress_text(state), out, None,
                        gr.update(visible=True), gr.update(visible=True),
                        gr.update(visible=False), gr.update(visible=False),
                        gr.update(visible=False),
                    )
                else:
                    if len(state["approved_frames"]) < idx:
                        raise RuntimeError(f"Frame {idx} belum disetujui.")
                    first = state["approved_frames"][idx - 1]
                    prompt = build_video_prompt()
                    out = agnes_generate_video(first, prompt, out_name=f"video{idx}")
                    state["current_type"] = "video"
                    state["current_output"] = out
                    state["current_index"] = idx
                    return (
                        state, f"✅ {name} siap. Review lalu Approve atau Regenerate.",
                        workflow_progress_text(state), None, out,
                        gr.update(visible=True), gr.update(visible=True),
                        gr.update(visible=False), gr.update(visible=False),
                        gr.update(visible=False),
                    )
            except Exception as e:
                state["status"] = "error"
                return (
                    state, f"❌ Generate gagal: {e}",
                    workflow_progress_text(state), None, None,
                    gr.update(visible=False), gr.update(visible=False),
                    gr.update(visible=False), gr.update(visible=True),
                    gr.update(visible=False),
                )

        generate_btn.click(
            lambda s: on_generate(s, False),
            inputs=[wf_state],
            outputs=[wf_state, gen_status, workflow_status,
                     current_preview, current_video,
                     regenerate_btn, approve_btn,
                     send_to_editor_btn, generate_btn, current_stage],
        )
        regenerate_btn.click(
            lambda s: on_generate(s, True),
            inputs=[wf_state],
            outputs=[wf_state, gen_status, workflow_status,
                     current_preview, current_video,
                     regenerate_btn, approve_btn,
                     send_to_editor_btn, generate_btn, current_stage],
        )

        # ---------- HANDLER: APPROVE ----------
        def on_approve(state):
            state = dict(state or fresh_workflow_state())
            step = state["step"]
            if step >= len(WORKFLOW_STAGES):
                return (state, "✅ Selesai.", workflow_progress_text(state),
                        gr.update(visible=False), gr.update(visible=False),
                        gr.update(visible=False), gr.update(visible=True),
                        None, None, None, [], gr.update(visible=False))
            name, kind, idx = WORKFLOW_STAGES[step]
            out = state.get("current_output")
            if not out or not Path(out).exists():
                return (state, "❌ Tidak ada output untuk disetujui.",
                        workflow_progress_text(state),
                        gr.update(visible=False), gr.update(visible=False),
                        gr.update(visible=False), gr.update(visible=True),
                        None, None, None, [], gr.update(visible=False))
            if kind == "image":
                frames = list(state["approved_frames"])
                while len(frames) < idx:
                    frames.append(None)
                frames[idx - 1] = out
                state["approved_frames"] = frames
            else:
                videos = list(state["approved_videos"])
                while len(videos) < idx:
                    videos.append(None)
                videos[idx - 1] = out
                state["approved_videos"] = videos

            state["step"] = step + 1
            state["current_output"] = None
            state["current_type"] = None
            state["status"] = "awaiting_approval"

            gallery_items = [f for f in state["approved_frames"] if f] + \
                            [v for v in state["approved_videos"] if v]

            all_done = state["step"] >= len(WORKFLOW_STAGES)
            return (
                state,
                "🎉 Semua tahap selesai! Klik 'Kirim 4 Video ke Video Editor'."
                if all_done else f"✅ {name} disetujui. Lanjut ke tahap berikutnya.",
                workflow_progress_text(state),
                gr.update(visible=False), gr.update(visible=False),
                gr.update(visible=all_done), gr.update(visible=not all_done),
                None if not all_done else state["approved_videos"][-1] if state["approved_videos"] else None,
                None, None, gallery_items,
                gr.update(visible=False),
            )

        approve_btn.click(
            on_approve, inputs=[wf_state],
            outputs=[wf_state, gen_status, workflow_status,
                     regenerate_btn, approve_btn, send_to_editor_btn,
                     generate_btn, current_preview, current_video,
                     current_stage, approved_gallery, studio_logbox],
        )

        # ---------- HANDLER: KIRIM KE VIDEO EDITOR (placeholder, diisi di Bagian 4) ----------
        # Binding aktual memerlukan referensi komponen tab 2,
        # sehingga akan ditulis di Bagian 4 setelah tab 2 didefinisikan.
        send_payload = gr.State(None)

    # ============================================================
    # TAB 2: VIDEO EDITOR (alur lama, UI identik)
    # ============================================================
    with gr.Tab("2. Video Editor"):
        with gr.Row(elem_id="mainrow", equal_height=False):
            with gr.Column(scale=1, min_width=300, elem_id="videos"):
                gr.Markdown("Video", elem_classes=["ave-col-title"])
                videos = gr.File(label="", file_count="multiple",
                                 file_types=["video"], type="filepath", height=200)
                with gr.Row(elem_id="video-actions"):
                    add_video = gr.UploadButton(
                        "＋ Add", file_count="multiple",
                        file_types=["video"], size="sm",
                    )
                    clear_video = gr.Button("✕ Clear", size="sm")

            with gr.Column(scale=1, min_width=240, elem_id="musicpanel"):
                gr.Markdown("Music", elem_classes=["ave-col-title"])
                music = gr.Dropdown(label="", choices=initial_music,
                                    allow_custom_value=False)
                music_player = gr.Audio(label="", type="filepath",
                                        interactive=False, autoplay=False,
                                        value=initial_music_value)
                music_upload = gr.File(label="", file_count="multiple",
                                       file_types=["audio"], type="filepath", height=80)
                add_music = gr.Button("＋ Add", size="sm")

            with gr.Column(scale=1, min_width=240, elem_id="contentpanel"):
                gr.Markdown("Content", elem_classes=["ave-col-title"])
                with gr.Row(elem_id="content-actions"):
                    duration_choice = gr.Radio(
                        choices=["11s", "21s"], value="21s",
                        label="", container=False,
                    )
                    action_btn = gr.Button(
                        "Generate", size="sm", variant="secondary",
                        interactive=False, scale=8,
                    )
                tiktok_link = gr.Markdown(
                    "Post TikTok will be available after the video is ready."
                )
                output_name = gr.Textbox(label="",
                                         placeholder="File name / Product ID",
                                         lines=1)
                caption = gr.Textbox(
                    label="Caption",
                    placeholder="Caption akan dibuat otomatis oleh AI...",
                    lines=5, interactive=True,
                )

            with gr.Column(scale=1, min_width=280, elem_id="preview"):
                gr.Markdown("Output", elem_classes=["ave-col-title"])
                preview = gr.Video(label="", height=320, interactive=False)
                download = gr.File(label="", interactive=False)

        with gr.Row(elem_id="outputrow", equal_height=False):
            with gr.Column(scale=1, min_width=500, elem_id="promptpanel"):
                gr.Markdown("Prompt (referensi)", elem_classes=["ave-col-title"])
                prompt_box = gr.Textbox(
                    label="",
                    placeholder="Isi deskripsi produk. AI memakai ini sebagai sumber caption.",
                    lines=9,
                )
            with gr.Column(scale=1, min_width=360, elem_id="logpanel"):
                gr.Markdown("Log", elem_classes=["ave-col-title"])
                log_timer = gr.Timer(value=1.0)
                logbox = gr.Textbox(label="", lines=16, max_lines=30,
                                    interactive=False)
                log_timer.tick(read_live_log, inputs=[], outputs=logbox)

        selected_product_id = gr.Textbox(visible=False)
        product_title = gr.Textbox(visible=False)
        product_link = gr.Textbox(visible=False)
        shop_name = gr.Textbox(visible=False)

        # Event binding tab 2 (sama seperti kode lama)
        output_name.input(update_render_button, inputs=output_name,
                          outputs=action_btn)
        output_name.change(update_render_button, inputs=output_name,
                           outputs=action_btn)
        add_video.upload(combine_video_files, inputs=[videos, add_video],
                         outputs=videos)
        clear_video.click(clear_video_files, inputs=[], outputs=videos)
        add_music.click(add_uploaded_music, inputs=[music_upload],
                        outputs=[music, music_upload, music_player])
        music.change(select_music, inputs=music, outputs=music_player)
        action_btn.click(
            fn=clear_caption_and_log, inputs=[], outputs=[caption, logbox],
        ).then(
            fn=generate_render,
            inputs=[videos, music, output_name, caption, duration_choice,
                    prompt_box, product_link, product_title, shop_name],
            outputs=[logbox, preview, download, tiktok_link, caption],
        )

    # ---------- BINDING KIRIM KE VIDEO EDITOR (butuh komponen tab 2) ----------
    def on_send_to_editor(state):
        state = dict(state or fresh_workflow_state())
        vids = [v for v in state.get("approved_videos", []) if v and Path(v).exists()]
        if len(vids) < 4:
            return (state, f"❌ Butuh 4 video disetujui, saat ini {len(vids)}.",
                    gr.update(), "")
        return (state, f"✅ {len(vids)} video dikirim ke Video Editor.",
                gr.update(value=vids), "")

    send_to_editor_btn.click(
        on_send_to_editor, inputs=[wf_state],
        outputs=[wf_state, gen_status, videos, studio_logbox],
    )

# ============================================================
# LAUNCH — Cloudflare Tunnel
# ============================================================
PORT = 7860
CLOUDFLARED_BIN = os.path.expanduser("~/cloudflared")


def _kill_port_7860():
    killed = False
    if shutil.which("lsof"):
        try:
            r = subprocess.run(
                ["lsof", "-ti", f":{PORT}"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            )
            for pid in [int(x) for x in r.stdout.strip().split()
                        if x.strip().isdigit()]:
                try:
                    os.kill(pid, signal.SIGKILL)
                    print(f"🔪 Killed PID {pid} (lsof)")
                    killed = True
                except Exception:
                    pass
        except Exception:
            pass
    if not killed and shutil.which("fuser"):
        try:
            subprocess.run(
                ["fuser", "-k", f"{PORT}/tcp"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5,
            )
            print("🔪 Killed via fuser")
            killed = True
        except Exception:
            pass
    if killed:
        time.sleep(2)


if __name__ == "__main__":
    _kill_port_7860()

    # Kill cloudflared lama
    if "_ave_tunnel_proc" in globals():
        try:
            globals()["_ave_tunnel_proc"].terminate()
            time.sleep(1)
        except Exception:
            pass
    try:
        subprocess.run(
            ["pkill", "-f", "cloudflared"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5,
        )
        time.sleep(1)
    except Exception:
        pass

    # Install cloudflared
    if not os.path.exists(CLOUDFLARED_BIN):
        print("📥 Install cloudflared ke ~/cloudflared...")
        subprocess.run(
            "wget -q "
            "https://github.com/cloudflare/cloudflared/releases/latest/download/"
            f"cloudflared-linux-amd64 -O {CLOUDFLARED_BIN} "
            f"&& chmod +x {CLOUDFLARED_BIN}",
            shell=True, check=True,
        )
        print(f"✅ cloudflared terinstall: {CLOUDFLARED_BIN}")
    else:
        print(f"✅ cloudflared sudah ada: {CLOUDFLARED_BIN}")

    # Peringatan konfigurasi (tidak fatal)
    if not AGNES_API_KEY:
        print("⚠️  AGNES_API_KEY belum diatur — tab Product Studio tidak bisa generate.")
    if not (os.environ.get("GEMINI_API_KEYS") or os.environ.get("GEMINI_API_KEY")):
        print("⚠️  GEMINI_API_KEY belum diatur — caption AI tab Video Editor tidak bisa generate.")

    print(f"▶ Launch Gradio di port {PORT}...")
    try:
        app.launch(
            server_name="0.0.0.0",
            server_port=PORT,
            share=False,
            debug=False,
            quiet=True,
            prevent_thread_lock=True,
            theme=gr.themes.Base(),
        )
        print("✅ Gradio jalan.")
    except Exception as e:
        print(f"❌ Gagal launch Gradio: {e}")
        raise

    # Cloudflare Tunnel
    print("🌐 Membuka Cloudflare Tunnel...")
    tunnel = subprocess.Popen(
        [CLOUDFLARED_BIN, "tunnel",
         "--url", f"http://127.0.0.1:{PORT}",
         "--no-autoupdate", "--protocol", "http2"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )
    globals()["_ave_tunnel_proc"] = tunnel

    public_url = None
    for _ in range(60):
        line = tunnel.stdout.readline()
        if not line:
            break
        m = re.search(r"https://[a-z0-9-]+\.trycloudflare\.com", line)
        if m:
            public_url = m.group(0)
            break

    if public_url:
        print("\n" + "=" * 60)
        print("✅ CLOUDFLARE TUNNEL AKTIF")
        print(f"🔗 {public_url}")
        print("=" * 60)
        print("Link ini bisa dibuka siapa saja tanpa login Google.")
        print("Catatan: URL berubah setiap restart runtime.")
    else:
        print("⚠️ Gagal mendapatkan URL Cloudflare. Cek log tunnel di atas.")

    try:
        tunnel.wait()
    except KeyboardInterrupt:
        print("\n🛑 Dihentikan user.")
        try:
            tunnel.terminate()
        except Exception:
            pass

  
