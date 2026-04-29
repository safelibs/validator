#!/usr/bin/env bash
# @testcase: usage-php83-sodium-hex-roundtrip
# @title: PHP sodium hex round trip
# @description: Encodes and decodes bytes through PHP sodium hexadecimal helpers and verifies the original payload returns intact.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-hex-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$hex = sodium_bin2hex("payload");
$plain = sodium_hex2bin($hex);
if ($plain !== "payload") { exit(1); }
echo $hex, PHP_EOL;
PHP
