#!/usr/bin/env bash
# @testcase: usage-php83-r17-sodium-compare-equal-vs-different
# @title: PHP sodium_compare returns 0 for equal buffers and -1/+1 for ordered different buffers
# @description: Constructs three equal-length 16-byte buffers (one zero, one one-greater, one one-less), asserts sodium_compare returns 0 for equal buffers, a negative integer when the left is smaller, and a positive integer when the left is larger, exercising libsodium's sodium_compare wrapper.
# @timeout: 60
# @tags: usage, crypto, compare, php, r17
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$a = str_repeat("\x00", 16);
$b = str_repeat("\x00", 16);
$c = str_repeat("\x00", 15) . "\x01";
$d = str_repeat("\x00", 15) . "\x00";

$eq = sodium_compare($a, $b);
$lt = sodium_compare($a, $c);
$gt = sodium_compare($c, $d);

if ($eq !== 0) { fwrite(STDERR, "eq=$eq\n"); exit(1); }
if ($lt >= 0)  { fwrite(STDERR, "lt=$lt\n"); exit(1); }
if ($gt <= 0)  { fwrite(STDERR, "gt=$gt\n"); exit(1); }
echo "ok eq=$eq lt=$lt gt=$gt", PHP_EOL;
'
