#!/usr/bin/env bash
# @testcase: usage-curl-r9-output-dir-with-create
# @title: curl --output-dir with --create-dirs
# @description: Downloads a payload into a deeply nested output directory using --output-dir and --create-dirs and verifies curl created the directory tree.
# @timeout: 180
# @tags: usage, curl, http, files
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
printf 'hello-output-dir\n' >"$tmpdir/srv/file.txt"
port=$((26000 + RANDOM % 8000))
( cd "$tmpdir/srv" && python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 50); do
  curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/file.txt" 2>/dev/null && break
  sleep 0.1
done

dest="$tmpdir/dl/level1/level2/level3"
[[ ! -e "$dest" ]]
curl -fsS --max-time 5 --create-dirs --output-dir "$dest" -O "http://127.0.0.1:$port/file.txt"
validator_require_file "$dest/file.txt"
validator_assert_contains "$dest/file.txt" 'hello-output-dir'
