use curve25519_dalek::edwards::EdwardsPoint;
use curve25519_dalek::scalar::Scalar;
use sha2::{Digest, Sha512};
use sodium::box_api;
use sodium::box_api::curve25519xchacha20poly1305 as box_xchacha;
use sodium::core::ed25519 as core_ed25519;
use sodium::core::ristretto255 as core_ristretto255;
use sodium::foundation::core as sodium_core;
use sodium::kx;
use sodium::scalarmult;
use sodium::scalarmult::ed25519 as scalarmult_ed25519;
use sodium::scalarmult::ristretto255 as scalarmult_ristretto255;
use sodium::sign;
use sodium::sign::ed25519 as sign_ed25519;
use sodium::sign::legacy_edwards25519sha512batch as legacy_sign;
use std::ffi::CStr;
use std::ptr;
use std::sync::Once;

static INIT: Once = Once::new();

const SMALL_ORDER_P: [u8; 32] = [
    0xe0, 0xeb, 0x7a, 0x7c, 0x3b, 0x41, 0xb8, 0xae, 0x16, 0x56, 0xe3, 0xfa, 0xf1, 0x9f, 0xc4,
    0x6a, 0xda, 0x09, 0x8d, 0xeb, 0x9c, 0x32, 0xb1, 0xfd, 0x86, 0x62, 0x05, 0x16, 0x5f, 0x49,
    0xb8, 0x00,
];

const NON_CANONICAL_P: [u8; 32] = [
    0xf6, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0x7f,
];

const NON_CANONICAL_INVALID_P: [u8; 32] = [
    0xf5, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0x7f,
];

const MAX_CANONICAL_P: [u8; 32] = [
    0xe4, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0x7f,
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

fn hex_decode(input: &str) -> Vec<u8> {
    assert_eq!(input.len() % 2, 0, "hex input must have even length");
    input
        .as_bytes()
        .chunks_exact(2)
        .map(|chunk| {
            let hi = (chunk[0] as char).to_digit(16).unwrap();
            let lo = (chunk[1] as char).to_digit(16).unwrap();
            ((hi << 4) | lo) as u8
        })
        .collect()
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

fn scalar_bytes(descending_from: u8) -> [u8; 32] {
    let mut out = [0u8; 32];
    for (i, byte) in out.iter_mut().enumerate() {
        *byte = descending_from.wrapping_sub(i as u8);
    }
    out
}

fn clamp_ed25519_scalar(mut bytes: [u8; 32]) -> [u8; 32] {
    bytes[0] &= 248;
    bytes[31] &= 127;
    bytes[31] |= 64;
    bytes
}

#[test]
fn curve25519_scalarmult_matches_upstream_vectors() {
    init();

    let alicesk = [
        0x77, 0x07, 0x6d, 0x0a, 0x73, 0x18, 0xa5, 0x7d, 0x3c, 0x16, 0xc1, 0x72, 0x51, 0xb2,
        0x66, 0x45, 0xdf, 0x4c, 0x2f, 0x87, 0xeb, 0xc0, 0x99, 0x2a, 0xb1, 0x77, 0xfb, 0xa5,
        0x1d, 0xb9, 0x2c, 0x2a,
    ];
    let bobsk = [
        0x5d, 0xab, 0x08, 0x7e, 0x62, 0x4a, 0x8a, 0x4b, 0x79, 0xe1, 0x7f, 0x8b, 0x83, 0x80,
        0x0e, 0xe6, 0x6f, 0x3b, 0xb1, 0x29, 0x26, 0x18, 0xb6, 0xfd, 0x1c, 0x2f, 0x8b, 0x27,
        0xff, 0x88, 0xe0, 0xeb,
    ];

    let mut alicepk = [0u8; 32];
    let mut bobpk = [0u8; 32];
    let mut shared = [0u8; 32];

    assert_eq!(
        scalarmult::crypto_scalarmult_base(alicepk.as_mut_ptr(), alicesk.as_ptr()),
        0
    );
    assert_eq!(hex(&alicepk), "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a");

    assert_eq!(
        scalarmult::crypto_scalarmult_base(bobpk.as_mut_ptr(), bobsk.as_ptr()),
        0
    );
    assert_eq!(hex(&bobpk), "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f");

    assert_eq!(
        scalarmult::crypto_scalarmult(shared.as_mut_ptr(), alicesk.as_ptr(), bobpk.as_ptr()),
        0
    );
    assert_eq!(hex(&shared), "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742");

    assert_eq!(
        scalarmult::crypto_scalarmult(shared.as_mut_ptr(), bobsk.as_ptr(), alicepk.as_ptr()),
        0
    );
    assert_eq!(hex(&shared), "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742");

    assert_eq!(
        scalarmult::crypto_scalarmult(shared.as_mut_ptr(), bobsk.as_ptr(), SMALL_ORDER_P.as_ptr()),
        -1
    );

    let primitive = unsafe { CStr::from_ptr(scalarmult::crypto_scalarmult_primitive()) };
    assert_eq!(primitive.to_str().unwrap(), "curve25519");
    assert_eq!(scalarmult::crypto_scalarmult_bytes(), 32);
    assert_eq!(scalarmult::crypto_scalarmult_scalarbytes(), 32);
}

#[test]
fn ed25519_core_and_conversion_vectors_match_upstream() {
    init();

    assert_eq!(
        core_ed25519::crypto_core_ed25519_is_valid_point(MAX_CANONICAL_P.as_ptr()),
        1
    );
    assert_eq!(
        core_ed25519::crypto_core_ed25519_is_valid_point(NON_CANONICAL_INVALID_P.as_ptr()),
        0
    );
    assert_eq!(
        core_ed25519::crypto_core_ed25519_is_valid_point(NON_CANONICAL_P.as_ptr()),
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

    let mut point = [0u8; 32];
    assert_eq!(
        core_ed25519::crypto_core_ed25519_add(point.as_mut_ptr(), base.as_ptr(), NON_CANONICAL_P.as_ptr()),
        0
    );
    assert_eq!(
        core_ed25519::crypto_core_ed25519_sub(point.as_mut_ptr(), point.as_ptr(), NON_CANONICAL_P.as_ptr()),
        0
    );
    assert_eq!(point, base);
    assert_eq!(
        core_ed25519::crypto_core_ed25519_add(
            point.as_mut_ptr(),
            base.as_ptr(),
            NON_CANONICAL_INVALID_P.as_ptr(),
        ),
        -1
    );

    let mut sc = scalar_bytes(255);
    assert_eq!(
        core_ed25519::crypto_core_ed25519_scalar_invert(sc.as_mut_ptr(), sc.as_ptr()),
        0
    );
    assert_eq!(hex(&sc), "5858cdec40a044b1548b3bb08f8ce0d71103d1f887df84ebc502643dac4df40b");
    assert_eq!(
        core_ed25519::crypto_core_ed25519_scalar_invert(sc.as_mut_ptr(), sc.as_ptr()),
        0
    );
    assert_eq!(hex(&sc), "09688ce78a8ff8273f636b0bc748c0cceeeeedecebeae9e8e7e6e5e4e3e2e100");

    sc = scalar_bytes(32);
    assert_eq!(
        core_ed25519::crypto_core_ed25519_scalar_invert(sc.as_mut_ptr(), sc.as_ptr()),
        0
    );
    assert_eq!(hex(&sc), "f70b4f272b47bd6a1015a511fb3c9fc1b9c21ca4ca2e17d5a225b4c410b9b60d");
    assert_eq!(
        core_ed25519::crypto_core_ed25519_scalar_invert(sc.as_mut_ptr(), sc.as_ptr()),
        0
    );
    assert_eq!(hex(&sc), "201f1e1d1c1b1a191817161514131211100f0e0d0c0b0a090807060504030201");

    sc = scalar_bytes(255);
    core_ed25519::crypto_core_ed25519_scalar_negate(sc.as_mut_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "e46b69758fd3193097398c9717b11e48111112131415161718191a1b1c1d1e0f");
    core_ed25519::crypto_core_ed25519_scalar_negate(sc.as_mut_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "09688ce78a8ff8273f636b0bc748c0cceeeeedecebeae9e8e7e6e5e4e3e2e100");

    sc = scalar_bytes(32);
    core_ed25519::crypto_core_ed25519_scalar_negate(sc.as_mut_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "cdb4d73ffe47f83ebe85e18dcae6cc03f0f0f1f2f3f4f5f6f7f8f9fafbfcfd0e");
    core_ed25519::crypto_core_ed25519_scalar_negate(sc.as_mut_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "201f1e1d1c1b1a191817161514131211100f0e0d0c0b0a090807060504030201");

    sc = scalar_bytes(255);
    core_ed25519::crypto_core_ed25519_scalar_complement(sc.as_mut_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "e56b69758fd3193097398c9717b11e48111112131415161718191a1b1c1d1e0f");
    core_ed25519::crypto_core_ed25519_scalar_complement(sc.as_mut_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "09688ce78a8ff8273f636b0bc748c0cceeeeedecebeae9e8e7e6e5e4e3e2e100");

    sc = scalar_bytes(32);
    core_ed25519::crypto_core_ed25519_scalar_complement(sc.as_mut_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "ceb4d73ffe47f83ebe85e18dcae6cc03f0f0f1f2f3f4f5f6f7f8f9fafbfcfd0e");
    core_ed25519::crypto_core_ed25519_scalar_complement(sc.as_mut_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "201f1e1d1c1b1a191817161514131211100f0e0d0c0b0a090807060504030201");

    let mut sc = [0x69u8; 32];
    let sc2 = [0x42u8; 32];
    core_ed25519::crypto_core_ed25519_scalar_add(sc.as_mut_ptr(), sc.as_ptr(), sc2.as_ptr());
    core_ed25519::crypto_core_ed25519_scalar_add(sc.as_mut_ptr(), sc2.as_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "f7567cd87c82ec1c355a6304c143bcc9ecedededededededededededededed0d");
    core_ed25519::crypto_core_ed25519_scalar_sub(sc.as_mut_ptr(), sc2.as_ptr(), sc.as_ptr());
    core_ed25519::crypto_core_ed25519_scalar_sub(sc.as_mut_ptr(), sc.as_ptr(), sc2.as_ptr());
    assert_eq!(hex(&sc), "f67c79849de0253ba142949e1db6224b13121212121212121212121212121202");

    let mut sc = [0xcdu8; 32];
    core_ed25519::crypto_core_ed25519_scalar_add(sc.as_mut_ptr(), sc.as_ptr(), sc2.as_ptr());
    core_ed25519::crypto_core_ed25519_scalar_add(sc.as_mut_ptr(), sc2.as_ptr(), sc.as_ptr());
    assert_eq!(hex(&sc), "b02e8581ce62f69922427c23f970f7e951525252525252525252525252525202");
    core_ed25519::crypto_core_ed25519_scalar_sub(sc.as_mut_ptr(), sc2.as_ptr(), sc.as_ptr());
    core_ed25519::crypto_core_ed25519_scalar_sub(sc.as_mut_ptr(), sc.as_ptr(), sc2.as_ptr());
    assert_eq!(hex(&sc), "3da570db4b001cbeb35a7b7fe588e72aaeadadadadadadadadadadadadadad0d");

    let mut sc = [0x69u8; 32];
    let mut sc2 = [0x42u8; 32];
    for _ in 0..100 {
        core_ed25519::crypto_core_ed25519_scalar_mul(sc.as_mut_ptr(), sc.as_ptr(), sc2.as_ptr());
        core_ed25519::crypto_core_ed25519_scalar_mul(sc2.as_mut_ptr(), sc.as_ptr(), sc2.as_ptr());
    }
    assert_eq!(hex(&sc2), "4453ef38408c06677c1b810e4bf8b1991f01c88716fbfa2f075a518b77da400b");

    let mut pk = [0u8; 32];
    let mut sk = [0u8; 64];
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_seed_keypair(pk.as_mut_ptr(), sk.as_mut_ptr(), KEYPAIR_SEED.as_ptr()),
        0
    );
    assert_eq!(hex(&pk), "b5076a8474a832daee4dd5b4040983b6623b5f344aca57d4d6ee4baf3f259e6e");
    assert_eq!(hex(&sk), "421151a459faeade3d247115f94aedae42318124095afabe4d1451a559faedeeb5076a8474a832daee4dd5b4040983b6623b5f344aca57d4d6ee4baf3f259e6e");

    let mut extracted = [0u8; 32];
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_sk_to_seed(extracted.as_mut_ptr(), sk.as_ptr()),
        0
    );
    assert_eq!(extracted, KEYPAIR_SEED);
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_sk_to_pk(extracted.as_mut_ptr(), sk.as_ptr()),
        0
    );
    assert_eq!(extracted, pk);

    let mut curve_pk = [0u8; 32];
    let mut curve_sk = [0u8; 32];
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_pk_to_curve25519(curve_pk.as_mut_ptr(), pk.as_ptr()),
        0
    );
    assert_eq!(hex(&curve_pk), "f1814f0e8ff1043d8a44d25babff3cedcae6c22c3edaa48f857ae70de2baae50");
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_sk_to_curve25519(curve_sk.as_mut_ptr(), sk.as_ptr()),
        0
    );
    assert_eq!(hex(&curve_sk), "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de166");

    let mut invalid = [0u8; 32];
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_pk_to_curve25519(curve_pk.as_mut_ptr(), invalid.as_ptr()),
        -1
    );
    invalid[0] = 2;
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_pk_to_curve25519(curve_pk.as_mut_ptr(), invalid.as_ptr()),
        -1
    );
    invalid[0] = 5;
    assert_eq!(
        sign_ed25519::crypto_sign_ed25519_pk_to_curve25519(curve_pk.as_mut_ptr(), invalid.as_ptr()),
        -1
    );
}

#[test]
fn ristretto_and_signature_vectors_match_upstream() {
    init();

    let hash_vectors = [
        (
            "5d1be09e3d0c82fc538112490e35701979d99e06ca3e2b5b54bffe8b4dc772c14d98b696a1bbfb5ca32c436cc61c16563790306c79eaca7705668b47dffe5bb6",
            "3066f82a1a747d45120d1740f14358531a8f04bbffe6a819f86dfe50f44a0a46",
        ),
        (
            "f116b34b8f17ceb56e8732a60d913dd10cce47a6d53bee9204be8b44f6678b270102a56902e2488c46120e9276cfe54638286b9e4b3cdb470b542d46c2068d38",
            "f26e5b6f7d362d2d2a94c5d0e7602cb4773c95a2e5c31a64f133189fa76ed61b",
        ),
        (
            "8422e1bbdaab52938b81fd602effb6f89110e1e57208ad12d9ad767e2e25510c27140775f9337088b982d83d7fcf0b2fa1edffe51952cbe7365e95c86eaf325c",
            "006ccd2a9e6867e6a2c5cea83d3302cc9de128dd2a9a57dd8ee7b9d7ffe02826",
        ),
        (
            "ac22415129b61427bf464e17baee8db65940c233b98afce8d17c57beeb7876c2150d15af1cb1fb824bbd14955f2b57d08d388aab431a391cfc33d5bafb5dbbaf",
            "f8f0c87cf237953c5890aec3998169005dae3eca1fbb04548c635953c817f92a",
        ),
        (
            "165d697a1ef3d5cf3c38565beefcf88c0f282b8e7dbd28544c483432f1cec7675debea8ebb4e5fe7d6f6e5db15f15587ac4d4d4a1de7191e0c1ca6664abcc413",
            "ae81e7dedf20a497e10c304a765c1767a42d6e06029758d2d7e8ef7cc4c41179",
        ),
        (
            "a836e6c9a9ca9f1e8d486273ad56a78c70cf18f0ce10abb1c7172ddd605d7fd2979854f47ae1ccf204a33102095b4200e5befc0465accc263175485f0e17ea5c",
            "e2705652ff9f5e44d3e841bf1c251cf7dddb77d140870d1ab2ed64f1a9ce8628",
        ),
        (
            "2cdc11eaeb95daf01189417cdddbf95952993aa9cb9c640eb5058d09702c74622c9965a697a3b345ec24ee56335b556e677b30e6f90ac77d781064f866a3c982",
            "80bd07262511cdde4863f8a7434cef696750681cb9510eea557088f76d9e5065",
        ),
    ];

    let mut point = [0u8; 32];
    for (hash_hex, point_hex) in hash_vectors {
        let hash = hex_decode(hash_hex);
        assert_eq!(
            core_ristretto255::crypto_core_ristretto255_from_hash(point.as_mut_ptr(), hash.as_ptr()),
            0
        );
        assert_eq!(hex(&point), point_hex);
    }

    let basepoint = hex_decode("e2f2ae0a6abc4e71a884a961c500515f58e30b6aa582dd8db6a65945e08d2d76");
    let expected = [
        "0000000000000000000000000000000000000000000000000000000000000000",
        "e2f2ae0a6abc4e71a884a961c500515f58e30b6aa582dd8db6a65945e08d2d76",
        "6a493210f7499cd17fecb510ae0cea23a110e8d5b901f8acadd3095c73a3b919",
        "94741f5d5d52755ece4f23f044ee27d5d1ea1e2bd196b462166b16152a9d0259",
        "da80862773358b466ffadfe0b3293ab3d9fd53c5ea6c955358f568322daf6a57",
        "e882b131016b52c1d3337080187cf768423efccbb517bb495ab812c4160ff44e",
        "f64746d3c92b13050ed8d80236a7f0007c3b3f962f5ba793d19a601ebb1df403",
        "44f53520926ec81fbd5a387845beb7df85a96a24ece18738bdcfa6a7822a176d",
        "903293d8f2287ebe10e2374dc1a53e0bc887e592699f02d077d5263cdd55601c",
        "02622ace8f7303a31cafc63f8fc48fdc16e1c8c8d234b2f0d6685282a9076031",
        "20706fd788b2720a1ed2a5dad4952b01f413bcf0e7564de8cdc816689e2db95f",
        "bce83f8ba5dd2fa572864c24ba1810f9522bc6004afe95877ac73241cafdab42",
        "e4549ee16b9aa03099ca208c67adafcafa4c3f3e4e5303de6026e3ca8ff84460",
        "aa52e000df2e16f55fb1032fc33bc42742dad6bd5a8fc0be0167436c5948501f",
        "46376b80f409b29dc2b5f6f0c52591990896e5716f41477cd30085ab7f10301e",
        "e0c418f7c8d9c4cdd7395b93ea124f3ad99021bb681dfc3302a9d99a2e53e64e",
    ];
    let mut n = [0u8; 32];
    for (i, expected_hex) in expected.iter().enumerate() {
        let ret = scalarmult_ristretto255::crypto_scalarmult_ristretto255_base(
            point.as_mut_ptr(),
            n.as_ptr(),
        );
        if i == 0 {
            assert_eq!(ret, -1);
        } else {
            assert_eq!(ret, 0);
        }
        assert_eq!(hex(&point), *expected_hex);
        let mut other = [0u8; 32];
        let ret = scalarmult_ristretto255::crypto_scalarmult_ristretto255(
            other.as_mut_ptr(),
            n.as_ptr(),
            basepoint.as_ptr(),
        );
        if i == 0 {
            assert_eq!(ret, -1);
        } else {
            assert_eq!(ret, 0);
        }
        assert_eq!(other, point);
        n[0] = n[0].wrapping_add(1);
    }

    let message = b"public-key signatures";
    let mut pk = [0u8; 32];
    let mut sk = [0u8; 64];
    assert_eq!(
        sign::crypto_sign_seed_keypair(pk.as_mut_ptr(), sk.as_mut_ptr(), KEYPAIR_SEED.as_ptr()),
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
        sign::crypto_sign_verify_detached(sig.as_ptr(), message.as_ptr(), message.len() as u64, pk.as_ptr()),
        0
    );

    let mut signed = vec![0u8; message.len() + 64];
    let mut signed_len = 0u64;
    assert_eq!(
        sign::crypto_sign(
            signed.as_mut_ptr(),
            &mut signed_len,
            message.as_ptr(),
            message.len() as u64,
            sk.as_ptr(),
        ),
        0
    );
    assert_eq!(signed_len, signed.len() as u64);
    let mut opened = vec![0u8; message.len()];
    let mut opened_len = 0u64;
    assert_eq!(
        sign::crypto_sign_open(
            opened.as_mut_ptr(),
            &mut opened_len,
            signed.as_ptr(),
            signed.len() as u64,
            pk.as_ptr(),
        ),
        0
    );
    assert_eq!(opened_len, message.len() as u64);
    assert_eq!(&opened, message);

    let ph_pk = hex_decode("ec172b93ad5e563bf4932c70e1245034c35467ef2efd4d64ebf819683467e2bf");
    let mut ph_sk = hex_decode("833fe62409237b9d62ec77587520911e9a759cec1d19755b7da901b96dca3d42");
    ph_sk.extend_from_slice(&ph_pk);
    let mut state = std::mem::MaybeUninit::zeroed();
    let mut ph_sig = [0u8; 64];
    let mut ph_siglen = 0u64;
    assert_eq!(sign::crypto_sign_init(state.as_mut_ptr()), 0);
    assert_eq!(
        sign::crypto_sign_update(state.as_mut_ptr(), b"abc".as_ptr(), 3),
        0
    );
    assert_eq!(
        sign::crypto_sign_final_create(
            state.as_mut_ptr(),
            ph_sig.as_mut_ptr(),
            &mut ph_siglen,
            ph_sk.as_ptr(),
        ),
        0
    );
    assert_eq!(ph_siglen, 64);
    assert_eq!(
        hex(&ph_sig),
        "98a70222f0b8121aa9d30f813d683f809e462b469c7ff87639499bb94e6dae4131f85042463c2a355a2003d062adf5aaa10b8c61e636062aaad11c2a26083406"
    );
    assert_eq!(sign::crypto_sign_init(state.as_mut_ptr()), 0);
    assert_eq!(
        sign::crypto_sign_update(state.as_mut_ptr(), b"abc".as_ptr(), 3),
        0
    );
    assert_eq!(
        sign::crypto_sign_final_verify(state.as_mut_ptr(), ph_sig.as_ptr(), ph_pk.as_ptr()),
        0
    );

    let mut legacy_pk = [0u8; 32];
    let mut legacy_sk = [0u8; 64];
    assert_eq!(
        legacy_sign::crypto_sign_edwards25519sha512batch_keypair(
            legacy_pk.as_mut_ptr(),
            legacy_sk.as_mut_ptr(),
        ),
        0
    );
    let legacy_message = b"legacy api";
    let mut legacy_signed = vec![0u8; legacy_message.len() + 64];
    let mut legacy_len = 0u64;
    assert_eq!(
        legacy_sign::crypto_sign_edwards25519sha512batch(
            legacy_signed.as_mut_ptr(),
            &mut legacy_len,
            legacy_message.as_ptr(),
            legacy_message.len() as u64,
            legacy_sk.as_ptr(),
        ),
        0
    );
    let mut legacy_opened = vec![0u8; legacy_message.len()];
    let mut legacy_opened_len = 0u64;
    assert_eq!(
        legacy_sign::crypto_sign_edwards25519sha512batch_open(
            legacy_opened.as_mut_ptr(),
            &mut legacy_opened_len,
            legacy_signed.as_ptr(),
            legacy_signed.len() as u64,
            legacy_pk.as_ptr(),
        ),
        0
    );
    assert_eq!(legacy_opened_len, legacy_message.len() as u64);
    assert_eq!(&legacy_opened, legacy_message);
}

#[test]
fn legacy_edwards25519sha512batch_matches_upstream_vector() {
    init();

    let seed: [u8; 32] = core::array::from_fn(|i| i as u8);
    let digest = Sha512::digest(seed);
    let mut legacy_sk = [0u8; 64];
    legacy_sk.copy_from_slice(&digest);
    let clamped = clamp_ed25519_scalar(legacy_sk[..32].try_into().unwrap());
    legacy_sk[..32].copy_from_slice(&clamped);
    let legacy_pk = EdwardsPoint::mul_base(&Scalar::from_bytes_mod_order(clamped))
        .compress()
        .to_bytes();
    let message = b"legacy api vector";
    let expected_signed = hex_decode(
        "2b4f6e212406080097793e1ba62d2c59107267f0760c83883dcc4ce651473fbe6c65676163792061706920766563746f72c178aea69b7cf4e6dd65d79a57def07c02097f2375e600499d29fff8aa268b0e",
    );

    let mut signed = vec![0u8; expected_signed.len()];
    let mut signed_len = 0u64;
    assert_eq!(
        legacy_sign::crypto_sign_edwards25519sha512batch(
            signed.as_mut_ptr(),
            &mut signed_len,
            message.as_ptr(),
            message.len() as u64,
            legacy_sk.as_ptr(),
        ),
        0
    );
    assert_eq!(signed_len, expected_signed.len() as u64);
    assert_eq!(signed, expected_signed);

    let mut opened = vec![0u8; message.len()];
    let mut opened_len = 0u64;
    assert_eq!(
        legacy_sign::crypto_sign_edwards25519sha512batch_open(
            opened.as_mut_ptr(),
            &mut opened_len,
            signed.as_ptr(),
            signed_len,
            legacy_pk.as_ptr(),
        ),
        0
    );
    assert_eq!(opened_len, message.len() as u64);
    assert_eq!(&opened, message);
}

#[test]
fn kx_and_box_vectors_match_upstream() {
    init();

    let seed0 = (0u8..32).collect::<Vec<_>>();
    let mut seed1 = seed0.clone();
    seed1[0] = seed1[0].wrapping_add(1);

    let mut client_pk = [0u8; 32];
    let mut client_sk = [0u8; 32];
    assert_eq!(
        kx::crypto_kx_seed_keypair(client_pk.as_mut_ptr(), client_sk.as_mut_ptr(), seed0.as_ptr()),
        0
    );
    assert_eq!(hex(&client_pk), "0e0216223f147143d32615a91189c288c1728cba3cc5f9f621b1026e03d83129");
    assert_eq!(hex(&client_sk), "cb2f5160fc1f7e05a55ef49d340b48da2e5a78099d53393351cd579dd42503d6");

    let mut server_pk = [0u8; 32];
    let mut server_sk = [0u8; 32];
    assert_eq!(
        kx::crypto_kx_seed_keypair(server_pk.as_mut_ptr(), server_sk.as_mut_ptr(), seed1.as_ptr()),
        0
    );

    let mut client_rx = [0u8; 32];
    let mut client_tx = [0u8; 32];
    let mut server_rx = [0u8; 32];
    let mut server_tx = [0u8; 32];

    assert_eq!(
        kx::crypto_kx_client_session_keys(
            client_rx.as_mut_ptr(),
            client_tx.as_mut_ptr(),
            client_pk.as_ptr(),
            client_sk.as_ptr(),
            SMALL_ORDER_P.as_ptr(),
        ),
        -1
    );
    assert_eq!(
        kx::crypto_kx_server_session_keys(
            server_rx.as_mut_ptr(),
            server_tx.as_mut_ptr(),
            server_pk.as_ptr(),
            server_sk.as_ptr(),
            SMALL_ORDER_P.as_ptr(),
        ),
        -1
    );

    assert_eq!(
        kx::crypto_kx_server_session_keys(
            server_rx.as_mut_ptr(),
            server_tx.as_mut_ptr(),
            server_pk.as_ptr(),
            server_sk.as_ptr(),
            client_pk.as_ptr(),
        ),
        0
    );
    assert_eq!(hex(&server_rx), "62c8f4fa81800abd0577d99918d129b65deb789af8c8351f391feb0cbf238604");
    assert_eq!(hex(&server_tx), "749519c68059bce69f7cfcc7b387a3de1a1e8237d110991323bf62870115731a");

    assert_eq!(
        kx::crypto_kx_client_session_keys(
            client_rx.as_mut_ptr(),
            client_tx.as_mut_ptr(),
            client_pk.as_ptr(),
            client_sk.as_ptr(),
            server_pk.as_ptr(),
        ),
        0
    );
    assert_eq!(hex(&client_rx), "749519c68059bce69f7cfcc7b387a3de1a1e8237d110991323bf62870115731a");
    assert_eq!(hex(&client_tx), "62c8f4fa81800abd0577d99918d129b65deb789af8c8351f391feb0cbf238604");

    let mut alias_client = [0u8; 32];
    assert_eq!(
        kx::crypto_kx_client_session_keys(
            alias_client.as_mut_ptr(),
            ptr::null_mut(),
            client_pk.as_ptr(),
            client_sk.as_ptr(),
            server_pk.as_ptr(),
        ),
        0
    );
    assert_eq!(alias_client, client_tx);
    assert_eq!(
        kx::crypto_kx_client_session_keys(
            ptr::null_mut(),
            alias_client.as_mut_ptr(),
            client_pk.as_ptr(),
            client_sk.as_ptr(),
            server_pk.as_ptr(),
        ),
        0
    );
    assert_eq!(alias_client, client_tx);

    let mut xpk = [0u8; 32];
    let mut xsk = [0u8; 32];
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_seed_keypair(
            xpk.as_mut_ptr(),
            xsk.as_mut_ptr(),
            seed0.as_ptr(),
        ),
        0
    );
    assert_eq!(hex(&xpk), "4701d08488451f545a409fb58ae3e58581ca40ac3f7f114698cd71deac73ca01");
    assert_eq!(hex(&xsk), "3d94eea49c580aef816935762be049559d6d1440dede12e6a125f1841fff8e6f");

    let nonce = (0u8..24).collect::<Vec<_>>();
    let message = b"public-key box coverage";

    let mut xsalsa_pk = [0u8; 32];
    let mut xsalsa_sk = [0u8; 32];
    let mut peer_pk = [0u8; 32];
    let mut peer_sk = [0u8; 32];
    assert_eq!(
        box_api::crypto_box_seed_keypair(xsalsa_pk.as_mut_ptr(), xsalsa_sk.as_mut_ptr(), seed0.as_ptr()),
        0
    );
    assert_eq!(
        box_api::crypto_box_seed_keypair(peer_pk.as_mut_ptr(), peer_sk.as_mut_ptr(), seed1.as_ptr()),
        0
    );

    let mut easy = vec![0u8; message.len() + box_api::crypto_box_macbytes()];
    let mut opened = vec![0u8; message.len()];
    assert_eq!(
        box_api::crypto_box_easy(
            easy.as_mut_ptr(),
            message.as_ptr(),
            message.len() as u64,
            nonce.as_ptr(),
            peer_pk.as_ptr(),
            xsalsa_sk.as_ptr(),
        ),
        0
    );
    assert_eq!(
        box_api::crypto_box_open_easy(
            opened.as_mut_ptr(),
            easy.as_ptr(),
            easy.len() as u64,
            nonce.as_ptr(),
            xsalsa_pk.as_ptr(),
            peer_sk.as_ptr(),
        ),
        0
    );
    assert_eq!(&opened, message);

    let mut beforenm = [0u8; 32];
    assert_eq!(
        box_api::crypto_box_beforenm(beforenm.as_mut_ptr(), SMALL_ORDER_P.as_ptr(), xsalsa_sk.as_ptr()),
        -1
    );
    assert_eq!(
        box_api::crypto_box_beforenm(beforenm.as_mut_ptr(), peer_pk.as_ptr(), xsalsa_sk.as_ptr()),
        0
    );
    assert_eq!(
        box_api::crypto_box_easy_afternm(
            easy.as_mut_ptr(),
            message.as_ptr(),
            message.len() as u64,
            nonce.as_ptr(),
            beforenm.as_ptr(),
        ),
        0
    );
    assert_eq!(
        box_api::crypto_box_open_easy_afternm(
            opened.as_mut_ptr(),
            easy.as_ptr(),
            easy.len() as u64,
            nonce.as_ptr(),
            beforenm.as_ptr(),
        ),
        0
    );
    assert_eq!(&opened, message);

    let mut detached = vec![0u8; message.len()];
    let mut mac = [0u8; 16];
    assert_eq!(
        box_api::crypto_box_detached(
            detached.as_mut_ptr(),
            mac.as_mut_ptr(),
            message.as_ptr(),
            message.len() as u64,
            nonce.as_ptr(),
            SMALL_ORDER_P.as_ptr(),
            peer_sk.as_ptr(),
        ),
        -1
    );
    assert_eq!(
        box_api::crypto_box_detached(
            detached.as_mut_ptr(),
            mac.as_mut_ptr(),
            message.as_ptr(),
            message.len() as u64,
            nonce.as_ptr(),
            xsalsa_pk.as_ptr(),
            peer_sk.as_ptr(),
        ),
        0
    );
    assert_eq!(
        box_api::crypto_box_open_detached(
            opened.as_mut_ptr(),
            detached.as_ptr(),
            mac.as_ptr(),
            detached.len() as u64,
            nonce.as_ptr(),
            xsalsa_pk.as_ptr(),
            peer_sk.as_ptr(),
        ),
        0
    );
    assert_eq!(&opened, message);

    let mut sealed = vec![0u8; message.len() + box_api::crypto_box_sealbytes()];
    assert_eq!(
        box_api::crypto_box_seal(sealed.as_mut_ptr(), message.as_ptr(), message.len() as u64, peer_pk.as_ptr()),
        0
    );
    assert_eq!(
        box_api::crypto_box_seal_open(
            opened.as_mut_ptr(),
            sealed.as_ptr(),
            sealed.len() as u64,
            peer_pk.as_ptr(),
            peer_sk.as_ptr(),
        ),
        0
    );
    assert_eq!(&opened, message);

    let mut x_easy = vec![0u8; message.len() + box_xchacha::crypto_box_curve25519xchacha20poly1305_macbytes()];
    let mut x_opened = vec![0u8; message.len()];
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_easy(
            x_easy.as_mut_ptr(),
            message.as_ptr(),
            message.len() as u64,
            nonce.as_ptr(),
            xpk.as_ptr(),
            xsk.as_ptr(),
        ),
        0
    );
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_open_easy(
            x_opened.as_mut_ptr(),
            x_easy.as_ptr(),
            x_easy.len() as u64,
            nonce.as_ptr(),
            xpk.as_ptr(),
            xsk.as_ptr(),
        ),
        0
    );
    assert_eq!(&x_opened, message);
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_open_easy(
            x_opened.as_mut_ptr(),
            x_easy.as_ptr(),
            (box_xchacha::crypto_box_curve25519xchacha20poly1305_macbytes() - 1) as u64,
            nonce.as_ptr(),
            xpk.as_ptr(),
            xsk.as_ptr(),
        ),
        -1
    );

    let mut x_beforenm = [0u8; 32];
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_beforenm(
            x_beforenm.as_mut_ptr(),
            SMALL_ORDER_P.as_ptr(),
            xsk.as_ptr(),
        ),
        -1
    );
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_beforenm(
            x_beforenm.as_mut_ptr(),
            xpk.as_ptr(),
            xsk.as_ptr(),
        ),
        0
    );

    let mut x_detached = vec![0u8; message.len()];
    let mut x_mac = [0u8; 16];
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_detached(
            x_detached.as_mut_ptr(),
            x_mac.as_mut_ptr(),
            message.as_ptr(),
            message.len() as u64,
            nonce.as_ptr(),
            SMALL_ORDER_P.as_ptr(),
            xsk.as_ptr(),
        ),
        -1
    );
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_detached(
            x_detached.as_mut_ptr(),
            x_mac.as_mut_ptr(),
            message.as_ptr(),
            message.len() as u64,
            nonce.as_ptr(),
            xpk.as_ptr(),
            xsk.as_ptr(),
        ),
        0
    );
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_open_detached(
            x_opened.as_mut_ptr(),
            x_detached.as_ptr(),
            x_mac.as_ptr(),
            x_detached.len() as u64,
            nonce.as_ptr(),
            xpk.as_ptr(),
            xsk.as_ptr(),
        ),
        0
    );
    assert_eq!(&x_opened, message);

    let mut x_sealed =
        vec![0u8; message.len() + box_xchacha::crypto_box_curve25519xchacha20poly1305_sealbytes()];
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_seal(
            x_sealed.as_mut_ptr(),
            message.as_ptr(),
            message.len() as u64,
            xpk.as_ptr(),
        ),
        0
    );
    assert_eq!(
        box_xchacha::crypto_box_curve25519xchacha20poly1305_seal_open(
            x_opened.as_mut_ptr(),
            x_sealed.as_ptr(),
            x_sealed.len() as u64,
            xpk.as_ptr(),
            xsk.as_ptr(),
        ),
        0
    );
    assert_eq!(&x_opened, message);

    let primitive = unsafe { CStr::from_ptr(kx::crypto_kx_primitive()) };
    assert_eq!(primitive.to_str().unwrap(), "x25519blake2b");
}
