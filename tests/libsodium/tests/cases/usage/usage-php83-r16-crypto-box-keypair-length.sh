#!/usr/bin/env bash
# @testcase: usage-php83-r16-crypto-box-keypair-length
# @title: PHP sodium_crypto_box_keypair produces a 64-byte keypair split into 32-byte halves
# @description: Calls sodium_crypto_box_keypair, asserts the concatenated keypair is exactly SODIUM_CRYPTO_BOX_KEYPAIRBYTES (64) bytes, extracts the secret and public halves using sodium_crypto_box_secretkey and sodium_crypto_box_publickey, asserts each half is 32 bytes and the two halves differ.
# @timeout: 60
# @tags: usage, crypto, box, keypair, php, r16
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$kp = sodium_crypto_box_keypair();
if (!is_string($kp)) { fwrite(STDERR, "kp not string\n"); exit(1); }
if (strlen($kp) !== SODIUM_CRYPTO_BOX_KEYPAIRBYTES) {
    fwrite(STDERR, "kp len=" . strlen($kp) . "\n"); exit(1);
}
$sk = sodium_crypto_box_secretkey($kp);
$pk = sodium_crypto_box_publickey($kp);
if (strlen($sk) !== 32) { fwrite(STDERR, "sk len=" . strlen($sk) . "\n"); exit(1); }
if (strlen($pk) !== 32) { fwrite(STDERR, "pk len=" . strlen($pk) . "\n"); exit(1); }
if ($sk === $pk) { fwrite(STDERR, "sk==pk\n"); exit(1); }
echo "ok ", strlen($kp), PHP_EOL;
'
