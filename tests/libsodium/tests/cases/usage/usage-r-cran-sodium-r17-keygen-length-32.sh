#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r17-keygen-length-32
# @title: r-cran-sodium keygen returns a 32-byte raw vector for secret key material
# @description: Calls sodium::keygen() twice, asserts each result is a raw vector of length exactly 32 (libsodium-derived symmetric key length), asserts the two keys differ (RNG sanity), and asserts a third call still yields a 32-byte raw vector distinct from both prior keys.
# @timeout: 60
# @tags: usage, crypto, keygen, r, r17
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
k1 <- keygen()
k2 <- keygen()
k3 <- keygen()
stopifnot(is.raw(k1), length(k1) == 32)
stopifnot(is.raw(k2), length(k2) == 32)
stopifnot(is.raw(k3), length(k3) == 32)
stopifnot(!identical(k1, k2))
stopifnot(!identical(k2, k3))
stopifnot(!identical(k1, k3))
cat("ok\n")
'
