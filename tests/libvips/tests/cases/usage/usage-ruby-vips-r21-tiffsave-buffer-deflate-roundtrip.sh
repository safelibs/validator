#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-tiffsave-buffer-deflate-roundtrip
# @title: ruby-vips tiffsave_buffer with compression :deflate roundtrips an image without losing pixel mean
# @description: Builds a 10x10 uchar image with constant value 55, encodes it to a TIFF byte string via tiffsave_buffer with compression: :deflate, decodes via new_from_buffer, and asserts width, height, and avg pixel value match the source, exercising libvips' deflate-compressed TIFF write path.
# @timeout: 60
# @tags: usage, vips, ruby, tiff, deflate, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(10, 10) + 55).cast(:uchar)
bytes = src.tiffsave_buffer(compression: :deflate)
raise "no bytes" if bytes.nil? || bytes.bytesize < 8
# TIFF little-endian magic is "II*\0" or big-endian "MM\0*"
magic = bytes.byteslice(0, 4).bytes
unless magic == [0x49, 0x49, 0x2a, 0x00] || magic == [0x4d, 0x4d, 0x00, 0x2a]
  raise "no tiff magic: #{magic.inspect}"
end
out = Vips::Image.new_from_buffer(bytes, '')
raise "width=#{out.width}" unless out.width == src.width
raise "height=#{out.height}" unless out.height == src.height
raise "avg out=#{out.avg} src=#{src.avg}" unless out.avg == src.avg
puts "tiff deflate avg=#{out.avg}"
RUBY
