#!/usr/bin/env bash
# @testcase: usage-gzip-r14-no-name-flag-strips-orig
# @title: gzip -n clears the FNAME header bit while default preserves it
# @description: Compresses two copies of the same payload — one with gzip -n (suppress name+mtime) and one with default flags (which preserves the FNAME) — and asserts byte 3 (flag byte) of each .gz header has the FNAME bit (0x08) cleared in the -n archive and set in the default archive.
# @timeout: 60
# @tags: usage, gzip, header, no-name
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"
printf 'r14 gzip no-name payload\n' >payload-noname.txt
printf 'r14 gzip default-name payload\n' >payload-default.txt

LC_ALL=C gzip -n payload-noname.txt
LC_ALL=C gzip   payload-default.txt
[[ -s payload-noname.txt.gz ]]
[[ -s payload-default.txt.gz ]]

# Read flag byte (offset 3) of each .gz header and check FNAME bit (0x08).
flag_no=$(LC_ALL=C dd if="$tmpdir/payload-noname.txt.gz"  bs=1 skip=3 count=1 status=none \
          | LC_ALL=C od -An -tu1 | LC_ALL=C tr -d ' ')
flag_def=$(LC_ALL=C dd if="$tmpdir/payload-default.txt.gz" bs=1 skip=3 count=1 status=none \
           | LC_ALL=C od -An -tu1 | LC_ALL=C tr -d ' ')

# FNAME bit (0x08) must be CLEARED with -n.
if (( (flag_no & 0x08) != 0 )); then
  printf '-n archive unexpectedly has FNAME bit set: flag=%s\n' "$flag_no" >&2
  exit 1
fi

# FNAME bit must be SET on the default archive.
if (( (flag_def & 0x08) == 0 )); then
  printf 'default archive missing FNAME bit: flag=%s\n' "$flag_def" >&2
  exit 1
fi
