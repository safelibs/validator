#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r19-sig-keygen-lengths
# @title: r-cran-sodium sig_keygen produces 64-byte private key with derivable 32-byte public key
# @description: Calls sodium::sig_keygen() to produce an Ed25519 private key, asserts it is a raw vector of length 64 (libsodium concatenated seed+publickey layout), calls sodium::sig_pubkey(priv) and asserts the derived public key is a raw vector of length 32, and asserts a second sig_keygen() call yields a private key of length 64 that differs from the first.
# @timeout: 60
# @tags: usage, crypto, sign, ed25519, r, r19
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
sk1 <- sig_keygen()
stopifnot(is.raw(sk1), length(sk1) == 64)
pk1 <- sig_pubkey(sk1)
stopifnot(is.raw(pk1), length(pk1) == 32)
sk2 <- sig_keygen()
stopifnot(is.raw(sk2), length(sk2) == 64)
stopifnot(!identical(sk1, sk2))
cat("ok sig_keygen sk=", length(sk1), " pk=", length(pk1), "\n", sep="")
'
