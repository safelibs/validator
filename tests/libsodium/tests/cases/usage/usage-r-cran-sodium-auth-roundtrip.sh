#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-auth-roundtrip
# @title: R sodium HMAC-SHA512-256 auth roundtrip
# @description: Generates a 32-byte secret key, computes an HMAC-SHA512-256 tag with sodium::data_tag using a fixed key, and asserts the tag length is 32 bytes and is deterministic for the same input but changes when either the message or the key changes.
# @timeout: 180
# @tags: usage, crypto, mac, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
key_a <- as.raw(rep(0x11, 32))
key_b <- as.raw(rep(0x22, 32))
msg <- charToRaw("r sodium auth payload")
tag_a <- data_tag(msg, key_a)
stopifnot(is.raw(tag_a))
stopifnot(length(tag_a) == 32)
tag_a2 <- data_tag(msg, key_a)
stopifnot(identical(tag_a, tag_a2))
tag_b <- data_tag(msg, key_b)
stopifnot(!identical(tag_a, tag_b))
msg2 <- charToRaw("r sodium auth payload!")
tag_a_msg2 <- data_tag(msg2, key_a)
stopifnot(!identical(tag_a, tag_a_msg2))
cat("ok", length(tag_a), "\n")
'
