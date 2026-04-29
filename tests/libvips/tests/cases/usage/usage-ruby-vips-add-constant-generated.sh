#!/usr/bin/env bash
# @testcase: usage-ruby-vips-add-constant-generated
# @title: ruby-vips generated add constant
# @description: Exercises ruby-vips generated add constant through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-add-constant-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" <<'RUBY'
case_id = ARGV[0]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).cast(:uchar).write_to_memory.bytes[0]
end

image = gray_image(2, 1, [5, 15])
out = (image + 5).cast(:uchar)
raise 'add mismatch' unless gray_pixel(out, 0, 0) == 10 && gray_pixel(out, 1, 0) == 20
puts "add #{gray_pixel(out, 1, 0)}"
RUBY
