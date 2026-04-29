#!/usr/bin/env bash
# @testcase: usage-php83-sodium-base64-roundtrip
# @title: PHP sodium base64 round trip
# @description: Encodes and decodes binary payload data with PHP sodium base64 helpers.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-base64-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$encoded = sodium_bin2base64("payload\x00", SODIUM_BASE64_VARIANT_ORIGINAL);
$decoded = sodium_base642bin($encoded, SODIUM_BASE64_VARIANT_ORIGINAL);
if ($decoded !== "payload\x00") { exit(1); }
echo $encoded, PHP_EOL;
PHP
