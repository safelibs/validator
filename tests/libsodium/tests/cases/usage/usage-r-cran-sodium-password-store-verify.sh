#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-password-store-verify
# @title: R sodium password_store and password_verify roundtrip
# @description: Stores a password hash with sodium::password_store and asserts password_verify accepts the original password and rejects a different one.
# @timeout: 600
# @tags: usage, crypto, pwhash, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
hash <- password_store("correct horse battery staple")
stopifnot(is.character(hash))
stopifnot(nchar(hash) > 0)
stopifnot(isTRUE(password_verify(hash, "correct horse battery staple")))
stopifnot(!isTRUE(password_verify(hash, "wrong password")))
cat("ok\n")
'
