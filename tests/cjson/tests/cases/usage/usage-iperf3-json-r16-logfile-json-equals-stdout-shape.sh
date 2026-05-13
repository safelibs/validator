#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r16-logfile-json-equals-stdout-shape
# @title: iperf3 -J --logfile emits the same top-level JSON keys as stdout
# @description: Runs a 1-second loopback TCP transfer twice, once with -J writing to stdout and once with -J --logfile writing to a file, and asserts both JSON outputs share the same top-level cjson key set (start, intervals, end), confirming the logfile sink preserves the serialised top-level shape.
# @timeout: 180
# @tags: usage, json, tcp, logfile
# @client: iperf3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
pid=""
cleanup() {
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi
    rm -rf "$tmpdir"
}
trap cleanup EXIT

run_once() {
    local label=$1
    shift
    local port=$((23000 + RANDOM % 20000))
    iperf3 -s -1 -p "$port" >"$tmpdir/server-$label.log" 2>&1 &
    pid=$!
    local ok=0
    for _ in $(seq 1 20); do
        if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 "$@" >"$tmpdir/client-$label.out" 2>"$tmpdir/client-$label.err"; then
            ok=1
            break
        fi
        sleep 0.2
    done
    wait "$pid"
    pid=""
    [[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client-$label.err" >&2; exit 1; }
}

run_once stdout
run_once logfile --logfile "$tmpdir/log.json"

validator_require_file "$tmpdir/log.json"
[[ -s "$tmpdir/log.json" ]] || { echo "logfile empty" >&2; exit 1; }

stdout_keys=$(jq -S 'keys' "$tmpdir/client-stdout.out")
logfile_keys=$(jq -S 'keys' "$tmpdir/log.json")

[[ "$stdout_keys" == "$logfile_keys" ]] || {
    printf 'top-level key drift:\n stdout=%s\n logfile=%s\n' "$stdout_keys" "$logfile_keys" >&2
    exit 1
}

jq -e '(.start | type == "object") and (.end | type == "object") and (.intervals | type == "array")' "$tmpdir/log.json"
