#!/usr/bin/env bash
# @testcase: usage-php83-r19-box-seal-open-roundtrip
# @title: PHP sodium_crypto_box_seal encrypts to a recipient pubkey and box_seal_open recovers plaintext
# @description: Generates a recipient sodium_crypto_box_keypair, encrypts a fixed payload with sodium_crypto_box_seal using only the recipient public key, asserts the sealed ciphertext length equals plaintext + SODIUM_CRYPTO_BOX_SEALBYTES (48), then calls sodium_crypto_box_seal_open with the full recipient keypair and asserts the recovered plaintext equals the original byte-for-byte.
# @timeout: 60
# @tags: usage, crypto, box, seal, php, r19
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$kp = sodium_crypto_box_keypair();
$pk = sodium_crypto_box_publickey($kp);
$msg = "r19 php sealed box payload";
$ct = sodium_crypto_box_seal($msg, $pk);
$expected = strlen($msg) + SODIUM_CRYPTO_BOX_SEALBYTES;
if (strlen($ct) !== $expected) {
    fwrite(STDERR, "ct_len=" . strlen($ct) . " expected=" . $expected . "\n");
    exit(1);
}
$pt = sodium_crypto_box_seal_open($ct, $kp);
if ($pt !== $msg) { fwrite(STDERR, "pt mismatch\n"); exit(1); }
echo "ok seal ct=", strlen($ct), " seal_overhead=", SODIUM_CRYPTO_BOX_SEALBYTES, PHP_EOL;
'
