import json, os, sys

models_path = os.path.join(os.path.dirname(__file__), "models.json")
root_dir = os.path.dirname(__file__)

with open(models_path, encoding="utf-8") as f:
    models = json.load(f)

print("\nAvailable models:", file=sys.stderr)
for k, v in models.items():
    print(f"  [{k}] {v['desc']}", file=sys.stderr)

print("Select model (default 1): ", file=sys.stderr, end="")
sys.stderr.flush()
choice = sys.stdin.readline().strip() or "1"
if choice not in models:
    print("Invalid choice, using default.", file=sys.stderr)
    choice = "1"

# Output: GGUF path | model name | moe flags  (single line for batch parsing)
gguf_path = os.path.join(root_dir, models[choice]["gguf"])
moe_flags = "--n-cpu-moe 32 --no-warmup" if models[choice].get("moe") else ""
reasoning_off = "--reasoning off --reasoning-budget 0" if "qwen3" in models[choice]["name"].lower() else ""
extra_flags = f"{moe_flags} {reasoning_off}".strip()
print(f"{gguf_path}|{models[choice]['name']}|{extra_flags}")
