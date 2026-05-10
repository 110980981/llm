"""Auto-download llama.cpp server (llama-server.exe + DLLs)."""
import os, sys, subprocess, urllib.request, zipfile, json, re
from pathlib import Path

ROOT = Path(__file__).parent
LLAMA_DIR = ROOT / "llama"
SERVER_EXE = LLAMA_DIR / "llama-server.exe"

CUDA_MAP = {"11": "cuda-cu11", "12": "cuda-cu12.8", "13": "cuda-cu13.1"}
CPU_TAG = "avx2-x64"

# Hardcoded fallback when GitHub API is unreachable
FALLBACK_TAG = "b9089"


def get_latest_tag():
    url = "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"
    try:
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=10) as r:
            return json.loads(r.read())["tag_name"]
    except Exception as e:
        print(f"  Warning: could not fetch latest release: {e}", file=sys.stderr)
        return FALLBACK_TAG


def detect_cuda():
    try:
        out = subprocess.check_output(["nvidia-smi"], stderr=subprocess.DEVNULL, text=True)
        for line in out.splitlines():
            m = re.search(r"CUDA Version:\s*(\d+)\.", line)
            if m:
                return m.group(1)
    except (FileNotFoundError, subprocess.CalledProcessError):
        pass
    return None


def bootstrap():
    if SERVER_EXE.exists():
        print("llama.cpp already bootstrapped.")
        return True

    tag = get_latest_tag()
    cuda_ver = detect_cuda()
    if cuda_ver and cuda_ver in CUDA_MAP:
        plat = CUDA_MAP[cuda_ver]
        label = f"CUDA {cuda_ver}"
    else:
        plat = CPU_TAG
        label = "CPU"
        if cuda_ver:
            print(f"  CUDA {cuda_ver} has no pre-built binary, falling back to CPU.", file=sys.stderr)

    zip_name = f"llama-{tag}-bin-win-{plat}-x64.zip"
    url = f"https://github.com/ggml-org/llama.cpp/releases/download/{tag}/{zip_name}"

    print(f"Downloading llama.cpp {tag} ({label})...")
    LLAMA_DIR.mkdir(parents=True, exist_ok=True)
    zip_path = LLAMA_DIR / "llama.zip"

    try:
        urllib.request.urlretrieve(url, zip_path)
    except Exception as e:
        print(f"  Download failed: {e}", file=sys.stderr)
        print(f"  Try downloading manually from:", file=sys.stderr)
        print(f"    {url}", file=sys.stderr)
        return False

    print("  Extracting...")
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(LLAMA_DIR)
    zip_path.unlink()
    print("  Done!")
    return True


if __name__ == "__main__":
    sys.exit(0 if bootstrap() else 1)
