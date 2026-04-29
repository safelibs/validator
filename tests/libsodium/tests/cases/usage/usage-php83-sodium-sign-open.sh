#!/usr/bin/env bash
# @testcase: usage-php83-sodium-sign-open
# @title: PHP sodium sign open
# @description: Signs a message with PHP sodium and opens the signed message with the matching public key.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-sign-open"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$keypair = sodium_crypto_sign_keypair();
$signed = sodium_crypto_sign('signed payload', sodium_crypto_sign_secretkey($keypair));
$plain = sodium_crypto_sign_open($signed, sodium_crypto_sign_publickey($keypair));
if ($plain !== 'signed payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
