"""Run the existing Flutter app on the laptop, with its backend and local AI."""
from pathlib import Path
import socket
import subprocess
import sys
import webbrowser

ROOT = Path(__file__).resolve().parent.parent
LOGS = ROOT / "output"
LOGS.mkdir(exist_ok=True)

def start(port, args, cwd, name):
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=1):
            print(f"Service already listening on {port}")
            return
    except OSError:
        pass
    with (LOGS / f"{name}.log").open("a", encoding="utf-8") as log:
        subprocess.Popen(args, cwd=cwd, stdout=log, stderr=log,
                         creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0)

if __name__ == "__main__":
    python = str(ROOT / "venv/Scripts/python.exe")
    runtime = Path.home() / ".lmstudio/extensions/backends/llama.cpp-win-x86_64-avx2-2.38.0/llama-server.exe"
    model = Path.home() / ".lmstudio/models/Manojb/Qwen_Qwen3.5-4B-Q4_K_M.gguf/Qwen_Qwen3.5-4B-Q4_K_M.gguf"
    if runtime.exists() and model.exists():
        start(1234, [str(runtime), "-m", str(model), "--host", "127.0.0.1", "--port", "1234",
                     "--ctx-size", "4096", "--threads", "6", "--n-gpu-layers", "0",
                     "--alias", "bsas-local", "--jinja"], ROOT, "web-local-ai")
    else:
        print("Local model missing; configure a provider in backend/.env.")
    start(8000, [python, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000"], ROOT / "backend", "web-backend")
    if not (ROOT / "build/web/index.html").exists():
        raise SystemExit("Web build missing. Run flutter build web --release first.")
    start(8080, [python, str(ROOT / "scripts/serve_mobile_web.py")], ROOT, "mobile-web")
    print("BSAS: http://127.0.0.1:8080 — AI may need a moment to load.")
    if "--no-browser" not in sys.argv:
        webbrowser.open("http://127.0.0.1:8080")
