#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-new-from-buffer-png-roundtrip
# @title: ruby-vips Image.new_from_buffer round-trips a PNG-encoded blob via write_to_buffer
# @description: Builds an 8x6 uchar constant-99 image, encodes it to a PNG byte string with write_to_buffer('.png'), decodes the bytes back via Image.new_from_buffer(bytes, ''), and asserts the reconstructed image has identical width, height, and avg pixel value, exercising libvips' in-memory PNG codec round-trip.
# @timeout: 60
# @tags: usage, vips, ruby, new-from-buffer, png, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(8, 6) + 99).cast(:uchar)
bytes = src.write_to_buffer('.png')
raise "no bytes" if bytes.nil? || bytes.bytesize < 8
raise "no png magic" unless bytes.byteslice(0, 8).bytes == [137, 80, 78, 71, 13, 10, 26, 10]
out = Vips::Image.new_from_buffer(bytes, '')
raise "width=#{out.width}" unless out.width == src.width
raise "height=#{out.height}" unless out.height == src.height
raise "avg out=#{out.avg} src=#{src.avg}" unless out.avg == src.avg
puts "new_from_buffer png avg=#{out.avg}"
RUBY
