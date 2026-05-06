#!/usr/bin/env bash
# @testcase: usage-curl-r11-write-out-fail-exitcode-22
# @title: curl --fail on a 404 sets %{exitcode} to 22 (CURLE_HTTP_RETURNED_ERROR)
# @description: Requests a missing path with --fail against a loopback server, captures stderr separately, and asserts the trailing %{exitcode} write-out token reports 22 even though stdout/stderr are split.
# @timeout: 180
# @tags: usage, curl, http, write-out, fail
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
printf 'fail-exit-target\n' >"$tmpdir/srv/exists.html"
port=$((29200 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/exists.html" 2>/dev/null && break
  sleep 0.1
done

set +e
got=$(curl -sS --max-time 5 --fail -o /dev/null \
            -w '%{exitcode}' \
            "http://127.0.0.1:$port/missing-on-purpose" 2>"$tmpdir/err")
ec=$?
set -e
[[ $ec -eq 22 ]] || {
  printf 'expected curl exit 22, got %d (stderr: %s)\n' "$ec" "$(tr -d "\n" <"$tmpdir/err")" >&2
  exit 1
}
[[ "$got" == "22" ]] || {
  printf 'expected %%{exitcode} 22, got %q\n' "$got" >&2
  exit 1
}
