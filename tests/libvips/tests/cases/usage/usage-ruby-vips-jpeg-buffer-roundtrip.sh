#!/usr/bin/env bash
# @testcase: usage-ruby-vips-jpeg-buffer-roundtrip
# @title: ruby-vips JPEG buffer round trip
# @description: Exercises ruby-vips jpeg buffer round trip through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-jpeg-buffer-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).write_to_memory.bytes[0]
end

image = multiband_image(2, 2, 3, [20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130])
buffer = image.write_to_buffer('.jpg')
reload = Vips::Image.new_from_buffer(buffer, '')
raise 'jpeg reload mismatch' unless reload.width == 2 && reload.height == 2
puts "jpeg-roundtrip #{reload.width}x#{reload.height}"
RUBY
