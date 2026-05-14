#!/usr/bin/env bash
# @testcase: usage-curl-r17-create-dirs-nested-output
# @title: curl --create-dirs --output writes through a not-yet-existing directory tree
# @description: Stands up a python http.server serving a small file, then invokes curl --create-dirs --output with a target path under multiple non-existent parent directories and asserts the nested file exists with the expected content.
# @timeout: 90
# @tags: usage, curl, create-dirs
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

mkdir -p "$tmpdir/wwwroot"
printf 'r17-create-dirs-body\n' >"$tmpdir/wwwroot/payload.txt"

port=$((24700 + RANDOM % 18000))
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir/wwwroot" >/dev/null 2>&1 &
pid=$!
ready=0
for _ in $(seq 1 60); do
    if curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/payload.txt" 2>/dev/null; then
        ready=1
        break
    fi
    sleep 0.1
done
[[ "$ready" -eq 1 ]] || { printf 'server never became ready\n' >&2; exit 1; }

target="$tmpdir/nested/a/b/c/out.txt"
[[ ! -d "$tmpdir/nested" ]] || { printf 'expected nested dir to be absent before request\n' >&2; exit 1; }

curl --noproxy '*' -fsS --max-time 5 \
    --create-dirs --output "$target" \
    "http://127.0.0.1:$port/payload.txt"

[[ -f "$target" ]] || {
    printf 'expected nested output file at %s\n' "$target" >&2
    exit 1
}
diff -q "$tmpdir/wwwroot/payload.txt" "$target"
