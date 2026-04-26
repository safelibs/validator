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

run_iperf_json_check() {
  local jq_expr=${1:?missing jq expression}
  shift

  local port=$((30000 + RANDOM % 5000))
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

  jq -e --argjson expected_port "$port" "$jq_expr" "$tmpdir/client.json"
}

case "$case_id" in
  usage-iperf3-json-title-field)
    run_iperf_json_check '.title == "validator-title"' -T validator-title -n 16K
    ;;
  usage-iperf3-json-extra-data-field)
    run_iperf_json_check '.extra_data == "validator-extra"' --extra-data validator-extra -n 16K
    ;;
  usage-iperf3-json-duration-field)
    run_iperf_json_check '.start.test_start.duration == 1' -t 1
    ;;
  usage-iperf3-json-udp-target-bitrate)
    run_iperf_json_check '(.start.test_start.target_bitrate // 0) > 0' -u -b 192K -t 1
    ;;
  usage-iperf3-json-end-stream-count)
    run_iperf_json_check '(.end.streams | length) == 2' -P 2 -n 32K
    ;;
  usage-iperf3-json-interval-sum-seconds)
    run_iperf_json_check '(.intervals[0].sum.seconds // 0) > 0' -t 1 -i 1
    ;;
  usage-iperf3-json-bytes-8k-fixed)
    run_iperf_json_check '(.start.test_start.bytes // 0) == 8192' -n 8K
    ;;
  usage-iperf3-json-reverse-received-bytes)
    run_iperf_json_check '(.end.sum_received.bytes // 0) >= 16384' -R -n 16K
    ;;
  usage-iperf3-json-udp-jitter-field)
    run_iperf_json_check '(.end.sum | has("jitter_ms")) and (.end.sum.jitter_ms >= 0)' -u -b 128K -t 1
    ;;
  usage-iperf3-json-port-match)
    run_iperf_json_check '.start.connected[0].remote_port == $expected_port' -n 16K
    ;;
  *)
    printf 'unknown cjson further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
