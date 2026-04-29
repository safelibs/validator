#!/usr/bin/env bash
# @testcase: usage-ruby-vips-linear-offset-batch11
# @title: ruby-vips linear offset
# @description: Applies a linear transform with scale and offset through ruby-vips.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-linear-offset-batch11"
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

image = gray_image(2, 1, [4, 8])
out = image.linear(3, 2).cast(:uchar)
raise "linear mismatch" unless bytes(out) == [14, 26]
puts "linear #{bytes(out).join(',')}"
RUBY
