#!/usr/bin/env bash
# @testcase: usage-ruby-vips-cast-int-generated
# @title: ruby-vips generated cast int
# @description: Casts a generated uchar image to int format with ruby-vips and verifies the resulting image reports the int pixel format.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-cast-int-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).cast(:uchar).write_to_memory.bytes[0]
end

image = gray_image(2, 1, [40, 80])
out = image.cast(:int)
raise "cast format mismatch" unless out.format.to_s == "int"
puts "cast #{out.format}"
RUBY
