use sodium::aead::{aes256gcm, chacha20poly1305, xchacha20poly1305};
use sodium::auth;
use sodium::auth::{hmacsha256, hmacsha512, hmacsha512256};
use sodium::box_api;
use sodium::box_api::curve25519xchacha20poly1305 as box_xchacha;
use sodium::foundation::{codecs, core as sodium_core, randombytes};
use sodium::generichash;
use sodium::kdf;
use sodium::kx;
use sodium::onetimeauth;
use sodium::onetimeauth::poly1305;
use sodium::pwhash;
use sodium::secretbox;
use sodium::secretstream;
use sodium::shorthash;
use sodium::stream;
use sodium::stream::{chacha20, salsa20, xchacha20, xsalsa20};
use std::alloc::{alloc_zeroed, dealloc, Layout};
use std::env;
#[cfg(unix)]
use std::os::unix::process::ExitStatusExt;
use std::process::Command;
use std::ptr;
use std::sync::Once;

static INIT: Once = Once::new();

const MAXLEN: usize = 512;
const MAX_ITER: usize = 1000;
const MISUSE_ABORT_HELPER: &str = "misuse_abort_helper";
const MISUSE_ABORT_CASES: &[&str] = &[
    "crypto_kx_client_session_keys",
    "crypto_kx_server_session_keys",
    "randombytes_buf_deterministic",
    "crypto_aead_chacha20poly1305_encrypt",
    "crypto_aead_chacha20poly1305_ietf_encrypt",
    "crypto_aead_xchacha20poly1305_ietf_encrypt",
    "sodium_pad",
    "sodium_bin2base64_invalid_variant",
    "sodium_bin2base64_small_buffer",
    "sodium_base642bin_invalid_variant",
    "crypto_box_easy_afternm",
    "crypto_box_easy",
    "crypto_pwhash_str_alg",
    "crypto_box_curve25519xchacha20poly1305_easy_afternm",
    "crypto_box_curve25519xchacha20poly1305_easy",
];

struct AlignedBuf {
    ptr: *mut u8,
    layout: Layout,
}

impl AlignedBuf {
    fn zeroed(size: usize) -> Self {
        let layout = Layout::from_size_align(size.max(1), 64).expect("aligned layout");
        let ptr = unsafe { alloc_zeroed(layout) };
        assert!(!ptr.is_null(), "aligned allocation failed");
        Self { ptr, layout }
    }

    fn as_mut_ptr(&mut self) -> *mut u8 {
        self.ptr
    }
}

impl Drop for AlignedBuf {
    fn drop(&mut self) {
        unsafe {
            dealloc(self.ptr, self.layout);
        }
    }
}

fn init() {
    INIT.call_once(|| {
        let ret = sodium_core::sodium_init();
        assert!(ret == 0 || ret == 1);
    });
}

fn random_len(upper_bound: usize) -> usize {
    if upper_bound == 0 {
        0
    } else {
        randombytes::randombytes_uniform(upper_bound as u32) as usize
    }
}

fn random_bytes(len: usize) -> Vec<u8> {
    let mut out = vec![0u8; len];
    if len != 0 {
        randombytes::randombytes_buf(out.as_mut_ptr().cast(), out.len());
    }
    out
}

fn split_message(message_len: usize) -> (usize, usize) {
    if message_len == 0 {
        return (0, 0);
    }
    let first = random_len(message_len);
    let second = random_len(message_len - first);
    (first, second)
}

#[test]
fn keygen_writes_the_full_key_buffer_for_every_exported_generator() {
    init();

    type KeygenFn = extern "C" fn(*mut u8);
    type KeygenCase = (&'static str, KeygenFn, usize);

    let cases: &[KeygenCase] = &[
        ("crypto_auth_keygen", auth::crypto_auth_keygen, auth::crypto_auth_keybytes()),
        (
            "crypto_auth_hmacsha256_keygen",
            hmacsha256::crypto_auth_hmacsha256_keygen,
            hmacsha256::crypto_auth_hmacsha256_keybytes(),
        ),
        (
            "crypto_aead_aes256gcm_keygen",
            aes256gcm::crypto_aead_aes256gcm_keygen,
            aes256gcm::crypto_aead_aes256gcm_keybytes(),
        ),
        (
            "crypto_auth_hmacsha512_keygen",
            hmacsha512::crypto_auth_hmacsha512_keygen,
            hmacsha512::crypto_auth_hmacsha512_keybytes(),
        ),
        (
            "crypto_auth_hmacsha512256_keygen",
            hmacsha512256::crypto_auth_hmacsha512256_keygen,
            hmacsha512256::crypto_auth_hmacsha512256_keybytes(),
        ),
        (
            "crypto_generichash_keygen",
            generichash::crypto_generichash_keygen,
            generichash::crypto_generichash_keybytes(),
        ),
        (
            "crypto_generichash_blake2b_keygen",
            generichash::crypto_generichash_blake2b_keygen,
            generichash::crypto_generichash_blake2b_keybytes(),
        ),
        ("crypto_kdf_keygen", kdf::crypto_kdf_keygen, kdf::crypto_kdf_keybytes()),
        (
            "crypto_onetimeauth_keygen",
            onetimeauth::crypto_onetimeauth_keygen,
            onetimeauth::crypto_onetimeauth_keybytes(),
        ),
        (
            "crypto_onetimeauth_poly1305_keygen",
            poly1305::crypto_onetimeauth_poly1305_keygen,
            poly1305::crypto_onetimeauth_poly1305_keybytes(),
        ),
        (
            "crypto_aead_chacha20poly1305_ietf_keygen",
            chacha20poly1305::crypto_aead_chacha20poly1305_ietf_keygen,
            chacha20poly1305::crypto_aead_chacha20poly1305_ietf_keybytes(),
        ),
        (
            "crypto_aead_chacha20poly1305_keygen",
            chacha20poly1305::crypto_aead_chacha20poly1305_keygen,
            chacha20poly1305::crypto_aead_chacha20poly1305_keybytes(),
        ),
        (
            "crypto_aead_chacha20poly1305_ietf_keygen_duplicate",
            chacha20poly1305::crypto_aead_chacha20poly1305_ietf_keygen,
            chacha20poly1305::crypto_aead_chacha20poly1305_ietf_keybytes(),
        ),
        (
            "crypto_aead_xchacha20poly1305_ietf_keygen",
            xchacha20poly1305::crypto_aead_xchacha20poly1305_ietf_keygen,
            xchacha20poly1305::crypto_aead_xchacha20poly1305_ietf_keybytes(),
        ),
        (
            "crypto_secretbox_xsalsa20poly1305_keygen",
            secretbox::crypto_secretbox_xsalsa20poly1305_keygen,
            secretbox::crypto_secretbox_xsalsa20poly1305_keybytes(),
        ),
        (
            "crypto_secretbox_keygen",
            secretbox::crypto_secretbox_keygen,
            secretbox::crypto_secretbox_keybytes(),
        ),
        (
            "crypto_secretstream_xchacha20poly1305_keygen",
            secretstream::crypto_secretstream_xchacha20poly1305_keygen,
            secretstream::crypto_secretstream_xchacha20poly1305_keybytes(),
        ),
        (
            "crypto_shorthash_keygen",
            shorthash::crypto_shorthash_keygen,
            shorthash::crypto_shorthash_keybytes(),
        ),
        (
            "crypto_stream_keygen",
            stream::crypto_stream_keygen,
            stream::crypto_stream_keybytes(),
        ),
        (
            "crypto_stream_chacha20_keygen",
            chacha20::crypto_stream_chacha20_keygen,
            chacha20::crypto_stream_chacha20_keybytes(),
        ),
        (
            "crypto_stream_chacha20_ietf_keygen",
            chacha20::crypto_stream_chacha20_ietf_keygen,
            chacha20::crypto_stream_chacha20_ietf_keybytes(),
        ),
        (
            "crypto_stream_salsa20_keygen",
            salsa20::crypto_stream_salsa20_keygen,
            salsa20::crypto_stream_salsa20_keybytes(),
        ),
        (
            "crypto_stream_xsalsa20_keygen",
            xsalsa20::crypto_stream_xsalsa20_keygen,
            xsalsa20::crypto_stream_xsalsa20_keybytes(),
        ),
    ];

    for (name, keygen, key_len) in cases {
        let mut key = vec![0u8; *key_len];
        let mut wrote_last_byte = false;

        for _ in 0..10_000 {
            key[*key_len - 1] = 0;
            keygen(key.as_mut_ptr());
            if key[*key_len - 1] != 0 {
                wrote_last_byte = true;
                break;
            }
        }

        assert!(wrote_last_byte, "buffer underflow with test vector {name}");
    }
}

#[test]
fn metamorphic_incremental_interfaces_match_single_shot_primitives() {
    init();

    for _ in 0..MAX_ITER {
        let message_len = random_len(MAXLEN);
        let message = random_bytes(message_len);
        let (first, second) = split_message(message_len);

        let key_len = random_len(
            generichash::crypto_generichash_keybytes_max()
                - generichash::crypto_generichash_keybytes_min()
                + 1,
        ) + generichash::crypto_generichash_keybytes_min();
        let key = random_bytes(key_len);
        let hash_len = random_len(
            generichash::crypto_generichash_bytes_max()
                - generichash::crypto_generichash_bytes_min()
                + 1,
        ) + generichash::crypto_generichash_bytes_min();
        let mut incremental = vec![0u8; hash_len];
        let mut single = vec![0u8; hash_len];
        let mut state = AlignedBuf::zeroed(generichash::crypto_generichash_statebytes());

        assert_eq!(
            generichash::crypto_generichash_init(state.as_mut_ptr().cast(), key.as_ptr(), key_len, hash_len),
            0
        );
        assert_eq!(
            generichash::crypto_generichash_update(
                state.as_mut_ptr().cast(),
                message.as_ptr(),
                first as u64,
            ),
            0
        );
        assert_eq!(
            generichash::crypto_generichash_update(
                state.as_mut_ptr().cast(),
                message.as_ptr().wrapping_add(first),
                second as u64,
            ),
            0
        );
        assert_eq!(
            generichash::crypto_generichash_update(
                state.as_mut_ptr().cast(),
                message.as_ptr().wrapping_add(first + second),
                (message_len - first - second) as u64,
            ),
            0
        );
        assert_eq!(
            generichash::crypto_generichash_final(
                state.as_mut_ptr().cast(),
                incremental.as_mut_ptr(),
                hash_len,
            ),
            0
        );
        assert_eq!(
            generichash::crypto_generichash(
                single.as_mut_ptr(),
                hash_len,
                message.as_ptr(),
                message_len as u64,
                key.as_ptr(),
                key_len,
            ),
            0
        );
        assert_eq!(incremental, single);
    }

    for _ in 0..MAX_ITER {
        let message_len = random_len(MAXLEN);
        let message = random_bytes(message_len);
        let (first, second) = split_message(message_len);
        let mut key = vec![0u8; onetimeauth::crypto_onetimeauth_keybytes()];
        let mut incremental = vec![0u8; onetimeauth::crypto_onetimeauth_bytes()];
        let mut single = vec![0u8; onetimeauth::crypto_onetimeauth_bytes()];
        let mut state = AlignedBuf::zeroed(onetimeauth::crypto_onetimeauth_statebytes());

        onetimeauth::crypto_onetimeauth_keygen(key.as_mut_ptr());
        assert_eq!(
            onetimeauth::crypto_onetimeauth_init(state.as_mut_ptr().cast(), key.as_ptr()),
            0
        );
        assert_eq!(
            onetimeauth::crypto_onetimeauth_update(
                state.as_mut_ptr().cast(),
                message.as_ptr(),
                first as u64,
            ),
            0
        );
        assert_eq!(
            onetimeauth::crypto_onetimeauth_update(
                state.as_mut_ptr().cast(),
                message.as_ptr().wrapping_add(first),
                second as u64,
            ),
            0
        );
        assert_eq!(
            onetimeauth::crypto_onetimeauth_update(
                state.as_mut_ptr().cast(),
                message.as_ptr().wrapping_add(first + second),
                (message_len - first - second) as u64,
            ),
            0
        );
        assert_eq!(
            onetimeauth::crypto_onetimeauth_final(state.as_mut_ptr().cast(), incremental.as_mut_ptr()),
            0
        );
        assert_eq!(
            onetimeauth::crypto_onetimeauth(
                single.as_mut_ptr(),
                message.as_ptr(),
                message_len as u64,
                key.as_ptr(),
            ),
            0
        );
        assert_eq!(incremental, single);
    }

    for _ in 0..MAX_ITER {
        let message_len = random_len(MAXLEN);
        let message = random_bytes(message_len);
        let (first, second) = split_message(message_len);
        let mut key = vec![0u8; hmacsha256::crypto_auth_hmacsha256_keybytes()];
        let mut incremental = vec![0u8; hmacsha256::crypto_auth_hmacsha256_bytes()];
        let mut single = vec![0u8; hmacsha256::crypto_auth_hmacsha256_bytes()];
        let mut state = AlignedBuf::zeroed(hmacsha256::crypto_auth_hmacsha256_statebytes());

        hmacsha256::crypto_auth_hmacsha256_keygen(key.as_mut_ptr());
        assert_eq!(
            hmacsha256::crypto_auth_hmacsha256_init(
                state.as_mut_ptr().cast(),
                key.as_ptr(),
                key.len(),
            ),
            0
        );
        assert_eq!(
            hmacsha256::crypto_auth_hmacsha256_update(
                state.as_mut_ptr().cast(),
                message.as_ptr(),
                first as u64,
            ),
            0
        );
        assert_eq!(
            hmacsha256::crypto_auth_hmacsha256_update(
                state.as_mut_ptr().cast(),
                message.as_ptr().wrapping_add(first),
                second as u64,
            ),
            0
        );
        assert_eq!(
            hmacsha256::crypto_auth_hmacsha256_update(
                state.as_mut_ptr().cast(),
                message.as_ptr().wrapping_add(first + second),
                (message_len - first - second) as u64,
            ),
            0
        );
        assert_eq!(
            hmacsha256::crypto_auth_hmacsha256_final(state.as_mut_ptr().cast(), incremental.as_mut_ptr()),
            0
        );
        assert_eq!(
            hmacsha256::crypto_auth_hmacsha256(
                single.as_mut_ptr(),
                message.as_ptr(),
                message_len as u64,
                key.as_ptr(),
            ),
            0
        );
        assert_eq!(incremental, single);
    }

    for _ in 0..MAX_ITER {
        let message_len = random_len(MAXLEN);
        let message = random_bytes(message_len);
        let (first, second) = split_message(message_len);
        let mut key = vec![0u8; hmacsha512::crypto_auth_hmacsha512_keybytes()];
        let mut incremental = vec![0u8; hmacsha512::crypto_auth_hmacsha512_bytes()];
        let mut single = vec![0u8; hmacsha512::crypto_auth_hmacsha512_bytes()];
        let mut state = AlignedBuf::zeroed(hmacsha512::crypto_auth_hmacsha512_statebytes());

        hmacsha512::crypto_auth_hmacsha512_keygen(key.as_mut_ptr());
        assert_eq!(
            hmacsha512::crypto_auth_hmacsha512_init(
                state.as_mut_ptr().cast(),
                key.as_ptr(),
                key.len(),
            ),
            0
        );
        assert_eq!(
            hmacsha512::crypto_auth_hmacsha512_update(
                state.as_mut_ptr().cast(),
                message.as_ptr(),
                first as u64,
            ),
            0
        );
        assert_eq!(
            hmacsha512::crypto_auth_hmacsha512_update(
                state.as_mut_ptr().cast(),
                message.as_ptr().wrapping_add(first),
                second as u64,
            ),
            0
        );
        assert_eq!(
            hmacsha512::crypto_auth_hmacsha512_update(
                state.as_mut_ptr().cast(),
                message.as_ptr().wrapping_add(first + second),
                (message_len - first - second) as u64,
            ),
            0
        );
        assert_eq!(
            hmacsha512::crypto_auth_hmacsha512_final(state.as_mut_ptr().cast(), incremental.as_mut_ptr()),
            0
        );
        assert_eq!(
            hmacsha512::crypto_auth_hmacsha512(
                single.as_mut_ptr(),
                message.as_ptr(),
                message_len as u64,
                key.as_ptr(),
            ),
            0
        );
        assert_eq!(incremental, single);
    }
}

#[cfg(unix)]
#[test]
fn misuse_abort_contracts_match_upstream() {
    init();

    for case_name in MISUSE_ABORT_CASES {
        let output = Command::new(env::current_exe().expect("current test binary"))
            .args(["--exact", MISUSE_ABORT_HELPER, "--nocapture"])
            .env("PORTED_ALL_CHILD_CASE", case_name)
            .output()
            .expect("spawn misuse helper");

        assert_eq!(
            output.status.signal(),
            Some(libc::SIGABRT),
            "misuse case {case_name} exited with {:?}\nstdout:\n{}\nstderr:\n{}",
            output.status,
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr),
        );
    }
}

#[cfg(unix)]
#[test]
fn misuse_abort_helper() {
    let Ok(case_name) = env::var("PORTED_ALL_CHILD_CASE") else {
        return;
    };

    init();
    run_misuse_abort_case(&case_name);
    panic!("misuse case {case_name} did not abort");
}

#[cfg(unix)]
fn run_misuse_abort_case(case_name: &str) {
    let mut byte = [0u8; 1];

    match case_name {
        "crypto_kx_client_session_keys" => {
            kx::crypto_kx_client_session_keys(
                ptr::null_mut(),
                ptr::null_mut(),
                byte.as_ptr(),
                byte.as_ptr(),
                byte.as_ptr(),
            );
        }
        "crypto_kx_server_session_keys" => {
            kx::crypto_kx_server_session_keys(
                ptr::null_mut(),
                ptr::null_mut(),
                byte.as_ptr(),
                byte.as_ptr(),
                byte.as_ptr(),
            );
        }
        "randombytes_buf_deterministic" => {
            if usize::BITS > 36 {
                randombytes::randombytes_buf_deterministic(
                    byte.as_mut_ptr().cast(),
                    0x4000_0000_01usize,
                    byte.as_ptr(),
                );
            } else {
                std::process::abort();
            }
        }
        "crypto_aead_chacha20poly1305_encrypt" => {
            chacha20poly1305::crypto_aead_chacha20poly1305_encrypt(
                byte.as_mut_ptr(),
                ptr::null_mut(),
                ptr::null(),
                u64::MAX,
                ptr::null(),
                0,
                ptr::null(),
                byte.as_ptr(),
                byte.as_ptr(),
            );
        }
        "crypto_aead_chacha20poly1305_ietf_encrypt" => {
            chacha20poly1305::crypto_aead_chacha20poly1305_ietf_encrypt(
                byte.as_mut_ptr(),
                ptr::null_mut(),
                ptr::null(),
                u64::MAX,
                ptr::null(),
                0,
                ptr::null(),
                byte.as_ptr(),
                byte.as_ptr(),
            );
        }
        "crypto_aead_xchacha20poly1305_ietf_encrypt" => {
            xchacha20poly1305::crypto_aead_xchacha20poly1305_ietf_encrypt(
                byte.as_mut_ptr(),
                ptr::null_mut(),
                ptr::null(),
                u64::MAX,
                ptr::null(),
                0,
                ptr::null(),
                byte.as_ptr(),
                byte.as_ptr(),
            );
        }
        "sodium_pad" => {
            let _ = sodium::foundation::utils::sodium_pad(
                ptr::null_mut(),
                byte.as_mut_ptr(),
                usize::MAX,
                16,
                1,
            );
        }
        "sodium_bin2base64_invalid_variant" => {
            let _ = codecs::sodium_bin2base64(
                byte.as_mut_ptr().cast(),
                1,
                byte.as_ptr(),
                1,
                -1,
            );
        }
        "sodium_bin2base64_small_buffer" => {
            let _ = codecs::sodium_bin2base64(
                byte.as_mut_ptr().cast(),
                1,
                byte.as_ptr(),
                1,
                1,
            );
        }
        "sodium_base642bin_invalid_variant" => {
            let _ = codecs::sodium_base642bin(
                byte.as_mut_ptr(),
                1,
                byte.as_ptr().cast(),
                1,
                ptr::null(),
                ptr::null_mut(),
                ptr::null_mut(),
                -1,
            );
        }
        "crypto_box_easy_afternm" => {
            box_api::crypto_box_easy_afternm(
                byte.as_mut_ptr(),
                byte.as_ptr(),
                xsalsa20::crypto_stream_xsalsa20_messagebytes_max() as u64,
                byte.as_ptr(),
                byte.as_ptr(),
            );
        }
        "crypto_box_easy" => {
            box_api::crypto_box_easy(
                byte.as_mut_ptr(),
                byte.as_ptr(),
                xsalsa20::crypto_stream_xsalsa20_messagebytes_max() as u64,
                byte.as_ptr(),
                byte.as_ptr(),
                byte.as_ptr(),
            );
        }
        "crypto_pwhash_str_alg" => {
            let _ = pwhash::crypto_pwhash_str_alg(
                byte.as_mut_ptr().cast(),
                b"\0".as_ptr().cast(),
                0,
                1,
                1,
                -1,
            );
        }
        "crypto_box_curve25519xchacha20poly1305_easy_afternm" => {
            box_xchacha::crypto_box_curve25519xchacha20poly1305_easy_afternm(
                byte.as_mut_ptr(),
                byte.as_ptr(),
                (xchacha20::crypto_stream_xchacha20_messagebytes_max() - 1) as u64,
                byte.as_ptr(),
                byte.as_ptr(),
            );
        }
        "crypto_box_curve25519xchacha20poly1305_easy" => {
            box_xchacha::crypto_box_curve25519xchacha20poly1305_easy(
                byte.as_mut_ptr(),
                byte.as_ptr(),
                (xchacha20::crypto_stream_xchacha20_messagebytes_max() - 1) as u64,
                byte.as_ptr(),
                byte.as_ptr(),
                byte.as_ptr(),
            );
        }
        other => panic!("unknown misuse case: {other}"),
    }
}
