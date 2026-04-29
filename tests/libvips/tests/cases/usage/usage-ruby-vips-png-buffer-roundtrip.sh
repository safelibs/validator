#!/usr/bin/env bash
# @testcase: usage-ruby-vips-png-buffer-roundtrip
# @title: ruby-vips PNG buffer round trip
# @description: Exercises ruby-vips png buffer round trip through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-png-buffer-roundtrip"
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

image = gray_image(2, 2, [5, 15, 25, 35])
buffer = image.write_to_buffer('.png')
reload = Vips::Image.new_from_buffer(buffer, '')
raise 'png roundtrip mismatch' unless gray_pixel(reload, 1, 1) == 35
puts "png-buffer #{gray_pixel(reload, 1, 1)}"
RUBY
