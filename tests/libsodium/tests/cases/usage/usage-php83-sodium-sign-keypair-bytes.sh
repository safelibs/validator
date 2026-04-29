#!/usr/bin/env bash
# @testcase: usage-php83-sodium-sign-keypair-bytes
# @title: php83 sodium sign keypair bytes
# @description: Generates a sign keypair through PHP sodium_crypto_sign_keypair and verifies the buffer length matches the KEYPAIRBYTES constant.
# @timeout: 180
# @tags: usage, php, sign
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-sign-keypair-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$pair = sodium_crypto_sign_keypair();
if (strlen($pair) !== SODIUM_CRYPTO_SIGN_KEYPAIRBYTES) { exit(1); }
echo strlen($pair), PHP_EOL;
PHP
