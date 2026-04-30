#!/usr/bin/env bash
# @testcase: usage-ruby-vips-matrixload-external-file
# @title: ruby-vips matrixload reads external matrix file
# @description: Writes a small 3x2 matrix to disk in libvips matrix-text format, loads it back through Vips::Image.matrixload, and verifies dimensions plus individual cell values via getpoint.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# libvips matrix file format: header line "<width> <height>" followed by
# height rows of width whitespace-separated numbers.
matrix_path="$tmpdir/kernel.mat"
cat >"$matrix_path" <<'MATRIX'
3 2
1.0 2.0 3.0
4.0 5.0 6.0
MATRIX
validator_require_file "$matrix_path"

ruby -rvips - "$tmpdir" "$matrix_path" <<'RUBY'
tmpdir = ARGV[0]
matrix_path = ARGV[1]

m = Vips::Image.matrixload(matrix_path)
raise "matrix dims #{m.width}x#{m.height}" unless m.width == 3 && m.height == 2
raise "matrix bands #{m.bands}" unless m.bands == 1

cells = (0...2).map do |y|
  (0...3).map { |x| m.getpoint(x, y)[0] }
end
expected = [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
unless cells.flatten.zip(expected.flatten).all? { |got, want| (got - want).abs < 1e-6 }
  raise "matrix values #{cells.inspect}"
end

# Round-trip via matrixsave so we exercise the reverse operation too.
out_path = File.join(tmpdir, "kernel-roundtrip.mat")
m.matrixsave(out_path)
raise "missing matrix roundtrip" unless File.size?(out_path)

reload = Vips::Image.matrixload(out_path)
raise "reload dims" unless reload.width == 3 && reload.height == 2
raise "reload value" unless (reload.getpoint(2, 1)[0] - 6.0).abs < 1e-6
puts "matrixload cells=#{cells.inspect}"
RUBY

# Header line should round-trip in the saved file.
grep -q '^3 2$' "$tmpdir/kernel-roundtrip.mat" || { echo "matrix header missing in $tmpdir/kernel-roundtrip.mat" >&2; exit 1; }
