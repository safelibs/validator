#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r10-sha512-kat
# @title: r-cran-sodium sha512 matches a known-answer vector
# @description: Calls sodium::sha512 on the canonical "abc" test vector and asserts the resulting 64-byte raw digest matches the FIPS 180-4 SHA-512("abc") known-answer in hex form, then asserts the empty-input digest matches its standard known-answer.
# @timeout: 180
# @tags: usage, crypto, hash, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))

abc_hex <- "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
empty_hex <- "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"

d_abc <- sha512(charToRaw("abc"))
stopifnot(is.raw(d_abc))
stopifnot(length(d_abc) == 64L)
hex_abc <- bin2hex(d_abc)
if (hex_abc != abc_hex) {
    stop(sprintf("abc digest mismatch: got %s", hex_abc))
}

d_empty <- sha512(raw(0))
stopifnot(length(d_empty) == 64L)
hex_empty <- bin2hex(d_empty)
if (hex_empty != empty_hex) {
    stop(sprintf("empty digest mismatch: got %s", hex_empty))
}

cat("ok", nchar(hex_abc), "\n")
'
