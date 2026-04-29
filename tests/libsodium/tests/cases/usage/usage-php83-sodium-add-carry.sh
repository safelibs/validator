#!/usr/bin/env bash
# @testcase: usage-php83-sodium-add-carry
# @title: PHP sodium add carry
# @description: Adds little-endian counters with PHP sodium_add and verifies that carry propagation updates the next byte.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-add-carry"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$value = "\xff\x00" . str_repeat("\x00", 6);
$delta = "\x01" . str_repeat("\x00", 7);
sodium_add($value, $delta);
if (ord($value[0]) !== 0 || ord($value[1]) !== 1) { exit(1); }
echo ord($value[0]), ':', ord($value[1]), PHP_EOL;
PHP
