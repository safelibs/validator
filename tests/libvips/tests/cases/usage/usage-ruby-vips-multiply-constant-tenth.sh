#!/usr/bin/env bash
# @testcase: usage-ruby-vips-multiply-constant-tenth
# @title: ruby-vips generated multiply constant tenth
# @description: Multiplies a generated image by a scalar constant with ruby-vips in the tenth batch and verifies each output pixel equals the input scaled by the constant.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-multiply-constant-tenth"
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

image = gray_image(2, 1, [3, 5])
out = (image * 4).cast(:uchar)
raise "multiply mismatch" unless out.write_to_memory.bytes == [12, 20]
puts "multiply #{out.write_to_memory.bytes.join(',')}"
RUBY
