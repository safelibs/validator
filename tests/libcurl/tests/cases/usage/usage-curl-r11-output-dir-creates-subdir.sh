#!/usr/bin/env bash
# @testcase: usage-curl-r11-output-dir-creates-subdir
# @title: curl --output-dir + --create-dirs writes into a fresh subdirectory
# @description: Combines --output-dir <fresh path> with --create-dirs and verifies curl creates the missing directory tree and writes the response body into it.
# @timeout: 180
# @tags: usage, curl, http, output-dir
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
printf 'output-dir-target\n' >"$tmpdir/srv/payload.txt"
port=$((28900 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/payload.txt" 2>/dev/null && break
  sleep 0.1
done

target="$tmpdir/dl/sub/leaf"
[[ ! -d "$target" ]] || { echo "fixture leaked: $target already exists" >&2; exit 1; }

curl -sS --max-time 5 --output-dir "$target" --create-dirs -o saved.txt "http://127.0.0.1:$port/payload.txt"

[[ -d "$target" ]] || { echo "expected curl to create directory $target" >&2; exit 1; }
[[ -s "$target/saved.txt" ]] || { echo "expected non-empty $target/saved.txt" >&2; exit 1; }
diff -q "$tmpdir/srv/payload.txt" "$target/saved.txt"
