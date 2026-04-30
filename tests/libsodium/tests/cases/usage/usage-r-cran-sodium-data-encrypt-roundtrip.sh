#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-data-encrypt-roundtrip
# @title: R sodium data_encrypt round-trip
# @description: Encrypts a payload with sodium::data_encrypt under a fixed key and nonce, then decrypts and asserts the recovered bytes match the original.
# @timeout: 180
# @tags: usage, crypto, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
key <- as.raw(rep(0x07, 32))
nonce <- as.raw(rep(0x09, 24))
msg <- charToRaw("r-cran-sodium roundtrip payload")
ct <- data_encrypt(msg, key, nonce)
stopifnot(length(ct) == length(msg) + 16)
pt <- data_decrypt(ct, key, nonce)
stopifnot(identical(pt, msg))
cat("ok", length(pt), "\n")
'
