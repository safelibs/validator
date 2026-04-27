#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

run_iperf_json() {
  local port=$((25000 + RANDOM % 2000))
  iperf3 -s -1 -p "$port" >"$tmpdir/server.log" 2>&1 &
  pid=$!

  local ok=0
  for _ in $(seq 1 30); do
    if iperf3 -c 127.0.0.1 -p "$port" -J "$@" >"$tmpdir/client.json" 2>"$tmpdir/client.err"; then
      ok=1
      break
    fi
    sleep 0.2
  done

  wait "$pid"
  pid=""

  if [[ "$ok" != 1 ]]; then
    sed -n '1,120p' "$tmpdir/client.err" >&2
    sed -n '1,120p' "$tmpdir/server.log" >&2
    exit 1
  fi

  validator_assert_contains "$tmpdir/client.json" '"start"'
  validator_assert_contains "$tmpdir/client.json" '"end"'
}

case "$case_id" in
  usage-iperf3-json-end-cpu-host-total-field)
    run_iperf_json -n 64K
    jq -e '.end.cpu_utilization_percent.host_total >= 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-end-cpu-remote-total-field)
    run_iperf_json -n 64K
    jq -e '.end.cpu_utilization_percent.remote_total >= 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-end-sum-sent-bytes-positive)
    run_iperf_json -n 64K
    jq -e '.end.sum_sent.bytes >= 65536' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-end-sum-received-bytes-positive)
    run_iperf_json -n 64K
    jq -e '.end.sum_received.bytes > 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-end-streams-sender-bytes)
    run_iperf_json -n 64K
    jq -e '.end.streams[0].sender.bytes >= 65536' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-end-streams-receiver-bytes)
    run_iperf_json -n 64K
    jq -e '.end.streams[0].receiver.bytes > 0' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-bytes-1m-fixed-field)
    run_iperf_json -n 1M
    jq -e '.start.test_start.bytes == 1048576' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-format-megabytes-flag)
    run_iperf_json -f M -n 64K
    jq -e '.start.test_start.protocol == "TCP"' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-length-2k-blksize)
    run_iperf_json -l 2K -n 32K
    jq -e '.start.test_start.blksize == 2048' "$tmpdir/client.json"
    ;;
  usage-iperf3-json-blockcount-three-blocks)
    run_iperf_json -k 3 -l 16K
    jq -e '.start.test_start.blocks == 3' "$tmpdir/client.json"
    ;;
  *)
    printf 'unknown cjson tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
