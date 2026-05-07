#!/usr/bin/env bash
# @testcase: usage-curl-r14-output-dir-with-remote-name
# @title: curl --output-dir combined with -O writes the URL leaf into the chosen directory
# @description: Combines curl --output-dir with -O (remote name) and asserts that the file is created at <output-dir>/<leaf> using the URL's last path segment as the filename, that the body matches the source byte-for-byte, and that the leaf is not created in the current working directory.
# @timeout: 180
# @tags: usage, curl, http, output-dir, remote-name
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
printf 'r14 output-dir + -O body\n' >"$tmpdir/srv/leaf.bin"
port=$((23000 + RANDOM % 19000))
( cd "$tmpdir/srv" && exec python3 -m http.server "$port" >/dev/null 2>&1 ) &
pid=$!
for _ in $(seq 1 60); do
    curl --noproxy '*' -fsS --max-time 2 -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null && break
    sleep 0.1
done

dst="$tmpdir/dl"
mkdir -p "$dst"
runcwd="$tmpdir/run"
mkdir -p "$runcwd"

( cd "$runcwd" && curl --noproxy '*' -fsS --max-time 5 \
    --output-dir "$dst" -O "http://127.0.0.1:$port/leaf.bin" )

validator_require_file "$dst/leaf.bin"
diff -q "$tmpdir/srv/leaf.bin" "$dst/leaf.bin"

# Must NOT have leaked the leaf into the cwd we ran from.
[[ ! -e "$runcwd/leaf.bin" ]] || {
    printf 'unexpected leaf.bin leaked into cwd %s\n' "$runcwd" >&2
    exit 1
}
