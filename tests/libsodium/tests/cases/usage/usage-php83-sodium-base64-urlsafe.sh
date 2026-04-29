#!/usr/bin/env bash
# @testcase: usage-php83-sodium-base64-urlsafe
# @title: PHP sodium base64 urlsafe
# @description: Exercises php sodium base64 urlsafe through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-base64-urlsafe"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$encoded = sodium_bin2base64("payload\xff", SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING);
$decoded = sodium_base642bin($encoded, SODIUM_BASE64_VARIANT_URLSAFE_NO_PADDING);
if ($decoded !== "payload\xff") { exit(1); }
echo $encoded, PHP_EOL;
PHP
