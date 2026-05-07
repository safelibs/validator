#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzgrep-h-no-prefix-multifile
# @title: bzgrep -h with two .bz2 inputs strips the filename prefix from every match line
# @description: Builds two .bz2 archives each containing a matching pattern, runs "bzgrep -h apple file1.bz2 file2.bz2", and asserts the output contains exactly two lines (one per match), neither of which contains a filename prefix or colon — confirming -h suppresses the per-line filename header that bzgrep would otherwise add when given multiple inputs. Distinct from r12-bzgrep-h-no-prefix which uses a single file.
# @timeout: 60
# @tags: usage, bzgrep, no-filename, multi-file
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple alpha\nbanana\n' >"$tmpdir/a.txt"
printf 'cherry\napple beta\n'   >"$tmpdir/b.txt"

bzip2 "$tmpdir/a.txt" "$tmpdir/b.txt"

bzgrep -h apple "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out.txt"

# Exactly two output lines.
[[ "$(wc -l <"$tmpdir/out.txt")" == "2" ]]

# No line contains either of the input filenames or a leading filename:colon prefix.
! grep -F "$tmpdir/a.txt.bz2" "$tmpdir/out.txt" >/dev/null
! grep -F "$tmpdir/b.txt.bz2" "$tmpdir/out.txt" >/dev/null
! grep -E '^[^ ]+\.bz2:' "$tmpdir/out.txt" >/dev/null

# But the two match lines themselves are present.
grep -Fxq 'apple alpha' "$tmpdir/out.txt"
grep -Fxq 'apple beta'  "$tmpdir/out.txt"
