#!/usr/bin/env bash
# @testcase: usage-php83-sodium-auth-verify
# @title: PHP sodium auth verify
# @description: Computes and verifies a message authentication code with PHP sodium and confirms verification succeeds.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-auth-verify"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_AUTH_KEYBYTES);
$mac = sodium_crypto_auth('auth payload', $key);
if (!sodium_crypto_auth_verify($mac, 'auth payload', $key)) { exit(1); }
echo sodium_bin2hex($mac), PHP_EOL;
PHP
