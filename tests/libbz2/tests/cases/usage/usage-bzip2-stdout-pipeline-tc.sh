#!/usr/bin/env bash
# @testcase: usage-bzip2-stdout-pipeline-tc
# @title: bzip2 -c piped into bzip2 -t -
# @description: Pipes plaintext into bzip2 -c (compress to stdout) and immediately into bzip2 -t - (test the stream from stdin), verifying the pipeline reports a healthy stream and that an out-of-band decompression of the captured pipeline output reproduces the input bytes.
# @timeout: 180
# @tags: usage, bzip2, stream, pipeline
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
for i in range(2048):
    sys.stdout.write(f"pipeline payload row {i}\n")' >"$tmpdir/in.txt"
expected_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

# Capture the compressed bytes once via the pipeline so the integrity check
# operates on exactly what compression produced.
bzip2 -c <"$tmpdir/in.txt" >"$tmpdir/pipe.bz2"

# bzip2 -t reading the stream from stdin must accept the compressed bytes.
# (-t exits 0 on a healthy stream.) The explicit "-" arg requests stdin.
bzip2 -t - <"$tmpdir/pipe.bz2" 2>"$tmpdir/err.test"
[[ ! -s "$tmpdir/err.test" ]] || {
  printf 'expected silent -t - on healthy stream, stderr was:\n' >&2
  cat "$tmpdir/err.test" >&2
  exit 1
}

# Direct pipeline form: bzip2 -c | bzip2 -t - exits 0 end-to-end.
bzip2 -c <"$tmpdir/in.txt" | bzip2 -t -

# Out-of-band decompression must reproduce the original bytes exactly.
bzip2 -dc "$tmpdir/pipe.bz2" >"$tmpdir/round.txt"
cmp "$tmpdir/in.txt" "$tmpdir/round.txt"
[[ "$(sha256sum "$tmpdir/round.txt" | awk '{print $1}')" == "$expected_sha" ]]
