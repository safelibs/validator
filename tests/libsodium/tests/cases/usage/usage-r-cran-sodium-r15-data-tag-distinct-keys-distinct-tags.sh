#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r15-data-tag-distinct-keys-distinct-tags
# @title: r-cran-sodium data_tag returns distinct 32-byte tags under distinct keys for the same message
# @description: Computes data_tag over a fixed message under three distinct 32-byte keys, asserts each tag is a 32-byte raw vector, asserts pairwise tag inequality across the three keys, and asserts re-computing data_tag with the first key yields a byte-identical tag (determinism) — exercising r-cran-sodium's libsodium-backed HMAC-SHA512-256.
# @timeout: 180
# @tags: usage, crypto, mac, r, r15
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))

msg <- charToRaw("r15 r-cran-sodium data_tag payload")
key_a <- as.raw(rep(0x11, 32))
key_b <- as.raw(rep(0x22, 32))
key_c <- as.raw(rep(0x33, 32))

tag_a <- data_tag(msg, key_a)
tag_b <- data_tag(msg, key_b)
tag_c <- data_tag(msg, key_c)

stopifnot(is.raw(tag_a), is.raw(tag_b), is.raw(tag_c))
stopifnot(length(tag_a) == 32)
stopifnot(length(tag_b) == 32)
stopifnot(length(tag_c) == 32)

# Pairwise distinct under distinct keys.
stopifnot(!identical(tag_a, tag_b))
stopifnot(!identical(tag_a, tag_c))
stopifnot(!identical(tag_b, tag_c))

# Determinism: same key + message yields the same tag.
again <- data_tag(msg, key_a)
stopifnot(identical(tag_a, again))

cat("ok\n")
'
