#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload=${1:?missing iperf3 workload}
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
client_args=(-c 127.0.0.1 -p "$port" -J)
needle='"end"'

case "$workload" in
    tcp-throughput)
        client_args+=(-t 1)
        needle='"sum_received"'
        ;;
    reverse-throughput)
        client_args+=(-t 1 -R)
        needle='"sum_sent"'
        ;;
    udp-throughput)
        client_args+=(-u -b 64K -t 1)
        needle='"sum"'
        ;;
    fixed-bytes)
        client_args+=(-n 32K)
        needle='"bytes"'
        ;;
    parallel-streams)
        client_args+=(-P 2 -t 1)
        needle='"streams"'
        ;;
    interval-report)
        client_args+=(-i 0.5 -t 1)
        needle='"intervals"'
        ;;
    bidirectional)
        client_args+=(--bidir -t 1)
        needle='"sum_sent"'
        ;;
    server-output)
        client_args+=(--get-server-output -t 1)
        needle='"server_output'
        ;;
    zero-copy)
        client_args+=(-Z -n 32K)
        needle='"sum_sent"'
        ;;
    omit-warmup)
        client_args+=(-O 1 -t 2 -i 1)
        needle='"intervals"'
        ;;
    *)
        printf 'unknown iperf3 workload: %s\n' "$workload" >&2
        exit 2
        ;;
esac

iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 20); do
    if iperf3 "${client_args[@]}" >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
        ok=1
        break
    fi
    sleep 0.2
done

wait "$pid"
pid=""

if [[ "$ok" != 1 ]]; then
    sed -n '1,80p' "$tmpdir/client.err" >&2
    sed -n '1,80p' "$tmpdir/server.log" >&2
    exit 1
fi

validator_assert_contains "$tmpdir/client.json" "$needle"
validator_assert_contains "$tmpdir/client.json" '"bits_per_second"'
case "$workload" in
    zero-copy)
        jq -e '.end.sum_sent.bytes > 0 and .end.sum_sent.bits_per_second > 0' "$tmpdir/client.json"
        ;;
    omit-warmup)
        jq -e '
          (.intervals | length) > 0
          and any(.intervals[]; (.sum.omitted == true) or any(.streams[]?; .omitted == true))
          and (.end | type == "object")
        ' "$tmpdir/client.json"
        ;;
esac
jq -r '.end | keys | join(",")' "$tmpdir/client.json"
