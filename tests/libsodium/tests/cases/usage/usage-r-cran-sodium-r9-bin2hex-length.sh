#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-r9-bin2hex-length
# @title: r-cran-sodium bin2hex length doubles
# @description: Calls sodium::bin2hex on a 32-byte random buffer and verifies the resulting hex string has length 64 and matches a hex regex.
# @timeout: 180
# @tags: usage, crypto, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/bin2hex.R" <<'R'
suppressMessages(library(sodium))
buf <- random(32)
hex <- bin2hex(buf)
stopifnot(nchar(hex) == 64L)
stopifnot(grepl("^[0-9a-fA-F]+$", hex))
roundtrip <- hex2bin(hex)
stopifnot(identical(as.raw(buf), as.raw(roundtrip)))
cat("ok\n")
R

Rscript --vanilla "$tmpdir/bin2hex.R"
