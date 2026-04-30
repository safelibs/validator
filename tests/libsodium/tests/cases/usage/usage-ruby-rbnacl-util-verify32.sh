#!/usr/bin/env bash
# @testcase: usage-ruby-rbnacl-util-verify32
# @title: RbNaCl Util.verify32 constant-time comparison
# @description: Exercises the constant-time comparators RbNaCl::Util.verify32 and RbNaCl::Util.verify16 on equal byte strings, on strings differing in the first byte, on strings differing in the last byte, and on inputs of the wrong length, asserting the boolean return for equal/unequal and that wrong-length inputs do not return true.
# @timeout: 180
# @tags: usage, crypto, util, ruby
# @client: ruby-rbnacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rrbnacl -e '
a32 = ("\x10".b * 32)
b32 = a32.dup
raise "verify32 false-negative" unless RbNaCl::Util.verify32(a32, b32)

# Differ in the first byte.
diff_first = a32.dup
diff_first.setbyte(0, diff_first.getbyte(0) ^ 0x01)
raise "verify32 false-positive (first byte)" if RbNaCl::Util.verify32(a32, diff_first)

# Differ in the last byte.
diff_last = a32.dup
diff_last.setbyte(31, diff_last.getbyte(31) ^ 0x01)
raise "verify32 false-positive (last byte)" if RbNaCl::Util.verify32(a32, diff_last)

# Wrong length must not return true.
short = ("\x10".b * 31)
ok_short = false
begin
  ok_short = RbNaCl::Util.verify32(a32, short)
rescue ArgumentError, RbNaCl::LengthError
  ok_short = false
end
raise "verify32 accepted wrong-length input" if ok_short

# verify16 mirror check on the same shape.
a16 = ("\xa5".b * 16)
b16 = a16.dup
raise "verify16 false-negative" unless RbNaCl::Util.verify16(a16, b16)
diff16 = a16.dup
diff16.setbyte(0, diff16.getbyte(0) ^ 0x80)
raise "verify16 false-positive" if RbNaCl::Util.verify16(a16, diff16)

puts "ok"
'
