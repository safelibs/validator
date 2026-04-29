#!/usr/bin/env bash
# @testcase: usage-php83-sodium-sign-detached
# @title: PHP sodium detached signatures
# @description: Signs a message with PHP sodium and verifies the detached signature through libsodium.
# @timeout: 180
# @tags: usage, crypto
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$message = 'detached signature payload';
$keypair = sodium_crypto_sign_keypair();
$secretKey = sodium_crypto_sign_secretkey($keypair);
$publicKey = sodium_crypto_sign_publickey($keypair);
$signature = sodium_crypto_sign_detached($message, $secretKey);

if (sodium_crypto_sign_verify_detached($signature, $message, $publicKey) !== true) {
    fwrite(STDERR, "detached signature verification failed\n");
    exit(1);
}

echo "verified\n";
PHP
