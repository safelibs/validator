#!/usr/bin/env bash
# @testcase: usage-ruby-vips-cast-double-precision
# @title: ruby-vips cast to double preserves precision
# @description: Casts a uchar image divided by a non-power-of-two scalar to :double and verifies the result reports the double format and preserves a fractional pixel value beyond uchar precision.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

src = (Vips::Image.black(2, 1) + [100]).cast(:uchar)
raise "src format" unless src.format.to_s == "uchar"
raise "src pt" unless src.getpoint(0, 0) == [100.0]

# Cast the source to :double FIRST so the subsequent divide stays in
# 64-bit floating-point space. Dividing a uchar image by a scalar in vips
# upcasts only as far as :float (32-bit), which is not enough to preserve
# 100/3 below ~1e-7.
src_d = src.cast(:double)
out = src_d / 3.0
raise "cast format" unless out.format.to_s == "double"
raise "cast dims" unless out.width == 2 && out.height == 1

pt = out.getpoint(0, 0)[0]
expected = 100.0 / 3.0
raise "double precision #{pt} vs #{expected}" unless (pt - expected).abs < 1e-12

# Round-trip back through a casted double image to confirm precision is real.
diff = out - expected
raise "max diff" unless diff.abs.max < 1e-12
puts "cast double pt=#{pt} expected=#{expected}"
RUBY
