#!/usr/bin/env bash
# @testcase: usage-curl-r15-write-out-time-namelookup
# @title: curl --write-out '%{time_namelookup}' reports a non-negative seconds.fraction value
# @description: Runs a curl GET against a loopback HTTP server with --write-out '%{time_namelookup}' and asserts the captured value is a fixed-point number with a fractional part (matches "<int>.<digits>") and is greater than or equal to zero. Pins the time_namelookup writeout token's numeric format.
# @timeout: 180
# @tags: usage, curl, http, write-out, time
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
printf 'r15 time_namelookup body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

t=$(curl --noproxy '*' -fsS --max-time 5 \
    -o /dev/null -w '%{time_namelookup}' \
    "http://127.0.0.1:$port/payload.txt")
[[ "$t" =~ ^[0-9]+\.[0-9]+$ ]] || {
    printf 'expected fixed-point time_namelookup, got %q\n' "$t" >&2
    exit 1
}

# Compare numerically as a non-negative real (allow leading zeros).
python3 - "$t" <<'PY'
import sys
v = float(sys.argv[1])
assert v >= 0.0, f"expected time_namelookup >= 0, got {v}"
PY
