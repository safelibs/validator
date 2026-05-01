#!/usr/bin/env bash
# @testcase: usage-ruby-vips-webp-buffer-roundtrip
# @title: ruby-vips WebP buffer round trip
# @description: Encodes a small sRGB image to WebP via Vips::Image#write_to_buffer('.webp') and decodes it again with Vips::Image.new_from_buffer, verifying the buffer is non-empty, has a WebP RIFF header, and that dimensions and band count survive the round trip.
# @timeout: 180
# @tags: usage, ruby, image, webp
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 4x4 sRGB image with deterministic per-pixel values.
data = []
(0...4).each do |y|
  (0...4).each do |x|
    data << (x * 17) % 256
    data << (y * 23) % 256
    data << ((x + y) * 11) % 256
  end
end
src = Vips::Image.new_from_memory(data.pack('C*'), 4, 4, 3, :uchar)
src = src.copy(interpretation: :srgb)

buf = src.write_to_buffer('.webp')
raise "empty buffer" unless buf.is_a?(String) && buf.bytesize > 16
raise "missing RIFF magic" unless buf.byteslice(0, 4) == 'RIFF'
raise "missing WEBP magic" unless buf.byteslice(8, 4) == 'WEBP'

reload = Vips::Image.new_from_buffer(buf, '')
raise "dims #{reload.width}x#{reload.height}" unless reload.width == 4 && reload.height == 4
raise "bands #{reload.bands}" unless reload.bands == 3 || reload.bands == 4

out_path = File.join(tmpdir, "out.webp")
File.binwrite(out_path, buf)
raise "missing webp" unless File.size?(out_path)
puts "webp roundtrip bytes=#{buf.bytesize} #{reload.width}x#{reload.height}"
RUBY

file "$tmpdir/out.webp" | grep -qiE 'WebP|RIFF' || { echo "not webp: $(file "$tmpdir/out.webp")" >&2; exit 1; }
