#!/usr/bin/env bash
# @testcase: usage-ruby-vips-math-sin-cos
# @title: ruby-vips math sin and cos in degrees
# @description: Builds a single-band float image holding angles in degrees and verifies that Vips::Image#math with :sin and :cos produces values matching Ruby's Math.sin and Math.cos at multiple sample angles within floating-point tolerance.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# libvips math operations work on degrees for trigonometric ops.
angles_deg = [0.0, 30.0, 45.0, 60.0, 90.0, 180.0]
img = Vips::Image.new_from_memory(angles_deg.pack('d*'),
                                  angles_deg.length, 1, 1, :double)
raise "img dims" unless img.width == 6 && img.height == 1 && img.bands == 1

sin_img = img.math(:sin)
cos_img = img.math(:cos)
raise "sin dims" unless sin_img.width == 6 && sin_img.bands == 1
raise "cos dims" unless cos_img.width == 6 && cos_img.bands == 1

angles_deg.each_with_index do |deg, x|
  rad = deg * Math::PI / 180.0
  s = sin_img.getpoint(x, 0)[0]
  c = cos_img.getpoint(x, 0)[0]
  raise "sin(#{deg})=#{s} want #{Math.sin(rad)}" unless (s - Math.sin(rad)).abs < 1e-6
  raise "cos(#{deg})=#{c} want #{Math.cos(rad)}" unless (c - Math.cos(rad)).abs < 1e-6
end

puts "math sin/cos ok #{angles_deg.length} samples"
RUBY
