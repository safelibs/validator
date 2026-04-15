use sodium::core::ed25519 as core_ed25519;
use sodium::foundation::core as sodium_core;
use sodium::scalarmult::ed25519 as scalarmult_ed25519;
use sodium::sign;
use sodium::sign::ed25519 as sign_ed25519;
use std::sync::Once;

static INIT: Once = Once::new();

const NOT_MAIN_SUBGROUP_P: [u8; 32] = [
    0x95, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99,
    0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99, 0x99,
    0x99, 0x99,
];

const KEYPAIR_SEED: [u8; 32] = [
    0x42, 0x11, 0x51, 0xa4, 0x59, 0xfa, 0xea, 0xde, 0x3d, 0x24, 0x71, 0x15, 0xf9, 0x4a, 0xed,
    0xae, 0x42, 0x31, 0x81, 0x24, 0x09, 0x5a, 0xfa, 0xbe, 0x4d, 0x14, 0x51, 0xa5, 0x59, 0xfa,
    0xed, 0xee,
];

fn init() {
    INIT.call_once(|| {
        let ret = sodium_core::sodium_init();
        assert!(ret == 0 || ret == 1);
    });
}

#[test]
fn invalid_subgroup_point_is_rejected_across_public_ed25519_entry_points() {
    init();

    assert_eq!(
        core_ed25519::crypto_core_ed25519_is_valid_point(NOT_MAIN_SUBGROUP_P.as_ptr()),
        0
    );

    let mut scalar = [0u8; 32];
    scalar[0] = 1;
    let mut base = [0u8; 32];
    assert_eq!(
        scalarmult_ed25519::crypto_scalarmult_ed25519_base_noclamp(
            base.as_mut_ptr(),
            scalar.as_ptr(),
        ),
        0
    );

    let mut out = [0u8; 32];
    assert_eq!(
        scalarmult_ed25519::crypto_scalarmult_ed25519(out.as_mut_ptr(), scalar.as_ptr(), NOT_MAIN_SUBGROUP_P.as_ptr()),
        -1
    );
    assert_eq!(
        scalarmult_ed25519::crypto_scalarmult_ed25519_noclamp(
            out.as_mut_ptr(),
            scalar.as_ptr(),
            NOT_MAIN_SUBGROUP_P.as_ptr(),
        ),
        -1
    );
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_pk_to_curve25519(out.as_mut_ptr(), NOT_MAIN_SUBGROUP_P.as_ptr()),
        -1
    );

    let message = b"cve-2025-69277";
    let mut pk = [0u8; 32];
    let mut sk = [0u8; 64];
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_seed_keypair(pk.as_mut_ptr(), sk.as_mut_ptr(), KEYPAIR_SEED.as_ptr()),
        0
    );
    let mut sig = [0u8; 64];
    let mut siglen = 0u64;
    assert_eq!(
        sign::crypto_sign_detached(
            sig.as_mut_ptr(),
            &mut siglen,
            message.as_ptr(),
            message.len() as u64,
            sk.as_ptr(),
        ),
        0
    );
    assert_eq!(siglen, 64);
    assert_eq!(
        sign::crypto_sign_verify_detached(
            sig.as_ptr(),
            message.as_ptr(),
            message.len() as u64,
            NOT_MAIN_SUBGROUP_P.as_ptr(),
        ),
        -1
    );
}
