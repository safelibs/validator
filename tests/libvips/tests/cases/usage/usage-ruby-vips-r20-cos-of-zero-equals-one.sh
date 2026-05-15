#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-cos-of-zero-equals-one
# @title: ruby-vips Image#cos on a zero-valued image returns one
# @description: Builds a 6x6 black (all zero) image cast to float, calls .cos, and asserts the avg, min, and max of the result are all within 1e-9 of 1.0 (cos(0)==1), confirming libvips' libm-backed cosine operator returns the documented constant-input value.
# @timeout: 60
# @tags: usage, vips, ruby, cos, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = Vips::Image.black(6, 6).cast(:float)
out = src.cos
raise "avg=#{out.avg}" unless (out.avg - 1.0).abs < 1e-9
raise "min=#{out.min}" unless (out.min - 1.0).abs < 1e-9
raise "max=#{out.max}" unless (out.max - 1.0).abs < 1e-9
puts "ok cos(0)=1"
RUBY
