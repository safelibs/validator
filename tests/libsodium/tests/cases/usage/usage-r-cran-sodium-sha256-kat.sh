#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-sha256-kat
# @title: R sodium SHA-256 known-answer
# @description: Computes sodium::sha256 of the canonical "abc" input and asserts the hex digest matches the FIPS 180-4 known-answer vector.
# @timeout: 180
# @tags: usage, crypto, hash, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
digest <- sha256(charToRaw("abc"))
hex <- paste(format(digest), collapse = "")
expected <- "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
stopifnot(identical(hex, expected))
cat(hex, "\n")
'
