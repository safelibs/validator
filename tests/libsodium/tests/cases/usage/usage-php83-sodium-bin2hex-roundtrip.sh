#!/usr/bin/env bash
# @testcase: usage-php83-sodium-bin2hex-roundtrip
# @title: PHP sodium bin2hex roundtrip
# @description: Converts binary data to hex and back with PHP sodium helpers and verifies the restored payload bytes.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-bin2hex-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$hex = sodium_bin2hex("payload\x00");
$raw = sodium_hex2bin($hex);
if ($raw !== "payload\x00") { exit(1); }
echo $hex, PHP_EOL;
PHP
