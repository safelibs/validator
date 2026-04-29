#!/usr/bin/env bash
# @testcase: usage-php83-sodium-compare-hex2bin
# @title: PHP sodium compare hex to bin
# @description: Exercises php sodium compare hex to bin through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-compare-hex2bin"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$hex = sodium_bin2hex('payload');
$plain = sodium_hex2bin($hex);
if (sodium_compare($plain, 'payload') !== 0) { exit(1); }
echo $hex, PHP_EOL;
PHP
