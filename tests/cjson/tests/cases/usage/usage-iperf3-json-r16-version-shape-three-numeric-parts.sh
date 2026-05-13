#!/usr/bin/env bash
# @testcase: usage-iperf3-json-r16-version-shape-three-numeric-parts
# @title: iperf3 -J start.version splits into three numeric tokens after iperf prefix
# @description: Runs a 1-second loopback TCP transfer and asserts the cjson-serialised start.version string begins with the literal "iperf " and that the trailing version token splits on '.' into at least three components, each of which parses as a non-negative integer (exercising the canonical iperf3 version cookie shape on noble).
# @timeout: 180
# @tags: usage, json, tcp, version
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

port=$((23000 + RANDOM % 20000))
iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 20); do
    if iperf3 -c 127.0.0.1 -p "$port" -J -t 1 >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

[[ "$ok" == 1 ]] || { sed -n '1,80p' "$tmpdir/client.err" >&2; exit 1; }

version=$(jq -r '.start.version' "$tmpdir/client.json")
[[ "$version" == iperf\ * ]] || { printf 'unexpected version prefix: %s\n' "$version" >&2; exit 1; }
ver=${version#iperf }
# Strip optional trailing date suffix in parens
ver=${ver%% *}
IFS='.' read -r a b c _ <<<"$ver"
[[ "$a" =~ ^[0-9]+$ ]] || { printf 'major not integer: %s (full=%s)\n' "$a" "$version" >&2; exit 1; }
[[ "$b" =~ ^[0-9]+$ ]] || { printf 'minor not integer: %s (full=%s)\n' "$b" "$version" >&2; exit 1; }
[[ "$c" =~ ^[0-9]+$ ]] || { printf 'patch not integer: %s (full=%s)\n' "$c" "$version" >&2; exit 1; }
