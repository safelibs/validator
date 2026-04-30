#!/usr/bin/env bash
# @testcase: usage-ruby-vips-ifthenelse-comparison-mask
# @title: ruby-vips ifthenelse with computed comparison condition
# @description: Builds a single-band gradient image, derives the boolean condition mask from a relational comparison, and uses Vips::Image#ifthenelse to select between two single-band sources, verifying the per-pixel selection follows the comparison.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 1-band 4x1 gradient: 10, 50, 100, 200.
src = Vips::Image.new_from_memory([10, 50, 100, 200].pack('C*'), 4, 1, 1, :uchar)
raise "src bands" unless src.bands == 1
raise "src dims" unless src.width == 4 && src.height == 1

# Build the mask via a comparison: pixels > 75 -> 255, else 0.
cond = (src > 75)
raise "cond bands" unless cond.bands == 1
raise "cond dims" unless cond.width == 4 && cond.height == 1
# Spot-check the comparison itself before feeding ifthenelse.
raise "cond[0] #{cond.getpoint(0, 0)}" unless cond.getpoint(0, 0) == [0.0]
raise "cond[1] #{cond.getpoint(1, 0)}" unless cond.getpoint(1, 0) == [0.0]
raise "cond[2] #{cond.getpoint(2, 0)}" unless cond.getpoint(2, 0) == [255.0]
raise "cond[3] #{cond.getpoint(3, 0)}" unless cond.getpoint(3, 0) == [255.0]

then_image = Vips::Image.new_from_memory([1, 2, 3, 4].pack('C*'), 4, 1, 1, :uchar)
else_image = Vips::Image.new_from_memory([91, 92, 93, 94].pack('C*'), 4, 1, 1, :uchar)

out = cond.ifthenelse(then_image, else_image)
raise "out bands" unless out.bands == 1
raise "out dims" unless out.width == 4 && out.height == 1

# Where comparison was true (src > 75) the then-image wins; otherwise else-image.
expected = [91, 92, 3, 4]
got = out.cast(:uchar).write_to_memory.bytes
raise "ifthenelse mismatch #{got.inspect}" unless got == expected

out_path = File.join(tmpdir, "ifthenelse_cmp.png")
out.cast(:uchar).write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "ifthenelse_cmp #{got.join(',')}"
RUBY

file "$tmpdir/ifthenelse_cmp.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/ifthenelse_cmp.png")" >&2; exit 1; }
