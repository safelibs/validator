#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r20-bin2hex-empty-string
# @title: r-cran-sodium bin2hex on an empty raw vector returns an empty character
# @description: Calls sodium::bin2hex(raw(0)) in R, asserts the return is a character of nchar 0, then calls sodium::hex2bin on an empty hex string and asserts the result is a raw of length 0, confirming libsodium-backed hex encoding correctly handles the zero-length boundary.
# @timeout: 180
# @tags: usage, sodium, bin2hex, empty, r20
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript --vanilla -e '
suppressMessages(library(sodium))
h <- bin2hex(raw(0))
stopifnot(is.character(h))
stopifnot(nchar(h) == 0)
b <- hex2bin("")
stopifnot(is.raw(b))
stopifnot(length(b) == 0)
cat("ok empty roundtrip\n")
'
