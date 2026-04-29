#!/usr/bin/env bash
# @testcase: usage-ruby-vips-add-constant-tenth
# @title: ruby-vips generated add constant tenth
# @description: Adds a scalar constant to a generated image with ruby-vips in the tenth batch and verifies each output pixel equals the input plus the constant.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-add-constant-tenth"
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

image = gray_image(2, 1, [10, 20])
out = (image + 7).cast(:uchar)
raise "add mismatch" unless out.write_to_memory.bytes == [17, 27]
puts "add #{out.write_to_memory.bytes.join(',')}"
RUBY
