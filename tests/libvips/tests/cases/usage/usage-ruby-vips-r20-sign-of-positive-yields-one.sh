#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-sign-of-positive-yields-one
# @title: ruby-vips Image#sign on a positive-constant image returns 1
# @description: Builds a 5x5 image with constant value 42 cast to float, calls .sign, and asserts the avg/min/max of the result are all exactly 1.0, confirming libvips' sign-of operator returns +1 for strictly positive input.
# @timeout: 60
# @tags: usage, vips, ruby, sign, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(5, 5) + 42).cast(:float)
out = src.sign
raise "avg=#{out.avg}" unless (out.avg - 1.0).abs < 1e-9
raise "min=#{out.min}" unless (out.min - 1.0).abs < 1e-9
raise "max=#{out.max}" unless (out.max - 1.0).abs < 1e-9
puts "ok sign(+42)=1"
RUBY
