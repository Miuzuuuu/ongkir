"""Jalankan dari folder proyek dengan python tool/rajaongkir.py."""
import json
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ROOT = "https://rajaongkir.komerce.id/api/v1"
KEY = (Path(__file__).resolve().parents[1] / ".rajaongkir-key").read_text().strip()


class Gateway(BaseHTTPRequestHandler):
    def forward(self):
        origin = self.headers.get("Origin", "")
        if not re.fullmatch(r"http://(localhost|127\.0\.0\.1):[0-9]+", origin):
            return self.send_error(403)
        locations = r"/destination/(province|(city|district|sub-district)/[0-9]+)"
        if self.command == "GET" and re.fullmatch(locations, self.path):
            data = None
        elif self.command == "POST" and self.path == "/calculate/district/domestic-cost":
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= 2048:
                return self.send_error(400)
            data = self.rfile.read(length)
        else:
            return self.send_error(404)
        req = Request(ROOT + self.path, data=data, headers={"key": KEY, "User-Agent": "Ongkir-Flutter/1.0", "Accept": "application/json"})
        try:
            with urlopen(req, timeout=30) as response:
                status, body = response.status, response.read()
        except HTTPError as error:
            status, body = error.code, error.read()
        except (URLError, TimeoutError):
            status, body = 502, json.dumps({"error": "RajaOngkir tidak dapat dijangkau"}).encode()
        self.send_response(status)
        self.send_header("Access-Control-Allow-Origin", origin)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    do_GET = do_POST = forward


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 8766), Gateway).serve_forever()
