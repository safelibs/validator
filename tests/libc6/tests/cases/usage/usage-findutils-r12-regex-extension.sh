#!/usr/bin/env bash
# @testcase: usage-findutils-r12-regex-extension
# @title: findutils find -regex matches files by full path extension
# @description: Creates a directory of mixed extensions and uses find -regex with the emacs default regex type to select only .log files, asserting only the expected files are returned.
# @timeout: 60
# @tags: usage, findutils, regex
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/d"
: >"$tmpdir/d/alpha.log"
: >"$tmpdir/d/beta.log"
: >"$tmpdir/d/gamma.txt"
: >"$tmpdir/d/delta.md"

LC_ALL=C find "$tmpdir/d" -maxdepth 1 -type f -regex '.*\.log' -printf '%f\n' \
  | LC_ALL=C sort >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
alpha.log
beta.log
EOF

cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"
