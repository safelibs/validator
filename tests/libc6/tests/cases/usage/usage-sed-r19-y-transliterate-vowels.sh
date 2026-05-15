#!/usr/bin/env bash
# @testcase: usage-sed-r19-y-transliterate-vowels
# @title: sed y/// transliterates lowercase vowels to digits
# @description: Pipes the string "hello world" into sed y/aeiou/12345/, and asserts the captured output equals "h2ll4 w4rld" - locking in libc-backed character-class transliteration via sed.
# @timeout: 30
# @tags: usage, sed, transliterate, r19
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

got=$(printf 'hello world\n' | sed 'y/aeiou/12345/')
[[ "$got" == "h2ll4 w4rld" ]] || {
    printf 'expected "h2ll4 w4rld", got %q\n' "$got" >&2
    exit 1
}
