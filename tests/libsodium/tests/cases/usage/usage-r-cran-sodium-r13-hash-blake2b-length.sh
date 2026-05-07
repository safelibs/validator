#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r13-hash-blake2b-length
# @title: r-cran-sodium hash() with explicit size returns a digest of that length
# @description: Hashes a fixed payload with sodium::hash(size=32) and sodium::hash(size=64), asserts each returned raw vector has the requested length, and asserts re-hashing the same input yields byte-identical output (deterministic).
# @timeout: 180
# @tags: usage, crypto, hash, blake2b, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
msg <- charToRaw("r-cran-sodium r13 blake2b payload")
h32 <- hash(msg, size = 32)
h64 <- hash(msg, size = 64)
stopifnot(is.raw(h32), is.raw(h64))
stopifnot(length(h32) == 32)
stopifnot(length(h64) == 64)
stopifnot(identical(h32, hash(msg, size = 32)))
stopifnot(identical(h64, hash(msg, size = 64)))
# Different-size digests should not be a prefix of each other byte-for-byte.
stopifnot(!identical(h32, h64[1:32]))
cat("ok\n")
'
