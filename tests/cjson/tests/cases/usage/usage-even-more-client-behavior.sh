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

  local port=$((28000 + RANDOM % 8000))
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
  jq -e "$jq_expr" "$tmpdir/client.json"
}

case "$case_id" in
  usage-iperf3-json-version-field)
    run_iperf_json_check '(.start.version | type) == "string" and (.start.version | length) > 0' -n 32K
    ;;
  usage-iperf3-json-system-info-field)
    run_iperf_json_check '(.start.system_info | type) == "string" and (.start.system_info | length) > 0' -n 32K
    ;;
  usage-iperf3-json-cookie-field)
    run_iperf_json_check '(.start.cookie | type) == "string" and (.start.cookie | length) > 0' -n 32K
    ;;
  usage-iperf3-json-timestamp-field)
    run_iperf_json_check '.start.timestamp.timesecs > 0' -n 32K
    ;;
  usage-iperf3-json-connected-count)
    run_iperf_json_check '(.start.connected | length) == 1' -n 32K
    ;;
  usage-iperf3-json-local-port-field)
    run_iperf_json_check '.start.connected[0].local_port > 0' -n 32K
    ;;
  usage-iperf3-json-remote-port-field)
    run_iperf_json_check '.start.connected[0].remote_port > 0' -n 32K
    ;;
  usage-iperf3-json-bytes-field)
    run_iperf_json_check '(.start.test_start.bytes // 0) == 16384' -n 16K
    ;;
  usage-iperf3-json-reverse-flag-field)
    run_iperf_json_check '(.start.test_start.reverse | tostring) != "0"' -R -n 16K
    ;;
  usage-iperf3-json-tos-flag-field)
    run_iperf_json_check '(.start.test_start.tos // 0) == 16' -S 0x10 -n 16K
    ;;
  *)
    printf 'unknown cjson even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
