#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-buildlut-piecewise
# @title: ruby-vips buildlut interpolates piecewise control points
# @description: Builds a 256-entry LUT from three control points via Vips::Image.buildlut and verifies the LUT exactly matches the control values at the input rows and linearly interpolates between them.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Control points: x=0 -> y=0, x=128 -> y=64, x=255 -> y=255
control = Vips::Image.new_from_array(
  [
    [0, 0],
    [128, 64],
    [255, 255],
  ],
)

lut = control.buildlut
raise "bands" unless lut.bands == 1
raise "dims #{lut.width}x#{lut.height}" unless lut.width == 256 && lut.height == 1

raise "anchor 0"   unless (lut.getpoint(0, 0)[0] - 0.0).abs < 0.01
raise "anchor 128" unless (lut.getpoint(128, 0)[0] - 64.0).abs < 0.01
raise "anchor 255" unless (lut.getpoint(255, 0)[0] - 255.0).abs < 0.01

# Linear interpolation midpoints.
midA = lut.getpoint(64, 0)[0]
raise "interp 64 got=#{midA}" unless (midA - 32.0).abs < 0.5
midB = lut.getpoint(192, 0)[0] # halfway between (128,64) and (255,255)
expected_midB = 64 + (192 - 128) * (255 - 64) / (255.0 - 128)
raise "interp 192 got=#{midB} want~=#{expected_midB}" unless (midB - expected_midB).abs < 1.0

puts "buildlut piecewise interpolation ok"
RUBY
