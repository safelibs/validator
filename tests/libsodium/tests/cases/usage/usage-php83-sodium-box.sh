#!/usr/bin/env bash
# @testcase: usage-php83-sodium-box
# @title: PHP sodium public box
# @description: Encrypts and decrypts a message with PHP sodium public-key box helpers.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-php83-sodium-box"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

php <<'PHP'
<?php
$alice = sodium_crypto_box_keypair();
$bob = sodium_crypto_box_keypair();
$alice_to_bob = sodium_crypto_box_keypair_from_secretkey_and_publickey(sodium_crypto_box_secretkey($alice), sodium_crypto_box_publickey($bob));
$bob_from_alice = sodium_crypto_box_keypair_from_secretkey_and_publickey(sodium_crypto_box_secretkey($bob), sodium_crypto_box_publickey($alice));
$nonce = random_bytes(SODIUM_CRYPTO_BOX_NONCEBYTES);
$cipher = sodium_crypto_box('box payload', $nonce, $alice_to_bob);
$plain = sodium_crypto_box_open($cipher, $nonce, $bob_from_alice);
if ($plain !== 'box payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
