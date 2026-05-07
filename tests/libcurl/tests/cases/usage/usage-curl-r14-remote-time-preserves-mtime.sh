#!/usr/bin/env bash
# @testcase: usage-curl-r14-remote-time-preserves-mtime
# @title: curl --remote-time copies the server Last-Modified onto the saved local file
# @description: Hosts a file with a fixed mtime via python http.server, fetches it with curl --remote-time, and asserts the saved file's mtime epoch matches the source file's mtime epoch (within a 1-second tolerance) so the Last-Modified header is being honored.
# @timeout: 180
# @tags: usage, curl, http, remote-time
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
printf 'r14 remote-time payload\n' >"$tmpdir/srv/f.txt"
touch -d '2020-01-15T10:30:00Z' "$tmpdir/srv/f.txt"
src_epoch=$(stat -c '%Y' "$tmpdir/srv/f.txt")

port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

curl --noproxy '*' -fsS --max-time 5 --remote-time \
    -o "$tmpdir/got.txt" "http://127.0.0.1:$port/f.txt"
validator_require_file "$tmpdir/got.txt"

dst_epoch=$(stat -c '%Y' "$tmpdir/got.txt")
diff_epoch=$(( dst_epoch > src_epoch ? dst_epoch - src_epoch : src_epoch - dst_epoch ))
[[ "$diff_epoch" -le 1 ]] || {
    printf 'expected --remote-time to copy mtime; src=%d dst=%d diff=%d\n' \
        "$src_epoch" "$dst_epoch" "$diff_epoch" >&2
    exit 1
}
