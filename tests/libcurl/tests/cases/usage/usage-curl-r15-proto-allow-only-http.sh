#!/usr/bin/env bash
# @testcase: usage-curl-r15-proto-allow-only-http
# @title: curl --proto '-all,+http' enables only HTTP and successfully fetches an http:// URL
# @description: Issues a curl GET against a loopback HTTP server with --proto '-all,+http' so every protocol except HTTP is disabled. Asserts the request still completes with a 200 response code and the body matches the served file, demonstrating the per-protocol allowlist.
# @timeout: 180
# @tags: usage, curl, http, proto
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

mkdir -p "$tmpdir/srv"
printf 'r15 proto allow-http body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

code=$(curl --noproxy '*' -sS --max-time 5 \
    --proto '-all,+http' \
    -o "$tmpdir/got.txt" -w '%{http_code}' \
    "http://127.0.0.1:$port/payload.txt")
[[ "$code" == "200" ]] || {
    printf 'expected 200 from --proto -all,+http, got %q\n' "$code" >&2
    exit 1
}
diff -q "$tmpdir/srv/payload.txt" "$tmpdir/got.txt"
