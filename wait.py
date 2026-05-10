import sys, os, time, urllib.request, json

port = os.environ.get("LLAMA_PORT", "11434")
url = f"http://127.0.0.1:{port}/health"

start = time.time()
for i in range(60):
    try:
        r = urllib.request.urlopen(url, timeout=2)
        if r.status == 200:
            break
    except Exception:
        pass
    if i % 5 == 4:
        print('.', end='', flush=True)
    time.sleep(1)
else:
    print(' timed out')
    sys.exit(1)

print(f' model loaded in {time.time() - start:.0f}s')
