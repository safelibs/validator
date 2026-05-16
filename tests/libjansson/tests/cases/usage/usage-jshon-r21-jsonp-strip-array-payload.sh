#!/usr/bin/env bash
# @testcase: usage-jshon-r21-jsonp-strip-array-payload
# @title: jshon -P strips jsonp wrapper around an array and -e extracts the second element
# @description: Wraps a JSON array of three strings inside a "callback(...)" jsonp envelope, pipes it through jshon -P -e 1 -u, and asserts the captured output equals exactly "middle" - locking in libjansson's parser invocation after jshon's jsonp-strip pass when the inner payload is an array (the existing r11 jsonp test only covered an object payload).
# @timeout: 30
# @tags: usage, json, cli, jsonp, array, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'cb(["first","middle","last"])' >"$tmpdir/in.jsonp"
got=$(jshon -P -e 1 -u <"$tmpdir/in.jsonp")
[[ "$got" == "middle" ]] || {
    printf 'expected "middle", got %q\n' "$got" >&2
    exit 1
}
