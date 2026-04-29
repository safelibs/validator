#!/usr/bin/env bash
# @testcase: usage-ruby-vips-extract-corner-batch11
# @title: ruby-vips extract corner
# @description: Extracts a lower-corner region from an image with ruby-vips.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-extract-corner-batch11"
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

def bytes(image)
  image.cast(:uchar).write_to_memory.bytes
end

image = gray_image(3, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9])
out = image.extract_area(1, 1, 2, 2)
raise "extract" unless bytes(out) == [5, 6, 8, 9]
puts "extract #{bytes(out).join(',')}"
RUBY
