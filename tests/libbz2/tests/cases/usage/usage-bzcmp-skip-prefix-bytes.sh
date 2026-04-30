#!/usr/bin/env bash
# @testcase: usage-bzcmp-skip-prefix-bytes
# @title: bzcmp -i skips a leading byte run
# @description: Builds a payload whose compressed copy differs from the same payload prepended with a fixed prefix, and verifies bzcmp -i N on the matching prefix length reports the streams as equal.
# @timeout: 180
# @tags: usage, bzcmp, skip
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcmp-skip-prefix-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 8-byte prefix that only appears on the second payload.
prefix='PREFIX!!'
printf '%s' 'tail bytes shared by both inputs\n' >"$tmpdir/base.txt"
printf '%s%s' "$prefix" 'tail bytes shared by both inputs\n' >"$tmpdir/prefixed.txt"

bzip2 -c "$tmpdir/base.txt" >"$tmpdir/base.bz2"
bzip2 -c "$tmpdir/prefixed.txt" >"$tmpdir/prefixed.bz2"

# Sanity: without skipping the streams must differ in their decompressed bytes.
set +e
bzcmp "$tmpdir/base.bz2" "$tmpdir/prefixed.bz2" >"$tmpdir/diff.out" 2>&1
rc_diff=$?
set -e
if (( rc_diff == 0 )); then
  printf 'bzcmp unexpectedly reported equality without -i\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/diff.out" 'differ'

# Skipping 8 bytes on the second file must align the tails and yield equality.
# bzcmp's argument splitter only recognises tokens beginning with '-' as
# options, so we must keep -i and its SKIP1:SKIP2 value glued into one token.
bzcmp "-i0:${#prefix}" "$tmpdir/base.bz2" "$tmpdir/prefixed.bz2" \
  >"$tmpdir/skip.out" 2>&1
[[ ! -s "$tmpdir/skip.out" ]] || {
  printf 'bzcmp -i emitted unexpected output\n' >&2
  sed -n '1,20p' "$tmpdir/skip.out" >&2
  exit 1
}
