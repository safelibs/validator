#!/usr/bin/env bash
# @testcase: usage-ruby-vips-flatten-white-batch11
# @title: ruby-vips flatten white
# @description: Flattens an alpha pixel over a white background with ruby-vips.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-flatten-white-batch11"
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

image = multiband_image(1, 1, 4, [0, 0, 0, 128])
out = image.flatten(background: [255, 255, 255])
raise "flatten" unless bytes(out)[0] > 100
puts "flatten #{bytes(out).join(',')}"
RUBY
