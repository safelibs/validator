#!/usr/bin/env bash
# @testcase: usage-php83-r21-sodium-memzero-clears-buffer
# @title: PHP sodium_memzero wipes a string variable so subsequent reads see an empty value
# @description: Allocates a 32-byte random buffer, asserts strlen 32 with some non-NUL byte, then calls sodium_memzero by reference and asserts the variable is now an empty string (strlen 0), confirming libsodium's secure-erase primitive surfaced via the PHP sodium extension destructively zeroes the buffer.
# @timeout: 30
# @tags: usage, sodium, memzero, php, r21
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$buf = random_bytes(32);
if (strlen($buf) !== 32) { fwrite(STDERR, "buf_len=".strlen($buf)."\n"); exit(1); }
$preNonZero = false;
for ($i = 0; $i < 32; $i++) { if (ord($buf[$i]) !== 0) { $preNonZero = true; break; } }
if (!$preNonZero) { fwrite(STDERR, "random returned all zeros\n"); exit(1); }
sodium_memzero($buf);
// PHP sodium_memzero wipes the backing buffer; the variable reads as NULL afterwards.
if (strlen($buf) !== 0) { fwrite(STDERR, "post len=".strlen($buf)."\n"); exit(1); }
if (!is_null($buf)) { fwrite(STDERR, "expected null got ".var_export($buf, true)."\n"); exit(1); }
echo "ok memzero buf_is_null=", (is_null($buf) ? "yes" : "no"), PHP_EOL;
'
