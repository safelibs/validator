#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-random-length
# @title: R sodium random() returns requested byte counts
# @description: Calls sodium::random with several sizes (16, 24, 32, 64) and asserts each result is a raw vector of the exact requested length and that two independent calls of size 32 produce different bytes (probabilistic but the collision space is 2^256).
# @timeout: 180
# @tags: usage, crypto, random, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
for (n in c(16L, 24L, 32L, 64L)) {
  buf <- random(n)
  stopifnot(is.raw(buf))
  stopifnot(length(buf) == n)
}
a <- random(32L)
b <- random(32L)
stopifnot(is.raw(a), length(a) == 32L)
stopifnot(is.raw(b), length(b) == 32L)
stopifnot(!identical(a, b))
cat("ok", length(a), length(b), "\n")
'
