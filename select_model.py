import json, os, sys, urllib.request

models_path = os.path.join(os.path.dirname(__file__), "models.json")
root_dir = os.path.dirname(__file__)

with open(models_path, encoding="utf-8") as f:
    models = json.load(f)

print("\nAvailable models:", file=sys.stderr)
for k, v in models.items():
    exists = os.path.exists(os.path.join(root_dir, v["gguf"]))
    mark = "✓" if exists else "✗"
    print(f"  [{k}] [{mark}] {v['desc']}", file=sys.stderr)

print("Select model (default 1): ", file=sys.stderr, end="")
sys.stderr.flush()
choice = sys.stdin.readline().strip() or "1"
if choice not in models:
    print("Invalid choice, using default.", file=sys.stderr)
    choice = "1"

selected = models[choice]
gguf_path = os.path.join(root_dir, selected["gguf"])

# Auto-download if missing and URL is configured
if not os.path.exists(gguf_path) and selected.get("url"):
    print(f"\nFile not found: {selected['gguf']}", file=sys.stderr)
    print(f"Download from: {selected['url']}", file=sys.stderr)
    print("Download now? [Y/n]: ", file=sys.stderr, end="")
    sys.stderr.flush()
    ans = sys.stdin.readline().strip().lower()
    if ans in ("", "y", "yes"):
        print(f"Downloading {selected['gguf']}...", file=sys.stderr)
        try:
            def progress(block, block_size, total_size):
                if total_size > 0:
                    pct = min(100, block * block_size * 100 // total_size)
                    print(f"\r  {pct}%", end="", file=sys.stderr)
                sys.stderr.flush()
            urllib.request.urlretrieve(selected["url"], gguf_path, progress)
            print(f"\n  Saved to {gguf_path}", file=sys.stderr)
        except Exception as e:
            print(f"\n  Download failed: {e}", file=sys.stderr)
            print("  You can download manually and place the file in the project root.", file=sys.stderr)
            sys.exit(1)

# Output: GGUF path | model name | extra flags (single line for batch parsing)
moe_flags = "--n-cpu-moe 32 --no-warmup" if selected.get("moe") else ""
reasoning_off = "--reasoning off --reasoning-budget 0" if "qwen3" in selected["name"].lower() else ""
extra_flags = f"{moe_flags} {reasoning_off}".strip()
print(f"{gguf_path}|{selected['name']}|{extra_flags}")
