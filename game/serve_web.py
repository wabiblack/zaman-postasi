#!/usr/bin/env python3
"""Serve Godot web build with correct MIME types for iPhone Safari."""
import os
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.join(os.path.dirname(__file__), "build", "web")
PORT = 8765

class Handler(SimpleHTTPRequestHandler):
    extensions_map = {
        **getattr(SimpleHTTPRequestHandler, "extensions_map", {}),
        ".html": "text/html",
        ".js": "application/javascript",
        ".mjs": "application/javascript",
        ".json": "application/json",
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".png": "image/png",
        ".svg": "image/svg+xml",
        ".css": "text/css",
    }

    def end_headers(self):
        # Helpful for local/dev; not required for nothreads build
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

if __name__ == "__main__":
    os.chdir(ROOT)
    httpd = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"Serving {ROOT} on http://0.0.0.0:{PORT}", flush=True)
    httpd.serve_forever()
