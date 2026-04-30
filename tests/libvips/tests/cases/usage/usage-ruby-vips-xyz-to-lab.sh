#!/usr/bin/env bash
# @testcase: usage-ruby-vips-xyz-to-lab
# @title: ruby-vips colourspace XYZ to LAB
# @description: Builds a synthetic XYZ image with the D65 white point reference (X=95.047, Y=100, Z=108.883) and converts it to LAB via Vips::Image#colourspace, verifying L* lands at 100 and a*/b* land near zero.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Build a 3-band double image tagged as XYZ at the D65 white point.
xyz = Vips::Image.black(4, 4, bands: 3)
  .cast(:double)
  .linear([1.0, 1.0, 1.0], [95.047, 100.0, 108.883])
  .copy(interpretation: :xyz)
raise "xyz interp" unless xyz.interpretation == :xyz
raise "xyz bands" unless xyz.bands == 3

lab = xyz.colourspace(:lab)
raise "lab interp" unless lab.interpretation == :lab
raise "lab bands" unless lab.bands == 3
raise "lab dims" unless lab.width == 4 && lab.height == 4

l, a, b = lab.getpoint(1, 1)
raise "L* not 100 (#{l})" unless (l - 100.0).abs < 0.5
raise "a* not ~0 (#{a})" unless a.abs < 0.5
raise "b* not ~0 (#{b})" unless b.abs < 0.5
puts "xyz_to_lab L*=#{l.round(3)} a*=#{a.round(3)} b*=#{b.round(3)}"
RUBY
