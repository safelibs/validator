#!/usr/bin/env bash
# @testcase: usage-curl-r17-silent-vs-show-error
# @title: curl --silent suppresses progress and --show-error keeps error text on failure
# @description: Runs curl --silent against a deliberately unreachable port and confirms stderr is empty, then runs curl --silent --show-error against the same target and confirms stderr contains a recognizable error token — locking in the two-flag interaction.
# @timeout: 30
# @tags: usage, curl, silent, show-error
# @client: curl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

set +e
curl --noproxy '*' --silent --max-time 2 \
    "http://127.0.0.1:1/" >"$tmpdir/silent.out" 2>"$tmpdir/silent.err"
rc1=$?
curl --noproxy '*' --silent --show-error --max-time 2 \
    "http://127.0.0.1:1/" >"$tmpdir/show.out" 2>"$tmpdir/show.err"
rc2=$?
set -e

[[ "$rc1" -ne 0 ]] || { printf 'expected silent connect to fail, got 0\n' >&2; exit 1; }
[[ "$rc2" -ne 0 ]] || { printf 'expected show-error connect to fail, got 0\n' >&2; exit 1; }

silent_bytes=$(wc -c <"$tmpdir/silent.err")
[[ "$silent_bytes" -eq 0 ]] || {
    printf '--silent should produce empty stderr, got %s bytes\n' "$silent_bytes" >&2
    cat "$tmpdir/silent.err" >&2
    exit 1
}
show_bytes=$(wc -c <"$tmpdir/show.err")
[[ "$show_bytes" -gt 0 ]] || {
    printf '--show-error should emit error text on stderr\n' >&2
    exit 1
}
grep -Eiq 'curl|connect|refus' "$tmpdir/show.err" || {
    printf '--show-error stderr missing expected token\n' >&2
    cat "$tmpdir/show.err" >&2
    exit 1
}
