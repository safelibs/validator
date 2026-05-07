#!/usr/bin/env bash
# @testcase: usage-findutils-r14-execdir-basename
# @title: findutils find -execdir runs the helper from the matched file's directory
# @description: Builds a two-level directory tree containing files in the inner subdirectory, runs find with -execdir printf '%s\n' {} \; on .txt members under LC_ALL=C, and asserts the captured arguments are bare './'-prefixed basenames (proof that -execdir changed cwd to the parent of each match before invoking the helper).
# @timeout: 60
# @tags: usage, findutils, execdir
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/root/sub"
: >"$tmpdir/root/sub/alpha.txt"
: >"$tmpdir/root/sub/beta.txt"
: >"$tmpdir/root/other.log"

# -execdir invokes the command from the directory containing the match,
# and supplies the match as './name'.
LC_ALL=C find "$tmpdir/root" -name '*.txt' \
  -execdir printf '%s\n' {} \; \
  | LC_ALL=C sort >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
./alpha.txt
./beta.txt
EOF

cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"
