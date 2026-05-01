#!/usr/bin/env bash
# @testcase: usage-python3-pil-tiff-artist-hostcomputer-tags
# @title: Pillow TIFF Artist and HostComputer tag round-trip
# @description: Saves a TIFF with Artist (315) and HostComputer (316) tags injected via ImageFileDirectory_v2 and verifies both strings reload exactly through Pillow tag_v2 on reopen.
# @timeout: 180
# @tags: usage, image, python, metadata
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$tmpdir/who.tiff"

python3 - <<'PY' "$img"
import sys
from PIL import Image
from PIL.TiffImagePlugin import ImageFileDirectory_v2

artist = "Validator Suite"
host = "ubuntu-noble-x86_64"
ifd = ImageFileDirectory_v2()
ifd[315] = artist
ifd[316] = host
image = Image.new("RGB", (8, 6), (90, 60, 30))
image.save(sys.argv[1], tiffinfo=ifd)

with Image.open(sys.argv[1]) as reopened:
    reopened.load()
    got_artist = reopened.tag_v2.get(315)
    got_host = reopened.tag_v2.get(316)
    assert got_artist == artist, got_artist
    assert got_host == host, got_host
    assert reopened.size == (8, 6), reopened.size
    print("attrib", repr(got_artist), repr(got_host))
PY
