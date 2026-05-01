#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-scalar-multiply-batch12
# @title: R sodium scalar X25519 Diffie-Hellman shared secret
# @description: Generates two Curve25519 keypairs with sodium::keygen + sodium::pubkey, computes the Diffie-Hellman shared secret in both directions with sodium::scalar_multiply, asserts each side derives an identical 32-byte shared secret, and that an unrelated third secret key produces a different shared secret with the first public key.
# @timeout: 180
# @tags: usage, crypto, scalarmult, dh, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
sk_a <- keygen()
pk_a <- pubkey(sk_a)
sk_b <- keygen()
pk_b <- pubkey(sk_b)

shared_ab <- scalar_multiply(sk_a, pk_b)
shared_ba <- scalar_multiply(sk_b, pk_a)
stopifnot(is.raw(shared_ab))
stopifnot(length(shared_ab) == 32)
stopifnot(identical(shared_ab, shared_ba))

sk_c <- keygen()
shared_cb <- scalar_multiply(sk_c, pk_a)
stopifnot(!identical(shared_cb, shared_ab))

cat("ok", length(shared_ab), "\n")
'
