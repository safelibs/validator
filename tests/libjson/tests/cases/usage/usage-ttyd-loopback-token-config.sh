#!/usr/bin/env bash
# @testcase: usage-ttyd-loopback-token-config
# @title: ttyd loopback token endpoint JSON
# @description: Starts ttyd with a credential and verifies the /token endpoint returns a JSON body whose token field is a string.
# @timeout: 180
# @tags: usage, ttyd, json
# @client: ttyd

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
ttyd -i 127.0.0.1 -p "$port" -c user:pw bash -lc 'printf hi' >"$tmpdir/ttyd.log" 2>&1 &
pid=$!

ready=0
for _ in $(seq 1 60); do
  if curl -fsS -u user:pw "http://127.0.0.1:$port/token" -o "$tmpdir/token.json" 2>/dev/null; then
    ready=1
    break
  fi
  sleep 0.25
done
[[ "$ready" == "1" ]] || { sed -n '1,80p' "$tmpdir/ttyd.log" >&2; exit 1; }

python3 - "$tmpdir/token.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
if "token" not in d or not isinstance(d["token"], str):
    raise SystemExit(f"unexpected token JSON: {d!r}")
PY
