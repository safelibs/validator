#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch13-exclude-from-file
# @title: bsdtar -X exclude file with xz
# @description: Creates a tar.xz with bsdtar -X pointing at an exclude-pattern file and verifies excluded entries are absent while kept entries round-trip.
# @timeout: 180
# @tags: usage, archive, xz
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in" "$tmpdir/out"
printf 'keep alpha\n' >"$tmpdir/in/alpha.txt"
printf 'keep beta\n'  >"$tmpdir/in/beta.txt"
printf 'skip a\n'     >"$tmpdir/in/skip.tmp"
printf 'skip log\n'   >"$tmpdir/in/run.log"

# Pattern file with two distinct globs, one per line.
cat >"$tmpdir/excl.txt" <<'EOF'
*.tmp
*.log
EOF

bsdtar -X "$tmpdir/excl.txt" -cJf "$tmpdir/a.tar.xz" -C "$tmpdir/in" .

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/a.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/a.tar.xz" | LC_ALL=C sort >"$tmpdir/list.txt"

# Excluded entries must be absent
if grep -Fq 'skip.tmp' "$tmpdir/list.txt"; then exit 1; fi
if grep -Fq 'run.log'  "$tmpdir/list.txt"; then exit 1; fi

# Kept entries must each appear exactly once
test "$(grep -cFx './alpha.txt' "$tmpdir/list.txt")" = "1"
test "$(grep -cFx './beta.txt'  "$tmpdir/list.txt")" = "1"

# Round-trip the kept entries
bsdtar -xf "$tmpdir/a.tar.xz" -C "$tmpdir/out"
cmp "$tmpdir/in/alpha.txt" "$tmpdir/out/alpha.txt"
cmp "$tmpdir/in/beta.txt"  "$tmpdir/out/beta.txt"
test ! -e "$tmpdir/out/skip.tmp"
test ! -e "$tmpdir/out/run.log"
