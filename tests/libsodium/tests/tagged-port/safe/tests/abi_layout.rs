use sodium::abi::types::*;
use std::mem::{align_of, size_of};

fn assert_layout_for<T>(name: &str, expected_size: usize, expected_align: usize) {
    assert_eq!(size_of::<T>(), expected_size, "size mismatch for {name}");
    assert_eq!(
        align_of::<T>(),
        expected_align,
        "alignment mismatch for {name}"
    );
}

fn assert_layout_and_statebytes_for<T>(
    name: &str,
    expected_size: usize,
    expected_align: usize,
    expected_statebytes: usize,
) {
    assert_layout_for::<T>(name, expected_size, expected_align);
    assert_eq!(
        size_of::<T>(),
        expected_statebytes,
        "statebytes mismatch for {name}"
    );
}

#[test]
fn public_state_layouts_match_headers() {
    assert_layout_and_statebytes_for::<crypto_aead_aes256gcm_state>(
        "crypto_aead_aes256gcm_state",
        CRYPTO_AEAD_AES256GCM_STATE_SIZE,
        CRYPTO_AEAD_AES256GCM_STATE_ALIGN,
        CRYPTO_AEAD_AES256GCM_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_auth_hmacsha256_state>(
        "crypto_auth_hmacsha256_state",
        CRYPTO_AUTH_HMACSHA256_STATE_SIZE,
        CRYPTO_AUTH_HMACSHA256_STATE_ALIGN,
        CRYPTO_AUTH_HMACSHA256_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_auth_hmacsha512_state>(
        "crypto_auth_hmacsha512_state",
        CRYPTO_AUTH_HMACSHA512_STATE_SIZE,
        CRYPTO_AUTH_HMACSHA512_STATE_ALIGN,
        CRYPTO_AUTH_HMACSHA512_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_auth_hmacsha512256_state>(
        "crypto_auth_hmacsha512256_state",
        CRYPTO_AUTH_HMACSHA512256_STATE_SIZE,
        CRYPTO_AUTH_HMACSHA512256_STATE_ALIGN,
        CRYPTO_AUTH_HMACSHA512256_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_generichash_blake2b_state>(
        "crypto_generichash_blake2b_state",
        CRYPTO_GENERICHASH_BLAKE2B_STATE_SIZE,
        CRYPTO_GENERICHASH_BLAKE2B_STATE_ALIGN,
        CRYPTO_GENERICHASH_BLAKE2B_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_generichash_state>(
        "crypto_generichash_state",
        CRYPTO_GENERICHASH_STATE_SIZE,
        CRYPTO_GENERICHASH_STATE_ALIGN,
        CRYPTO_GENERICHASH_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_onetimeauth_poly1305_state>(
        "crypto_onetimeauth_poly1305_state",
        CRYPTO_ONETIMEAUTH_POLY1305_STATE_SIZE,
        CRYPTO_ONETIMEAUTH_POLY1305_STATE_ALIGN,
        CRYPTO_ONETIMEAUTH_POLY1305_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_onetimeauth_state>(
        "crypto_onetimeauth_state",
        CRYPTO_ONETIMEAUTH_STATE_SIZE,
        CRYPTO_ONETIMEAUTH_STATE_ALIGN,
        CRYPTO_ONETIMEAUTH_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_hash_sha256_state>(
        "crypto_hash_sha256_state",
        CRYPTO_HASH_SHA256_STATE_SIZE,
        CRYPTO_HASH_SHA256_STATE_ALIGN,
        CRYPTO_HASH_SHA256_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_hash_sha512_state>(
        "crypto_hash_sha512_state",
        CRYPTO_HASH_SHA512_STATE_SIZE,
        CRYPTO_HASH_SHA512_STATE_ALIGN,
        CRYPTO_HASH_SHA512_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_secretstream_xchacha20poly1305_state>(
        "crypto_secretstream_xchacha20poly1305_state",
        CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_STATE_SIZE,
        CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_STATE_ALIGN,
        CRYPTO_SECRETSTREAM_XCHACHA20POLY1305_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_sign_ed25519ph_state>(
        "crypto_sign_ed25519ph_state",
        CRYPTO_SIGN_ED25519PH_STATE_SIZE,
        CRYPTO_SIGN_ED25519PH_STATE_ALIGN,
        CRYPTO_SIGN_ED25519PH_STATE_STATEBYTES,
    );
    assert_layout_and_statebytes_for::<crypto_sign_state>(
        "crypto_sign_state",
        CRYPTO_SIGN_STATE_SIZE,
        CRYPTO_SIGN_STATE_ALIGN,
        CRYPTO_SIGN_STATE_STATEBYTES,
    );
    assert_layout_for::<randombytes_implementation>(
        "randombytes_implementation",
        RANDOMBYTES_IMPLEMENTATION_SIZE,
        RANDOMBYTES_IMPLEMENTATION_ALIGN,
    );
}
