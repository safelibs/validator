#!/usr/bin/env bash
# @testcase: usage-r-cran-sodium-bin2hex-roundtrip
# @title: R sodium bin2hex/hex2bin roundtrip across keygen output
# @description: Generates a curve25519 secret key with sodium::keygen, encodes it via sodium::bin2hex, asserts the encoded form has length 64 and matches lowercase hex, and asserts hex2bin decodes back to the exact original raw bytes.
# @timeout: 180
# @tags: usage, crypto, encoding, r
# @client: r-cran-sodium

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

Rscript -e '
suppressMessages(library(sodium))
sk <- keygen()
stopifnot(is.raw(sk))
stopifnot(length(sk) == 32)

hex_str <- bin2hex(sk)
stopifnot(is.character(hex_str))
stopifnot(nchar(hex_str) == 64)
stopifnot(grepl("^[0-9a-f]{64}$", hex_str))

decoded <- hex2bin(hex_str)
stopifnot(is.raw(decoded))
stopifnot(length(decoded) == 32)
stopifnot(identical(decoded, sk))

# Roundtripping a fixed value matches a known hex string exactly.
fixed <- as.raw(c(0x00, 0xff, 0x10, 0x20, 0x30))
stopifnot(identical(bin2hex(fixed), "00ff102030"))
stopifnot(identical(hex2bin("00ff102030"), fixed))

cat("ok", nchar(hex_str), "\n")
'
