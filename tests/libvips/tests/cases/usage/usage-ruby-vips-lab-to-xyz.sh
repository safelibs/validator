#!/usr/bin/env bash
# @testcase: usage-ruby-vips-lab-to-xyz
# @title: ruby-vips colourspace LAB to XYZ
# @description: Builds a synthetic LAB image with known L*=50, a*=0, b*=0 and converts it to XYZ via Vips::Image#colourspace, verifying band count, interpretation, and that Y lands close to the published value for a neutral 50%% lightness.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Build a 3-band float image tagged as LAB with L=50, a=0, b=0.
lab = Vips::Image.black(4, 4, bands: 3)
  .cast(:double)
  .linear([1.0, 1.0, 1.0], [50.0, 0.0, 0.0])
  .copy(interpretation: :lab)
raise "lab interp" unless lab.interpretation == :lab
raise "lab bands" unless lab.bands == 3

xyz = lab.colourspace(:xyz)
raise "xyz interp" unless xyz.interpretation == :xyz
raise "xyz bands" unless xyz.bands == 3
raise "xyz dims" unless xyz.width == 4 && xyz.height == 4

x, y, z = xyz.getpoint(2, 2)
# For L*=50, neutral grey, expected Y ~= 18.42 (CIE D65 reference). X and Z
# scale alongside Y for a perfectly neutral input.
raise "xyz Y out of range #{y}" unless (y - 18.42).abs < 1.0
raise "xyz X plausibility #{x}" unless x > 10.0 && x < 30.0
raise "xyz Z plausibility #{z}" unless z > 10.0 && z < 30.0

puts "lab_to_xyz Y=#{y.round(3)}"
RUBY
