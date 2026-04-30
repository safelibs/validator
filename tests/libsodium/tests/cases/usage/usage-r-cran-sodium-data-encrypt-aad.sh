#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-data-encrypt-aad
# @title: R sodium data_encrypt round-trip and tamper detection
# @description: Encrypts a payload with sodium::data_encrypt under fixed key and nonce, asserts the ciphertext length is plaintext + 16 (Poly1305 tag) and that data_decrypt recovers the plaintext exactly, then flips a ciphertext byte and confirms data_decrypt raises an authentication error rather than silently returning the corrupted plaintext.
# @timeout: 180
# @tags: usage, crypto, aead, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
key <- as.raw(rep(0x21, 32))
nonce <- as.raw(rep(0x42, 24))
msg <- charToRaw("r sodium aead payload")

ct <- data_encrypt(msg, key, nonce)
stopifnot(is.raw(ct))
stopifnot(length(ct) == length(msg) + 16)

pt <- data_decrypt(ct, key, nonce)
stopifnot(identical(pt, msg))

# Flip a ciphertext byte: decryption must raise rather than return.
tampered <- ct
tampered[1] <- as.raw(bitwXor(as.integer(tampered[1]), 0xFF))
stopifnot(!identical(tampered, ct))
ok_tampered <- tryCatch({ data_decrypt(tampered, key, nonce); TRUE },
                        error = function(e) FALSE)
stopifnot(!isTRUE(ok_tampered))

# A wrong key must also fail authentication.
wrong_key <- as.raw(rep(0x22, 32))
ok_wrong_key <- tryCatch({ data_decrypt(ct, wrong_key, nonce); TRUE },
                          error = function(e) FALSE)
stopifnot(!isTRUE(ok_wrong_key))

cat("ok", length(ct), length(pt), "\n")
'
