#!/usr/bin/env bash
# @testcase: usage-bzip2-r11-end-of-options-separator
# @title: bzip2 -- terminator allows compressing a dash-prefixed filename
# @description: Creates a file whose name begins with a dash and uses the -- end-of-options separator so bzip2 treats the dash-prefixed token as a filename rather than a flag, then verifies the .bz2 sibling exists and decodes to the original content.
# @timeout: 60
# @tags: usage, compression, argv, separator
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"
fname='-leading-dash.txt'
printf 'dash-name payload line\n%s\n' "$(seq 1 40)" >"$fname"
orig_sha=$(sha256sum -- "$fname" | awk '{print $1}')

bzip2 --keep -- "$fname"

[[ -f "${fname}.bz2" ]]
bzip2 -dc -- "${fname}.bz2" >"$tmpdir/round.out"
round_sha=$(sha256sum "$tmpdir/round.out" | awk '{print $1}')
[[ "$orig_sha" == "$round_sha" ]]
