use sodium::foundation::{codecs, core, randombytes, utils, verify, version};
use std::ffi::CStr;

unsafe extern "C" {
    fn sodium_runtime_has_neon() -> i32;
    fn sodium_runtime_has_sse2() -> i32;
    fn sodium_runtime_has_sse3() -> i32;
    fn sodium_runtime_has_ssse3() -> i32;
    fn sodium_runtime_has_sse41() -> i32;
    fn sodium_runtime_has_avx() -> i32;
    fn sodium_runtime_has_avx2() -> i32;
    fn sodium_runtime_has_avx512f() -> i32;
    fn sodium_runtime_has_pclmul() -> i32;
    fn sodium_runtime_has_aesni() -> i32;
    fn sodium_runtime_has_rdrand() -> i32;
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

#[test]
fn sodium_init_is_idempotent_and_runtime_exports_are_callable() {
    let first = core::sodium_init();
    assert!(first == 0 || first == 1);
    assert_eq!(core::sodium_init(), 1);

    unsafe {
        let _ = sodium_runtime_has_neon();
        let _ = sodium_runtime_has_sse2();
        let _ = sodium_runtime_has_sse3();
        let _ = sodium_runtime_has_ssse3();
        let _ = sodium_runtime_has_sse41();
        let _ = sodium_runtime_has_avx();
        let _ = sodium_runtime_has_avx2();
        let _ = sodium_runtime_has_avx512f();
        let _ = sodium_runtime_has_pclmul();
        let _ = sodium_runtime_has_aesni();
        let _ = sodium_runtime_has_rdrand();
    }
}

#[test]
fn version_exports_match_upstream() {
    let version_string = unsafe { CStr::from_ptr(version::sodium_version_string()) };
    assert_eq!(version_string.to_str().unwrap(), "1.0.18");
    assert_eq!(version::sodium_library_version_major(), 10);
    assert_eq!(version::sodium_library_version_minor(), 3);
    assert_eq!(version::sodium_library_minimal(), 0);
}

#[test]
fn randombytes_deterministic_matches_upstream_vector() {
    let seed: Vec<u8> = (0u8..32).collect();
    let mut out = [0u8; 100];

    randombytes::randombytes_buf_deterministic(out.as_mut_ptr().cast(), out.len(), seed.as_ptr());

    assert_eq!(
        hex(&out),
        "0d8e6cc68715648926732e7ea73250cfaf2d58422083904c841a8ba33b986111f346ba50723a68ae283524a6bded09f83be6b80595856f72e25b86918e8b114bafb94bc8abedd73daab454576b7c5833eb0bf982a1bb4587a5c970ff0810ca3b791d7e12"
    );

    let mut out2 = [0u8; 100];
    randombytes::randombytes_buf_deterministic(out2.as_mut_ptr().cast(), out2.len(), seed.as_ptr());
    assert_eq!(out, out2);

    assert_eq!(randombytes::randombytes_seedbytes(), 32);
    assert_eq!(randombytes::randombytes_uniform(1), 0);
}

#[test]
fn codecs_match_upstream_examples() {
    let mut hex_buf = [0i8; 33];
    let encoded = codecs::sodium_bin2hex(
        hex_buf.as_mut_ptr(),
        hex_buf.len(),
        b"0123456789ABCDEF".as_ptr(),
        16,
    );
    let encoded = unsafe { CStr::from_ptr(encoded) };
    assert_eq!(
        encoded.to_str().unwrap(),
        "30313233343536373839414243444546"
    );

    let hex_src = b"Cafe : 6942";
    let mut out = [0u8; 4];
    let mut out_len = 0usize;
    let mut end = std::ptr::null();
    assert_eq!(
        codecs::sodium_hex2bin(
            out.as_mut_ptr(),
            out.len(),
            hex_src.as_ptr().cast(),
            hex_src.len(),
            b": \0".as_ptr().cast(),
            &mut out_len,
            &mut end,
        ),
        0
    );
    assert_eq!(out_len, 4);
    assert_eq!(&out, b"\xca\xfe\x69\x42");
    assert_eq!(unsafe { end.offset_from(hex_src.as_ptr().cast()) }, 11);

    let mut b64 = [0i8; 33];
    let b64_ptr = codecs::sodium_bin2base64(
        b64.as_mut_ptr(),
        b64.len(),
        b"\xfb\xf0\xf10123456789ABCDEFabc".as_ptr(),
        22,
        3,
    );
    let b64 = unsafe { CStr::from_ptr(b64_ptr) };
    assert_eq!(b64.to_str().unwrap(), "+/DxMDEyMzQ1Njc4OUFCQ0RFRmFiYw");
}

#[test]
fn verify_helpers_match_upstream_semantics() {
    let left16 = [7u8; 16];
    let right16 = [7u8; 16];
    let mut diff16 = right16;
    diff16[3] ^= 1;

    assert_eq!(
        verify::crypto_verify_16(left16.as_ptr(), right16.as_ptr()),
        0
    );
    assert_eq!(
        verify::crypto_verify_16(left16.as_ptr(), diff16.as_ptr()),
        -1
    );
    assert_eq!(verify::crypto_verify_16_bytes(), 16);
    assert_eq!(verify::crypto_verify_32_bytes(), 32);
    assert_eq!(verify::crypto_verify_64_bytes(), 64);
}

#[test]
fn utils_arithmetic_padding_and_allocator_behave_like_upstream() {
    let mut buf = [0u8; 24];
    utils::sodium_increment(buf.as_mut_ptr(), buf.len());
    assert_eq!(
        hex(&buf),
        "010000000000000000000000000000000000000000000000"
    );

    buf.fill(0xff);
    utils::sodium_increment(buf.as_mut_ptr(), buf.len());
    assert_eq!(
        hex(&buf),
        "000000000000000000000000000000000000000000000000"
    );

    let mut addend = [0u8; 24];
    addend[1] = 1;
    utils::sodium_add(buf.as_mut_ptr(), addend.as_ptr(), buf.len());
    assert_eq!(
        hex(&buf),
        "000100000000000000000000000000000000000000000000"
    );
    utils::sodium_sub(buf.as_mut_ptr(), addend.as_ptr(), buf.len());
    assert_eq!(
        hex(&buf),
        "000000000000000000000000000000000000000000000000"
    );
    assert_eq!(utils::sodium_is_zero(buf.as_ptr(), buf.len()), 1);

    let left = [1u8, 2, 3, 4];
    let mut right = left;
    assert_eq!(
        utils::sodium_memcmp(left.as_ptr().cast(), right.as_ptr().cast(), left.len()),
        0
    );
    right[3] = 5;
    assert_eq!(
        utils::sodium_memcmp(left.as_ptr().cast(), right.as_ptr().cast(), left.len()),
        -1
    );
    assert!(utils::sodium_compare(left.as_ptr(), right.as_ptr(), left.len()) < 0);

    let mut padded = [0x55u8; 16];
    let mut padded_len = 0usize;
    assert_eq!(
        utils::sodium_pad(&mut padded_len, padded.as_mut_ptr(), 5, 4, padded.len()),
        0
    );
    let mut unpadded_len = 0usize;
    assert_eq!(
        utils::sodium_unpad(&mut unpadded_len, padded.as_ptr(), padded_len, 4),
        0
    );
    assert_eq!(unpadded_len, 5);

    let ptr = utils::sodium_malloc(64).cast::<u8>();
    assert!(!ptr.is_null());
    unsafe {
        for i in 0..64 {
            *ptr.add(i) = i as u8;
        }
    }
    assert_eq!(utils::sodium_mprotect_readwrite(ptr.cast()), 0);
    assert_eq!(utils::sodium_mprotect_noaccess(ptr.cast()), 0);
    utils::sodium_free(ptr.cast());
}
