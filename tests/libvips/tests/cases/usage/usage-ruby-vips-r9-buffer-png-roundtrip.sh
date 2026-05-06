#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-buffer-png-roundtrip
# @title: ruby-vips PNG buffer roundtrip
# @description: Encodes an image to a PNG buffer with write_to_buffer, decodes it with new_from_buffer and verifies dimensions and band count are preserved.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - <<'RUBY'
img = Vips::Image.black(20, 10, bands: 3) + [128, 64, 32]
img = img.cast(:uchar)
buf = img.write_to_buffer('.png')
raise "empty buffer" unless buf.bytesize > 8
raise "missing PNG header" unless buf[1, 3] == 'PNG'
loaded = Vips::Image.new_from_buffer(buf, '')
raise "dim #{loaded.width}x#{loaded.height}" unless loaded.width == 20 && loaded.height == 10
raise "bands #{loaded.bands}" unless loaded.bands == 3
RUBY
