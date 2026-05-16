#!/usr/bin/env bash
# @testcase: usage-python3-r21-urllib-parse-quote-rfc3986
# @title: python3 urllib.parse.quote escapes a space as "%20"
# @description: Invokes python3 -c with urllib.parse.quote on the string "a b" and asserts the result is exactly "a%20b" - locking in libc-backed percent-encoding through python's urllib module, distinct from existing python3 stdlib tests (json, csv, hashlib, struct, ipaddress, base85).
# @timeout: 30
# @tags: usage, python3, urllib, quote, r21
# @client: python3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(python3 -c 'from urllib.parse import quote; import sys; sys.stdout.write(quote("a b"))')
[[ "$got" == "a%20b" ]] || {
    printf 'expected "a%%20b", got %q\n' "$got" >&2
    exit 1
}
