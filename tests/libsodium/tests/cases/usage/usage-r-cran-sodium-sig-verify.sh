#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-sig-verify
# @title: R sodium ed25519 sign and sig_verify
# @description: Generates an ed25519 signing key with sodium::sig_keygen, signs a binary payload with sodium::sig, and asserts sig_verify accepts the signature with the matching public key (sig_pubkey) and rejects it for a tampered message.
# @timeout: 180
# @tags: usage, crypto, signature, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
sk <- sig_keygen()
stopifnot(is.raw(sk))
# r-cran-sodium returns the full libsodium expanded secret key
# (crypto_sign_SECRETKEYBYTES == 64), which is the Ed25519 seed concatenated
# with the public key.
stopifnot(length(sk) == 64)
pk <- sig_pubkey(sk)
stopifnot(is.raw(pk))
stopifnot(length(pk) == 32)
msg <- charToRaw("r sodium signature payload")
signature <- sig_sign(msg, sk)
stopifnot(is.raw(signature))
stopifnot(length(signature) == 64)
stopifnot(isTRUE(sig_verify(msg, signature, pk)))
tampered <- charToRaw("r sodium signature payload!")
ok <- tryCatch(sig_verify(tampered, signature, pk), error = function(e) FALSE)
stopifnot(!isTRUE(ok))
cat("ok", length(sk), length(signature), "\n")
'
