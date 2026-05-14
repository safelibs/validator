#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r17-random-length-48
# @title: r-cran-sodium random(48) returns 48-byte raw vector and is non-deterministic
# @description: Calls sodium::random(48) twice, asserts each result is a raw vector of length exactly 48 (libsodium randombytes_buf path), and asserts the two raw vectors differ (RNG sanity); additionally asserts random(1) returns a single-byte raw vector.
# @timeout: 60
# @tags: usage, crypto, random, r, r17
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
a <- random(48)
b <- random(48)
stopifnot(is.raw(a))
stopifnot(length(a) == 48)
stopifnot(is.raw(b))
stopifnot(length(b) == 48)
stopifnot(!identical(a, b))

c <- random(1)
stopifnot(is.raw(c))
stopifnot(length(c) == 1)
cat("ok\n")
'
