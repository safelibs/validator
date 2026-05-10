#!/usr/bin/env bash
# @testcase: usage-php83-sodium-sub-batch12
# @title: PHP sodium_increment modular addition wraps at 2**128
# @description: Calls sodium_increment on three 16-byte little-endian counter shapes and asserts the documented modular arithmetic invariants: 0xff..ff + 1 wraps to all-zero, (0x00,0x01)+1 advances the low byte without carry, and (0xff,0x00)+1 propagates the carry into the second byte. (PHP 8.3 on noble does not expose sodium_sub; sodium_increment exercises the same little-endian mod 2**128 surface.)
# @timeout: 60
# @tags: usage, crypto, arithmetic, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php <<'PHP'
<?php
// 1) 0xff..ff + 1 wraps to all-zero.
$max = str_repeat("\xff", 16);
sodium_increment($max);
$zero = str_repeat("\x00", 16);
if ($max !== $zero) {
    fwrite(STDERR, "wrap-around mismatch: " . bin2hex($max) . "\n"); exit(1);
}
// 2) (0x00, 0x01) + 1 advances the low byte to 0x01 with no carry.
$x = "\x00\x01" . str_repeat("\x00", 14);
sodium_increment($x);
$want = "\x01\x01" . str_repeat("\x00", 14);
if ($x !== $want) {
    fwrite(STDERR, "advance mismatch: " . bin2hex($x) . "\n"); exit(1);
}
// 3) Low byte carry: (0xff, 0x00) + 1 == (0x00, 0x01).
$c = "\xff\x00" . str_repeat("\x00", 14);
sodium_increment($c);
$want2 = "\x00\x01" . str_repeat("\x00", 14);
if ($c !== $want2) {
    fwrite(STDERR, "carry mismatch: " . bin2hex($c) . "\n"); exit(1);
}
echo "ok\n";
PHP
