#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r16-sha256-hex-length-64
# @title: r-cran-sodium sha256 followed by bin2hex returns 64 lowercase hex characters
# @description: Hashes a fixed message with sodium::sha256, asserts the resulting raw vector is 32 bytes, converts to hex via sodium::bin2hex and asserts the hex string is exactly 64 characters of [0-9a-f], and asserts re-hashing the same message yields the identical hex digest.
# @timeout: 60
# @tags: usage, crypto, sha256, r, r16
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
msg <- charToRaw("r16 r-cran-sodium sha256 payload")
h1 <- sha256(msg)
stopifnot(is.raw(h1))
stopifnot(length(h1) == 32)
hex <- bin2hex(h1)
stopifnot(is.character(hex))
stopifnot(nchar(hex) == 64)
stopifnot(grepl("^[0-9a-f]{64}$", hex))
again <- bin2hex(sha256(msg))
stopifnot(identical(hex, again))
cat("ok\n")
'
