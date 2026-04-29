#!/usr/bin/env bash
# @testcase: usage-php83-sodium-sign-publickey-from-secretkey
# @title: PHP sodium sign public key from secret key
# @description: Derives a signing public key from a PHP libsodium secret key and verifies it matches the public key already stored in the keypair.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-sign-publickey-from-secretkey"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$pair = sodium_crypto_sign_keypair();
$secret = sodium_crypto_sign_secretkey($pair);
$public = sodium_crypto_sign_publickey($pair);
$derived = sodium_crypto_sign_publickey_from_secretkey($secret);
if ($derived !== $public) { exit(1); }
echo strlen($derived), PHP_EOL;
PHP
