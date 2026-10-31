"""Serve the Flutter web build and forward its same-origin API requests."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent


class MobileWebHandler(SimpleHTTPRequestHandler):
    api_url = "http://127.0.0.1:8000"

    def do_GET(self):
        if self.path.startswith("/api/"):
            return self.proxy_api()
        return super().do_GET()

    def do_POST(self):
        if self.path.startswith("/api/"):
            return self.proxy_api()
        self.send_error(405)

    def proxy_api(self):
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length < 0 or length > 1024 * 1024:
                return self.send_error(413)
            body = self.rfile.read(length) if length else None
            headers = {key: self.headers[key] for key in
                       ("Authorization", "Content-Type", "Accept") if key in self.headers}
            request = Request(self.api_url + self.path, data=body,
                              headers=headers, method=self.command)
            try:
                response = urlopen(request, timeout=190)
            except HTTPError as error:
                response = error
            with response:
                content = response.read()
                self.send_response(response.status)
                self.send_header("Content-Type", response.headers.get("Content-Type", "application/json"))
                self.send_header("Content-Length", str(len(content)))
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(content)
        except (URLError, TimeoutError, OSError, ValueError):
            self.send_error(502, "BSAS API unavailable. Start the backend and retry.")

    def end_headers(self):
        if not self.path.startswith("/api/"):
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()
    directory = ROOT / "build" / "web"
    if not (directory / "index.html").exists():
        raise SystemExit("Web build missing. Run flutter build web --release first.")
    handler = partial(MobileWebHandler, directory=str(directory))
    print(f"BSAS mobile web app: http://127.0.0.1:{args.port}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()
