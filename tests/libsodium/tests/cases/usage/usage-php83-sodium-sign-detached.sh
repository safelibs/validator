#!/usr/bin/env bash
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
