#!/usr/bin/env bash
# @testcase: usage-ruby-vips-tiff-buffer-roundtrip
# @title: ruby-vips TIFF buffer round trip
# @description: Encodes a small grayscale image to TIFF via Vips::Image#write_to_buffer('.tif') and decodes it back, verifying that the produced buffer carries a TIFF magic header and that dimensions plus exact pixel values survive the round trip.
# @timeout: 180
# @tags: usage, ruby, image, tiff
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 3x3 grayscale, deterministic
data = [
  10, 20, 30,
  40, 50, 60,
  70, 80, 90,
]
src = Vips::Image.new_from_memory(data.pack('C*'), 3, 3, 1, :uchar)

buf = src.write_to_buffer('.tif')
raise "empty buffer" unless buf.is_a?(String) && buf.bytesize > 8

# TIFF magic: II*\0 (little-endian) or MM\0* (big-endian)
magic = buf.byteslice(0, 4)
raise "no TIFF magic: #{magic.bytes.inspect}" unless magic == "II*\x00".b || magic == "MM\x00*".b

reload = Vips::Image.new_from_buffer(buf, '')
raise "dims #{reload.width}x#{reload.height}" unless reload.width == 3 && reload.height == 3
raise "bands #{reload.bands}" unless reload.bands == 1

# TIFF is lossless for uchar, so verify a known pixel exactly.
raise "pt 0,0" unless reload.getpoint(0, 0) == [10.0]
raise "pt 2,2" unless reload.getpoint(2, 2) == [90.0]

out_path = File.join(tmpdir, "out.tif")
File.binwrite(out_path, buf)
raise "missing tif" unless File.size?(out_path)
puts "tiff roundtrip bytes=#{buf.bytesize} #{reload.width}x#{reload.height}"
RUBY

file "$tmpdir/out.tif" | grep -qiE 'TIFF image data' || { echo "not tiff: $(file "$tmpdir/out.tif")" >&2; exit 1; }
