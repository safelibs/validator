#!/usr/bin/env bash
# @testcase: usage-curl-r15-no-clobber-keeps-existing
# @title: curl --no-clobber keeps an existing -o target intact and writes the download to a sibling .1 path
# @description: Pre-creates a destination file, runs curl --no-clobber -o <existing> against a loopback server, and asserts the original file is left byte-for-byte intact while the downloaded body lands at <existing>.1, demonstrating curl's collision-avoidance rename behavior.
# @timeout: 180
# @tags: usage, curl, http, no-clobber
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
printf 'r15 no-clobber server body\n' >"$tmpdir/srv/payload.txt"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

dst="$tmpdir/existing.txt"
printf 'r15 pre-existing local body\n' >"$dst"
pre_sum=$(sha256sum "$dst" | awk '{print $1}')

curl --noproxy '*' -fsS --max-time 5 --no-clobber \
    -o "$dst" "http://127.0.0.1:$port/payload.txt"

# Existing target must NOT be overwritten.
[[ "$pre_sum" == "$(sha256sum "$dst" | awk '{print $1}')" ]] || {
    printf 'no-clobber should not overwrite existing %s\n' "$dst" >&2
    exit 1
}

# Body should have landed at <existing>.1
validator_require_file "$dst.1"
diff -q "$tmpdir/srv/payload.txt" "$dst.1"
