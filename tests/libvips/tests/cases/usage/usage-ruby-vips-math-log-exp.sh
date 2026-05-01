#!/usr/bin/env bash
# @testcase: usage-ruby-vips-math-log-exp
# @title: ruby-vips math log followed by exp roundtrip
# @description: Applies Vips::Image#math(:log) to a positive double image and then math(:exp) to the result, verifying that the recovered values match the original samples within floating-point tolerance.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

orig = [1.0, 2.0, 2.71828182845, 7.5, 10.0, 100.0]
img = Vips::Image.new_from_memory(orig.pack('d*'),
                                  orig.length, 1, 1, :double)

ln = img.math(:log)
orig.each_with_index do |v, x|
  got = ln.getpoint(x, 0)[0]
  raise "log(#{v})=#{got} want #{Math.log(v)}" unless (got - Math.log(v)).abs < 1e-9
end

restored = ln.math(:exp)
orig.each_with_index do |v, x|
  got = restored.getpoint(x, 0)[0]
  raise "exp(log(#{v}))=#{got}" unless (got - v).abs < 1e-6
end

puts "math log/exp roundtrip ok"
RUBY
