# Tiny HTTP server for VM tests (the guest reaches the host at 10.0.2.2 when
# booted with network, VMOPTS= in vm-session.sh):
#   python -I iso/test/vm-http.py <port> <serve dir> <upload dir>
#   in the guest: curl -s 10.0.2.2:<port>/script.sh | bash           (GET a file)
#                 cmd | curl -s --data-binary @- 10.0.2.2:<port>/out  (POST: saved as <upload dir>/out)
# Stop it by PID (`... & srv=$!; ...; kill $srv`): `pkill -f` would also match
# the shell that started it.
import http.server, os, sys
port, serve_dir, up_dir = int(sys.argv[1]), sys.argv[2], sys.argv[3]
os.makedirs(up_dir, exist_ok=True)
class H(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k): super().__init__(*a, directory=serve_dir, **k)
    def do_POST(self):
        name = os.path.basename(self.path) or "upload"
        data = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        with open(os.path.join(up_dir, name), "wb") as f: f.write(data)
        self.send_response(200); self.end_headers()
    def log_message(self, *a): pass
http.server.ThreadingHTTPServer(("0.0.0.0", port), H).serve_forever()
