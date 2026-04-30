#!/usr/bin/env bash
# @testcase: usage-ruby-vips-rint-banker
# @title: ruby-vips rint rounds to nearest with banker rounding
# @description: Applies Vips::Image#rint to a synthetic float image including half-integer ties and verifies the result rounds to the nearest integer using libvips' banker (round-half-to-even) rule for ties.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# rint follows the C library's nearbyint/rint (banker rounding under the
# default rounding mode). Include both ties (0.5, 1.5, 2.5) and clear cases.
values = [-1.4, -0.5, 0.5, 1.5, 2.5, 2.6]
src = Vips::Image.new_from_memory(values.pack('d*'), values.length, 1, 1, :double)
raise "src dims" unless src.width == values.length && src.height == 1

rounded = src.rint
raise "rint dims" unless rounded.width == values.length && rounded.height == 1

# Clear-cut cases must hit the obvious nearest integer.
raise "rint(-1.4) #{rounded.getpoint(0, 0)}" unless rounded.getpoint(0, 0)[0] == -1.0
raise "rint(2.6) #{rounded.getpoint(5, 0)}"  unless rounded.getpoint(5, 0)[0] == 3.0

# Banker rounding ties: 0.5 -> 0, 1.5 -> 2, 2.5 -> 2, -0.5 -> 0.
raise "rint(-0.5) #{rounded.getpoint(1, 0)}" unless rounded.getpoint(1, 0)[0] == 0.0
raise "rint(0.5) #{rounded.getpoint(2, 0)}"  unless rounded.getpoint(2, 0)[0] == 0.0
raise "rint(1.5) #{rounded.getpoint(3, 0)}"  unless rounded.getpoint(3, 0)[0] == 2.0
raise "rint(2.5) #{rounded.getpoint(4, 0)}"  unless rounded.getpoint(4, 0)[0] == 2.0

# rint should be idempotent on already-integer values.
again = rounded.rint
(0...values.length).each do |x|
  raise "idempotent #{x}" unless again.getpoint(x, 0) == rounded.getpoint(x, 0)
end

puts "rint #{(0...values.length).map { |x| rounded.getpoint(x, 0)[0] }.inspect}"
RUBY
