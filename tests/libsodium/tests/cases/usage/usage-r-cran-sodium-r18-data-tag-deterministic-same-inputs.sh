#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r18-data-tag-deterministic-same-inputs
# @title: r-cran-sodium data_tag is deterministic for identical message and key inputs
# @description: Generates a 32-byte key, computes sodium::data_tag(msg, key) twice on the same byte vector with the same key, and asserts both outputs are raw vectors of length 32 (libsodium generichash default) and identical byte-for-byte, then computes data_tag with a fresh key and asserts the result is a 32-byte raw vector that differs from the original tag.
# @timeout: 60
# @tags: usage, crypto, mac, generichash, r, r18
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
key <- keygen()
msg <- charToRaw("r18 sodium data_tag determinism vector")
t1 <- data_tag(msg, key)
t2 <- data_tag(msg, key)
stopifnot(is.raw(t1), length(t1) == 32)
stopifnot(is.raw(t2), length(t2) == 32)
stopifnot(identical(t1, t2))
key2 <- keygen()
t3 <- data_tag(msg, key2)
stopifnot(is.raw(t3), length(t3) == 32)
stopifnot(!identical(t1, t3))
cat("ok deterministic tag\n")
'
