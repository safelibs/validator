#!/usr/bin/env bash
# @testcase: usage-php83-sodium-add
# @title: PHP sodium add
# @description: Adds two little-endian counters with PHP sodium_add and verifies the resulting counter byte value.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-add"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$value = str_repeat("\x00", 8);
$delta = "\x02" . str_repeat("\x00", 7);
sodium_add($value, $delta);
if (ord($value[0]) !== 2) { exit(1); }
echo ord($value[0]), PHP_EOL;
PHP
