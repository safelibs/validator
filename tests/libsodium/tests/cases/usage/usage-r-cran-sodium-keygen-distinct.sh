#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-keygen-distinct
# @title: R sodium::keygen produces distinct keys across calls
# @description: Calls sodium::keygen() five times, asserts each result is a 32-byte raw vector, that every pair of generated keys is distinct, and that each derived public key (sodium::pubkey) is also 32 bytes and differs from its corresponding secret key. Confirms r-cran-sodium's libsodium-backed CSPRNG produces independent X25519 secret keys on repeat invocations rather than reusing a stuck value.
# @timeout: 180
# @tags: usage, crypto, keygen, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
samples <- replicate(5, keygen(), simplify = FALSE)

for (i in seq_along(samples)) {
  sk <- samples[[i]]
  stopifnot(is.raw(sk))
  stopifnot(length(sk) == 32)
}

# Pairwise distinctness.
for (i in seq_along(samples)) {
  for (j in seq_along(samples)) {
    if (i < j) {
      stopifnot(!identical(samples[[i]], samples[[j]]))
    }
  }
}

# Each public key derives to 32 bytes and differs from its secret key.
for (sk in samples) {
  pk <- pubkey(sk)
  stopifnot(is.raw(pk))
  stopifnot(length(pk) == 32)
  stopifnot(!identical(pk, sk))
}

cat("ok", length(samples), "\n")
'
