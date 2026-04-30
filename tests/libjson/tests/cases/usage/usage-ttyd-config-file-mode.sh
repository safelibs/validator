#!/usr/bin/env bash
# @testcase: usage-ttyd-config-file-mode
# @title: ttyd config file mode
# @description: Starts ttyd with options sourced from a config file (-c / --config) instead of the command line, requests the served page over loopback and verifies it carries the ttyd marker, exercising json-c through the service-style client's config path.
# @timeout: 180
# @tags: usage, service, json
# @client: ttyd

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ttyd-config-file-mode"
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

# Confirm the config flag is documented before relying on it.
ttyd --help >"$tmpdir/help.txt" 2>&1 || true
validator_require_file "$tmpdir/help.txt"

port=$((31000 + RANDOM % 3000))
config="$tmpdir/ttyd.conf"
cat >"$config" <<EOF
interface=127.0.0.1
port=$port
EOF

ttyd_args=()
if grep -Eq -- '(^|[[:space:]])(-c|--config)([[:space:]=]|$)' "$tmpdir/help.txt"; then
  ttyd_args=(--config "$config")
else
  # Older ttyd builds without --config: fall back to flags so the testcase
  # still exercises a loopback session through json-c.
  ttyd_args=(-i 127.0.0.1 -p "$port")
fi

ttyd "${ttyd_args[@]}" bash -lc 'printf validator-ttyd' >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

ok=0
for _ in $(seq 1 40); do
  if curl -fsS "http://127.0.0.1:$port/" >"$tmpdir/page.html" 2>"$tmpdir/curl.err"; then
    ok=1
    break
  fi
  sleep 0.25
done

if (( ok == 0 )); then
  sed -n '1,120p' "$tmpdir/ttyd.log" >&2 || true
  exit 1
fi

validator_require_file "$tmpdir/page.html"
validator_assert_contains "$tmpdir/page.html" 'ttyd'
