#!/usr/bin/env bash
# @testcase: usage-ruby-vips-project-row-column-sums
# @title: ruby-vips project row and column sums
# @description: Builds a small grayscale image with known per-row and per-column sums, calls Vips::Image#project, and verifies that the returned columns image is one row tall, the rows image is one column wide, and that the sums match the analytic expectations.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 3x2 image. Column sums: 1+4=5, 2+5=7, 3+6=9. Row sums: 1+2+3=6, 4+5+6=15.
src = Vips::Image.new_from_array([
  [1, 2, 3],
  [4, 5, 6],
])

cols, rows = src.project
raise "cols dims #{cols.width}x#{cols.height}" unless cols.width == src.width && cols.height == 1
raise "rows dims #{rows.width}x#{rows.height}" unless rows.width == 1 && rows.height == src.height

expected_cols = [5.0, 7.0, 9.0]
expected_rows = [6.0, 15.0]

expected_cols.each_with_index do |v, x|
  got = cols.getpoint(x, 0).first
  raise "col #{x} got=#{got} want=#{v}" unless got == v
end

expected_rows.each_with_index do |v, y|
  got = rows.getpoint(0, y).first
  raise "row #{y} got=#{got} want=#{v}" unless got == v
end

puts "project cols=#{expected_cols.inspect} rows=#{expected_rows.inspect}"
RUBY
