#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-png-buffer-roundtrip-via-bytes
# @title: ruby-vips write_to_buffer(.png) followed by new_from_buffer recovers width and height
# @description: Builds a 5x4 single-band uchar image, writes a PNG to an in-memory buffer with write_to_buffer('.png'), reloads the buffer with Vips::Image.new_from_buffer, and verifies the reload preserves the original 5x4 dimensions, asserting the libvips PNG buffer roundtrip without disk IO.
# @timeout: 60
# @tags: usage, vips, ruby, png, buffer
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(5, 4) + 80).cast(:uchar)
buf = img.write_to_buffer('.png')
raise "empty png buffer" unless buf.bytesize > 0
reload = Vips::Image.new_from_buffer(buf, '')
raise "png reload dims=#{reload.width}x#{reload.height}" unless reload.width == 5 && reload.height == 4
puts "png buffer roundtrip #{reload.width}x#{reload.height}"
RUBY
