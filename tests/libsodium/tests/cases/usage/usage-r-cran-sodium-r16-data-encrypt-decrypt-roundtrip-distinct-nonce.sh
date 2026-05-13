#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r16-data-encrypt-decrypt-roundtrip-distinct-nonce
# @title: r-cran-sodium data_encrypt then data_decrypt recovers a fixed payload under a 24-byte nonce
# @description: Encrypts a fixed message with sodium::data_encrypt under a 32-byte key and a 24-byte nonce, asserts the ciphertext is exactly plaintext-length plus 16 bytes (Poly1305 MAC), decrypts via sodium::data_decrypt and asserts the recovered raw vector equals the original message bytes.
# @timeout: 60
# @tags: usage, crypto, data-encrypt, r, r16
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
msg <- charToRaw("r16 r-cran-sodium data_encrypt payload")
key <- as.raw(rep(0x16, 32))
nonce <- as.raw(rep(0x21, 24))
ct <- data_encrypt(msg, key, nonce)
stopifnot(is.raw(ct))
stopifnot(length(ct) == length(msg) + 16)
pt <- data_decrypt(ct, key, nonce)
stopifnot(is.raw(pt))
stopifnot(identical(pt, msg))
cat("ok ct=", length(ct), "\n", sep="")
'
