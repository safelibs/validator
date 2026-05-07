#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r12-multiply-constant-three-triples-mean
# @title: ruby-vips Image#* by 3 triples a constant-10 image to mean 30
# @description: Builds a 6x4 constant-10 uchar image and verifies (img * 3).avg == 30.0 exactly, asserting libvips scalar multiplication promotes safely and produces the expected arithmetic mean.
# @timeout: 60
# @tags: usage, vips, ruby, arithmetic, multiply
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(6, 4) + 10).cast(:uchar)
v = (img * 3).avg
raise "multiply avg=#{v}" unless v == 30.0
puts "img * 3 avg=#{v}"
RUBY
