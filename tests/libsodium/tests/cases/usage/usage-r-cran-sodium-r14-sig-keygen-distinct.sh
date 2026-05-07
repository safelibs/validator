#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r14-sig-keygen-distinct
# @title: r-cran-sodium sig_keygen produces distinct ed25519 keys across calls
# @description: Calls sodium::sig_keygen() five times, asserts each result is a 64-byte raw vector (libsodium expanded ed25519 secret key), asserts every pair of generated keys is distinct, and asserts each derived sig_pubkey is a distinct 32-byte public key.
# @timeout: 180
# @tags: usage, crypto, ed25519, keygen, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
samples <- replicate(5, sig_keygen(), simplify = FALSE)

for (sk in samples) {
  stopifnot(is.raw(sk))
  stopifnot(length(sk) == 64)
}

# Pairwise distinct secret keys.
for (i in seq_along(samples)) {
  for (j in seq_along(samples)) {
    if (i < j) {
      stopifnot(!identical(samples[[i]], samples[[j]]))
    }
  }
}

# Derive public keys: 32 bytes each, pairwise distinct.
pubs <- lapply(samples, sig_pubkey)
for (pk in pubs) {
  stopifnot(is.raw(pk))
  stopifnot(length(pk) == 32)
}
for (i in seq_along(pubs)) {
  for (j in seq_along(pubs)) {
    if (i < j) {
      stopifnot(!identical(pubs[[i]], pubs[[j]]))
    }
  }
}

cat("ok", length(samples), "\n")
'
