#!/usr/bin/env bash
# @testcase: usage-ruby-vips-jpeg-quality-buffer
# @title: ruby-vips JPEG quality buffer roundtrip
# @description: Encodes a synthetic image to JPEG buffers at two quality levels, confirms the high-quality buffer is larger, and reloads each via new_from_buffer.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Use a noisy synthetic image so quality has a measurable effect on size.
base = Vips::Image.gaussnoise(64, 64, mean: 128, sigma: 80).cast(:uchar)
rgb  = base.bandjoin([base, base]).copy(interpretation: :srgb)

low_buf  = rgb.write_to_buffer(".jpg", Q: 20)
high_buf = rgb.write_to_buffer(".jpg", Q: 95)

raise "low buf empty"  if low_buf.bytesize  == 0
raise "high buf empty" if high_buf.bytesize == 0
raise "expected high quality > low quality (#{high_buf.bytesize} vs #{low_buf.bytesize})" unless high_buf.bytesize > low_buf.bytesize

[low_buf, high_buf].each do |buf|
  raise "missing JPEG SOI" unless buf.bytes.first(2) == [0xFF, 0xD8]
end

low_img  = Vips::Image.new_from_buffer(low_buf,  "")
high_img = Vips::Image.new_from_buffer(high_buf, "")
raise "low dims"  unless low_img.width  == 64 && low_img.height  == 64
raise "high dims" unless high_img.width == 64 && high_img.height == 64

low_path  = File.join(tmpdir, "low.jpg")
high_path = File.join(tmpdir, "high.jpg")
File.binwrite(low_path,  low_buf)
File.binwrite(high_path, high_buf)
puts "jpeg sizes low=#{low_buf.bytesize} high=#{high_buf.bytesize}"
RUBY

file "$tmpdir/low.jpg"  | grep -q 'JPEG image data' || { echo "low not a JPEG" >&2; exit 1; }
file "$tmpdir/high.jpg" | grep -q 'JPEG image data' || { echo "high not a JPEG" >&2; exit 1; }
