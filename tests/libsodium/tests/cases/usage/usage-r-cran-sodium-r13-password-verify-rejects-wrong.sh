#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r13-password-verify-rejects-wrong
# @title: r-cran-sodium password_verify accepts the original password and rejects a near-miss
# @description: Stores a hash with sodium::password_store, asserts password_verify returns TRUE for the original password, returns FALSE for a single-character variant, and returns FALSE for an empty string.
# @timeout: 600
# @tags: usage, crypto, pwhash, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

Rscript -e '
suppressMessages(library(sodium))
pw <- "r13-password-correct-horse"
hash <- password_store(pw)
stopifnot(is.character(hash))
stopifnot(nchar(hash) > 0)
stopifnot(isTRUE(password_verify(hash, pw)))
stopifnot(!isTRUE(password_verify(hash, "r13-password-correct-hors")))
stopifnot(!isTRUE(password_verify(hash, "")))
cat("ok\n")
'
