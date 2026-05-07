#!/usr/bin/env bash
# @testcase: usage-curl-r12-write-out-url-token
# @title: curl -w %{url} echoes the requested URL exactly as supplied on the command line
# @description: Fetches a loopback URL with a unique query string and -w '%{url}', asserts curl emits the exact URL passed on the command line as the write-out token even when the body itself goes elsewhere.
# @timeout: 180
# @tags: usage, curl, http, write-out
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
printf 'r12 url-token body\n' >"$tmpdir/srv/index.html"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

target="http://127.0.0.1:$port/index.html?marker=r12"
got=$(curl --noproxy '*' -sS --max-time 5 -o /dev/null -w '%{url}' "$target")
[[ "$got" == "$target" ]] || {
    printf 'expected %%{url} %q, got %q\n' "$target" "$got" >&2
    exit 1
}
