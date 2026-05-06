#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r11-data-encrypt-roundtrip
# @title: r-cran-sodium data_encrypt and data_decrypt round-trip a payload
# @description: Encrypts a binary payload with sodium::data_encrypt under a 32-byte key and 24-byte nonce, decrypts the resulting ciphertext back to the original bytes, and asserts that flipping a single byte of the ciphertext makes data_decrypt error out — exercising the secretbox-style authenticated encryption wrapper.
# @timeout: 180
# @tags: usage, crypto, hash, r, secretbox
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))

key   <- as.raw(rep(0x11, 32))
nonce <- as.raw(rep(0x22, 24))
msg   <- charToRaw("r-cran-sodium r11 data_encrypt payload")

ct <- data_encrypt(msg, key, nonce)
stopifnot(is.raw(ct))
stopifnot(length(ct) == length(msg) + 16L)
stopifnot(!identical(ct, msg))

pt <- data_decrypt(ct, key, nonce)
stopifnot(identical(pt, msg))

ct_bad <- ct
ct_bad[1] <- as.raw(bitwXor(as.integer(ct_bad[1]), 0x01L))
ok <- tryCatch({
    data_decrypt(ct_bad, key, nonce)
    FALSE
}, error = function(e) TRUE)
if (!ok) {
    stop("forged ciphertext was accepted")
}

cat("ok\n")
'
