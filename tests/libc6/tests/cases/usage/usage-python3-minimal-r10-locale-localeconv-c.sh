#!/usr/bin/env bash
# @testcase: usage-python3-minimal-r10-locale-localeconv-c
# @title: Python locale.localeconv() under LC_ALL=C reports POSIX defaults
# @description: Sets LC_ALL=C and queries Python's locale.localeconv() for the decimal point and thousands separator, verifying they equal the POSIX libc localeconv values (dot and empty string).
# @timeout: 180
# @tags: usage, python, locale
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

LC_ALL=C python3 >"$tmpdir/out.txt" <<'PYCASE'
import locale
locale.setlocale(locale.LC_ALL, "C")
lc = locale.localeconv()
print(repr(lc["decimal_point"]))
print(repr(lc["thousands_sep"]))
PYCASE

LC_ALL=C cat >"$tmpdir/want.txt" <<'EOF'
'.'
''
EOF

diff -u "$tmpdir/want.txt" "$tmpdir/out.txt"
