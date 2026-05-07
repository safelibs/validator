#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-tiff-buffer-write-then-read-back
# @title: ruby-vips write_to_buffer('.tif') then new_from_buffer recovers width and height
# @description: Builds a 6x5 single-band uchar image, writes a TIFF to an in-memory buffer with write_to_buffer('.tif'), reloads the buffer with Vips::Image.new_from_buffer, and verifies the reload preserves the original 6x5 dimensions, asserting the libvips TIFF buffer roundtrip without disk IO.
# @timeout: 60
# @tags: usage, vips, ruby, tiff, buffer
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(6, 5) + 60).cast(:uchar)
buf = img.write_to_buffer('.tif')
raise "empty tiff buffer" unless buf.bytesize > 0
reload = Vips::Image.new_from_buffer(buf, '')
raise "tiff reload dims=#{reload.width}x#{reload.height}" unless reload.width == 6 && reload.height == 5
puts "tiff buffer roundtrip #{reload.width}x#{reload.height}"
RUBY
