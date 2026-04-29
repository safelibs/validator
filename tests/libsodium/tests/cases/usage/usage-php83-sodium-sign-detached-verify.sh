#!/usr/bin/env bash
# @testcase: usage-php83-sodium-sign-detached-verify
# @title: PHP sodium detached sign verify
# @description: Exercises php sodium detached sign verify through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-sign-detached-verify"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$pair = sodium_crypto_sign_keypair();
$secret = sodium_crypto_sign_secretkey($pair);
$public = sodium_crypto_sign_publickey($pair);
$sig = sodium_crypto_sign_detached('signed payload', $secret);
if (!sodium_crypto_sign_verify_detached($sig, 'signed payload', $public)) { exit(1); }
echo strlen($sig), PHP_EOL;
PHP
