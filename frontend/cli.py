import sys
import json
import argparse
import httpx

# Fix Windows console encoding for emoji/Unicode output
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

LLAMA_API = "http://127.0.0.1:11434"


def fetch_model_name() -> str:
    try:
        r = httpx.Client(transport=httpx.HTTPTransport()).get(f"{LLAMA_API}/v1/models", timeout=5)
        r.raise_for_status()
        models = r.json().get("data", [])
        return models[0].get("id", "model") if models else "model"
    except Exception:
        return "model"


def ask_model_stream(messages: list):
    payload = {
        "messages": messages,
        "stream": True,
        "temperature": 0.7,
        "repeat_penalty": 1.1,
        "top_k": 40,
    }
    try:
        with httpx.Client(transport=httpx.HTTPTransport(), timeout=300) as client:
            with client.stream("POST", f"{LLAMA_API}/v1/chat/completions", json=payload) as resp:
                for line in resp.iter_lines():
                    if not line or not line.startswith("data: "):
                        continue
                    raw = line[6:]
                    if raw == "[DONE]":
                        break
                    try:
                        data = json.loads(raw)
                    except json.JSONDecodeError:
                        continue
                    choices = data.get("choices", [])
                    if not choices:
                        continue
                    delta = choices[0].get("delta", {})
                    content = delta.get("content", "")
                    if content:
                        yield content
    except httpx.RequestError as e:
        yield f"\n[Error] Cannot reach llama.cpp at {LLAMA_API}: {e}"
    except Exception as e:
        yield f"\n[Error] {e}"


def ask_model(messages: list) -> str:
    payload = {"messages": messages, "stream": False, "temperature": 0.7}
    try:
        r = httpx.Client(transport=httpx.HTTPTransport()).post(
            f"{LLAMA_API}/v1/chat/completions", json=payload, timeout=120
        )
        r.raise_for_status()
        data = r.json()
        return data.get("choices", [{}])[0].get("message", {}).get("content", "")
    except httpx.RequestError as e:
        return f"[Error] Cannot reach llama.cpp at {LLAMA_API}: {e}"
    except Exception as e:
        return f"[Error] {e}"


def interactive_mode():
    name = fetch_model_name()
    print(f" {name}  (llama.cpp: {LLAMA_API})")
    print("Type '/exit' to quit, '/clear' to reset history.\n")
    messages = [
        {"role": "system", "content": "你是一个有用的中文AI助手。请用中文回答用户的问题，语言简洁自然。"}
    ]

    while True:
        try:
            user_input = input(">>> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nBye!")
            break

        if not user_input:
            continue
        if user_input == "/exit":
            print("Bye!")
            break
        if user_input == "/clear":
            messages.clear()
            print("History cleared.\n")
            continue

        messages.append({"role": "user", "content": user_input})

        reply = ""
        for token in ask_model_stream(messages):
            print(token, end="", flush=True)
            reply += token
        print()

        messages.append({"role": "assistant", "content": reply})


def single_query_mode(prompt: str):
    messages = [
        {"role": "system", "content": "你是一个有用的中文AI助手。请用中文回答用户的问题，语言简洁自然。"},
        {"role": "user", "content": prompt},
    ]
    for token in ask_model_stream(messages):
        print(token, end="", flush=True)
    print()


def main():
    global LLAMA_API
    parser = argparse.ArgumentParser(description="LLM CLI (llama.cpp)")
    parser.add_argument("prompt", nargs="?", help="Single query prompt")
    parser.add_argument("--api-url", default=LLAMA_API, help="llama.cpp API URL")
    args = parser.parse_args()

    if args.prompt:
        single_query_mode(args.prompt)
    else:
        interactive_mode()


if __name__ == "__main__":
    main()
