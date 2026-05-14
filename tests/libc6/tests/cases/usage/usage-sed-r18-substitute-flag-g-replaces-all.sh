#!/usr/bin/env bash
# @testcase: usage-sed-r18-substitute-flag-g-replaces-all
# @title: sed s/foo/bar/g replaces every occurrence on a line
# @description: Pipes a single-line input "foo foo foo" through sed with the s/foo/bar/g substitution and asserts the captured output equals "bar bar bar" — locking in libc-backed regex global-replace in noble's sed build.
# @timeout: 30
# @tags: usage, sed, substitute, global, r18
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(printf 'foo foo foo\n' | sed 's/foo/bar/g')
[[ "$got" == "bar bar bar" ]] || {
    printf 'expected "bar bar bar", got %q\n' "$got" >&2
    exit 1
}
