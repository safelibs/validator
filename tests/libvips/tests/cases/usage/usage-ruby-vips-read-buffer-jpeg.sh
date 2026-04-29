#!/usr/bin/env bash
# @testcase: usage-ruby-vips-read-buffer-jpeg
# @title: ruby-vips read JPEG buffer
# @description: Exercises ruby-vips read jpeg buffer through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-read-buffer-jpeg"
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

image = multiband_image(2, 2, 3, [255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0])
buffer = image.write_to_buffer('.jpg')
reload = Vips::Image.new_from_buffer(buffer, '')
raise 'jpeg buffer mismatch' unless reload.width == 2 && reload.height == 2
puts "jpeg-buffer #{reload.width}x#{reload.height}"
RUBY
