#!/usr/bin/env bash
# @testcase: usage-grep-r16-pcre-lookbehind-match
# @title: grep -P with a positive lookbehind matches only after the prefix
# @description: Feeds a small fixture into grep -P with the regex (?<=foo-)\\d+ and asserts only the digits following the "foo-" prefix are matched, not bare digits — locking in the PCRE lookbehind support shipping with libpcre-linked grep on Ubuntu 24.04.
# @timeout: 30
# @tags: usage, grep, pcre, lookbehind
# @client: grep

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'TXT'
foo-123 alpha
bar-456 beta
foo-789 gamma
no-prefix-100 here
TXT

grep -oP '(?<=foo-)\d+' "$tmpdir/in.txt" >"$tmpdir/hits"

mapfile -t lines <"$tmpdir/hits"
[[ "${#lines[@]}" -eq 2 ]] || {
    printf 'expected 2 matches, got %s\n' "${#lines[@]}" >&2
    cat "$tmpdir/hits" >&2
    exit 1
}
[[ "${lines[0]}" == "123" ]]
[[ "${lines[1]}" == "789" ]]
