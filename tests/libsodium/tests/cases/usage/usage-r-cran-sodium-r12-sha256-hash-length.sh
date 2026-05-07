#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r12-sha256-hash-length
# @title: r-cran-sodium sha256 returns a 32-byte digest for a known input
# @description: Hashes a fixed ASCII payload via sodium::sha256, asserts the digest is a 32-byte raw vector, hashes the same input again and asserts the two digests are byte-identical (deterministic), and asserts a different payload yields a different digest.
# @timeout: 180
# @tags: usage, crypto, hash, sha256, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
msg <- charToRaw("r-cran-sodium r12 sha256 payload")
h1 <- sha256(msg)
h2 <- sha256(msg)
stopifnot(is.raw(h1))
stopifnot(length(h1) == 32)
stopifnot(identical(h1, h2))

other <- charToRaw("r-cran-sodium r12 different payload")
stopifnot(!identical(sha256(other), h1))
cat("ok\n")
'
