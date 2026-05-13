#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r16-write-to-buffer-png-has-png-magic
# @title: ruby-vips Image#write_to_buffer('.png') emits a buffer whose first 8 bytes are the PNG magic
# @description: Builds a 6x6 single-band uchar image, encodes via Image#write_to_buffer('.png'), asserts the resulting buffer is non-empty and its first 8 bytes equal the canonical PNG magic signature \x89PNG\r\n\x1a\n — exercising libvips' PNG buffer encoder.
# @timeout: 60
# @tags: usage, vips, ruby, png, buffer
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(6, 6) + 90).cast(:uchar)
buf = img.write_to_buffer(".png")
raise "empty png buffer" unless buf.bytesize > 8
magic = "\x89PNG\r\n\x1a\n".b
raise "png magic mismatch: #{buf.byteslice(0, 8).bytes.inspect}" unless buf.byteslice(0, 8) == magic
puts "png magic ok size=#{buf.bytesize}"
RUBY
