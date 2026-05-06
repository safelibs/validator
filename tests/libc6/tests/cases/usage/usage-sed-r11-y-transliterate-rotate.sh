#!/usr/bin/env bash
# @testcase: usage-sed-r11-y-transliterate-rotate
# @title: sed y transliteration command rotates ASCII letters by three positions
# @description: Uses the sed y/abc.../def.../ command to map a 6-character ASCII string and verifies each character is replaced with its 3-position rotation exercising sed character-class transliteration via libc string indexing.
# @timeout: 60
# @tags: usage, sed, transliterate
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
got=$(printf 'abcdef\n' | LC_ALL=C sed 'y/abcdef/defghi/')
[[ "$got" == "defghi" ]]
