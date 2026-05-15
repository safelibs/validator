#!/usr/bin/env bash
# @testcase: usage-sed-r20-substitute-anchored-end
# @title: sed s/foo$/bar/ replaces only end-of-line matches
# @description: Pipes a three-line input where only one line ends with "foo" through sed 's/foo$/bar/', then asserts the recovered output contains "bar" exactly where the anchored match fired and leaves a non-terminal "foo" untouched - locking in libc-backed end-of-line anchor semantics through sed.
# @timeout: 30
# @tags: usage, sed, anchor, end-of-line, r20
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
foo
afoo
foofoo
EOF

sed 's/foo$/bar/' "$tmpdir/in.txt" >"$tmpdir/out"

# Line 1 "foo" -> "bar".
[[ "$(sed -n '1p' "$tmpdir/out")" == "bar" ]] || {
    printf 'line 1 wrong: %s\n' "$(sed -n '1p' "$tmpdir/out")" >&2
    exit 1
}
# Line 2 "afoo" -> "abar".
[[ "$(sed -n '2p' "$tmpdir/out")" == "abar" ]] || {
    printf 'line 2 wrong: %s\n' "$(sed -n '2p' "$tmpdir/out")" >&2
    exit 1
}
# Line 3 "foofoo" -> "foobar" (only end-of-line foo replaced).
[[ "$(sed -n '3p' "$tmpdir/out")" == "foobar" ]] || {
    printf 'line 3 wrong: %s\n' "$(sed -n '3p' "$tmpdir/out")" >&2
    exit 1
}
