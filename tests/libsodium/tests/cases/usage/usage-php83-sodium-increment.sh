#!/usr/bin/env bash
# @testcase: usage-php83-sodium-increment
# @title: PHP sodium increment
# @description: Exercises php sodium increment through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-increment"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$value = str_repeat("\x00", 8);
sodium_increment($value);
if (ord($value[0]) !== 1) { exit(1); }
echo ord($value[0]), PHP_EOL;
PHP
