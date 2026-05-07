#!/usr/bin/env bash
# @testcase: usage-curl-r14-multi-next-fetches-two-urls
# @title: curl --next runs a second request in the same invocation with a separate output file
# @description: Issues a single curl invocation that fetches two URLs separated by --next, with each URL's body written to a distinct -o output. Asserts both files are populated with their respective server payloads, demonstrating the per-request reset between --next-delimited requests.
# @timeout: 180
# @tags: usage, curl, http, multi
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
printf 'r14 next-first body\n' >"$tmpdir/srv/a.txt"
printf 'r14 next-second body\n' >"$tmpdir/srv/b.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 10 \
    -o "$tmpdir/got_a.txt" "http://127.0.0.1:$port/a.txt" \
    --next \
    -o "$tmpdir/got_b.txt" "http://127.0.0.1:$port/b.txt"

diff -q "$tmpdir/srv/a.txt" "$tmpdir/got_a.txt"
diff -q "$tmpdir/srv/b.txt" "$tmpdir/got_b.txt"
