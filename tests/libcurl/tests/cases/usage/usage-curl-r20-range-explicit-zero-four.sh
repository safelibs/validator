#!/usr/bin/env bash
# @testcase: usage-curl-r20-range-explicit-zero-four
# @title: curl --range 0-4 fetches the first five bytes from a loopback server
# @description: Stands up a python loopback http.server that serves a fixed 16-byte payload, then issues curl --range 0-4 -o file and asserts the recovered file is exactly 5 bytes long and matches the prefix of the payload - locking in client-driven Range request handling.
# @timeout: 90
# @tags: usage, curl, range, prefix, r20
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
pid=""
cleanup() {
    if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
    rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$tmpdir/server.py" <<'PY'
import http.server, sys
PAYLOAD=b'ABCDEFGHIJKLMNOP'
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        rng=self.headers.get('Range','')
        if rng.startswith('bytes='):
            spec=rng[len('bytes='):]
            try:
                lo,hi=spec.split('-',1)
                lo=int(lo) if lo else 0
                hi=int(hi) if hi else len(PAYLOAD)-1
            except Exception:
                self.send_response(400); self.send_header('Content-Length','0'); self.end_headers(); return
            body=PAYLOAD[lo:hi+1]
            self.send_response(206)
            self.send_header('Content-Range', f'bytes {lo}-{hi}/{len(PAYLOAD)}')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers(); self.wfile.write(body)
        else:
            self.send_response(200); self.send_header('Content-Length', str(len(PAYLOAD))); self.end_headers(); self.wfile.write(PAYLOAD)
    def log_message(self,*a,**k): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PY

port=$((41000 + RANDOM % 18000))
python3 "$tmpdir/server.py" "$port" >/dev/null 2>&1 &
pid=$!
ready=0
for _ in $(seq 1 60); do
    if curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/.ping" 2>/dev/null; then
        ready=1; break
    fi
    sleep 0.1
done
[[ "$ready" -eq 1 ]] || { printf 'server never became ready\n' >&2; exit 1; }

curl --noproxy '*' -sS --max-time 5 --range 0-4 "http://127.0.0.1:$port/" -o "$tmpdir/got"
n=$(wc -c <"$tmpdir/got")
[[ "$n" -eq 5 ]] || { printf 'expected 5 bytes, got %s\n' "$n" >&2; exit 1; }
got=$(cat "$tmpdir/got")
[[ "$got" == "ABCDE" ]] || { printf 'expected ABCDE, got %q\n' "$got" >&2; exit 1; }
