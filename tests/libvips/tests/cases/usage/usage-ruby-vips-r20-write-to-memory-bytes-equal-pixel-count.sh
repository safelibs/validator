#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r20-write-to-memory-bytes-equal-pixel-count
# @title: ruby-vips Image#write_to_memory length equals width*height*bands for uchar
# @description: Builds a 9x5 single-band uchar image, calls .write_to_memory, and asserts the resulting binary string has bytesize equal to 9*5*1 (no padding) and the first byte equals the constant pixel value 33, confirming libvips' raw memory write yields a contiguous pixel buffer with no row padding.
# @timeout: 60
# @tags: usage, vips, ruby, memory, write-to-memory, r20
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(9, 5) + 33).cast(:uchar)
mem = src.write_to_memory
raise "bytesize=#{mem.bytesize}" unless mem.bytesize == 9 * 5 * 1
raise "byte0=#{mem.getbyte(0)}" unless mem.getbyte(0) == 33
raise "byte_last=#{mem.getbyte(-1)}" unless mem.getbyte(-1) == 33
puts "ok write_to_memory bytes=#{mem.bytesize}"
RUBY
