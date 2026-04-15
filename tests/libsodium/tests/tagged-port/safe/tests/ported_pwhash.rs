use sodium::abi::types::crypto_aead_aes256gcm_state;
use sodium::aead::aes256gcm;
use sodium::foundation::core;
use sodium::kdf;
use sodium::pwhash;
use sodium::pwhash::argon2;
use sodium::pwhash::scrypt;
use std::ffi::{CStr, CString};
use std::mem::{align_of, size_of, MaybeUninit};
use std::os::raw::c_char;
use std::ptr;

fn errno() -> i32 {
    unsafe { *libc::__errno_location() }
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

#[test]
fn kdf_vectors_match_upstream() {
    let context = b"KDF test";
    let master_key = (0u8..kdf::crypto_kdf_keybytes() as u8).collect::<Vec<_>>();
    let expected = [
        "a0c724404728c8bb95e5433eb6a9716171144d61efb23e74b873fcbeda51d8071b5d70aae12066dfc94ce943f145aa176c055040c3dd73b0a15e36254d450614",
        "02507f144fa9bf19010bf7c70b235b4c2663cc00e074f929602a5e2c10a780757d2a3993d06debc378a90efdac196dd841817b977d67b786804f6d3cd585bab5",
        "1944da61ff18dc2028c3578ac85be904931b83860896598f62468f1cb5471c6a344c945dbc62c9aaf70feb62472d17775ea5db6ed5494c68b7a9a59761f39614",
    ];

    for (subkey_id, expected_hex) in expected.into_iter().enumerate() {
        let mut subkey = vec![0u8; kdf::crypto_kdf_bytes_max()];
        assert_eq!(
            kdf::crypto_kdf_derive_from_key(
                subkey.as_mut_ptr(),
                subkey.len(),
                subkey_id as u64,
                context.as_ptr().cast::<c_char>(),
                master_key.as_ptr(),
            ),
            0
        );
        assert_eq!(subkey, hex_decode(expected_hex));
    }

    let mut short = vec![0u8; kdf::crypto_kdf_bytes_min() - 1];
    assert_eq!(
        kdf::crypto_kdf_derive_from_key(
            short.as_mut_ptr(),
            short.len(),
            0,
            context.as_ptr().cast::<c_char>(),
            master_key.as_ptr(),
        ),
        -1
    );
    assert_eq!(errno(), libc::EINVAL);
}

#[test]
fn argon2_selector_and_rehash_behavior_match_upstream() {
    assert_eq!(
        pwhash::crypto_pwhash_alg_default(),
        pwhash::crypto_pwhash_alg_argon2id13()
    );
    assert_eq!(
        unsafe { CStr::from_ptr(pwhash::crypto_pwhash_primitive()) }
            .to_str()
            .unwrap(),
        "argon2i"
    );

    let password = CString::new("test").unwrap();
    let opslimit = 3u64;
    let memlimit = 5_000_000usize;

    let mut argon2i_str = vec![0 as c_char; argon2::crypto_pwhash_argon2i_strbytes()];
    assert_eq!(
        pwhash::crypto_pwhash_str_alg(
            argon2i_str.as_mut_ptr(),
            password.as_ptr(),
            4,
            opslimit,
            memlimit,
            pwhash::crypto_pwhash_alg_argon2i13(),
        ),
        0
    );
    let argon2i_text = unsafe { CStr::from_ptr(argon2i_str.as_ptr()) }
        .to_str()
        .unwrap();
    assert!(argon2i_text.starts_with("$argon2i$"));
    assert_eq!(
        argon2::crypto_pwhash_argon2i_str_verify(argon2i_str.as_ptr(), password.as_ptr(), 4),
        0
    );
    assert_eq!(
        argon2::crypto_pwhash_argon2i_str_needs_rehash(argon2i_str.as_ptr(), opslimit, memlimit),
        0
    );
    assert_eq!(
        argon2::crypto_pwhash_argon2i_str_needs_rehash(
            argon2i_str.as_ptr(),
            opslimit,
            memlimit / 2
        ),
        1
    );

    let mut default_str = vec![0 as c_char; pwhash::crypto_pwhash_strbytes()];
    assert_eq!(
        pwhash::crypto_pwhash_str(
            default_str.as_mut_ptr(),
            password.as_ptr(),
            4,
            opslimit,
            memlimit
        ),
        0
    );
    let default_text = unsafe { CStr::from_ptr(default_str.as_ptr()) }
        .to_str()
        .unwrap();
    assert!(default_text.starts_with("$argon2id$"));
    assert_eq!(
        pwhash::crypto_pwhash_str_verify(default_str.as_ptr(), password.as_ptr(), 4),
        0
    );
    assert_eq!(
        pwhash::crypto_pwhash_str_needs_rehash(default_str.as_ptr(), opslimit, memlimit),
        0
    );
    assert_eq!(
        argon2::crypto_pwhash_argon2i_str_needs_rehash(default_str.as_ptr(), opslimit, memlimit),
        -1
    );
    assert_eq!(errno(), libc::EINVAL);
}

#[test]
fn scrypt_vectors_and_rehash_behavior_match_upstream() {
    let mut out = [0u8; 64];
    assert_eq!(
        scrypt::crypto_pwhash_scryptsalsa208sha256_ll(
            b"password".as_ptr(),
            b"password".len(),
            b"NaCl".as_ptr(),
            b"NaCl".len(),
            1024,
            8,
            16,
            out.as_mut_ptr(),
            out.len(),
        ),
        0
    );
    assert_eq!(
        out,
        hex_decode(
            "fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b373162\
             2eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640"
        )
        .as_slice()
    );

    let password = CString::new("password").unwrap();
    let opslimit = scrypt::crypto_pwhash_scryptsalsa208sha256_opslimit_interactive() as u64;
    let memlimit = scrypt::crypto_pwhash_scryptsalsa208sha256_memlimit_interactive();
    let mut encoded = vec![0 as c_char; scrypt::crypto_pwhash_scryptsalsa208sha256_strbytes()];
    assert_eq!(
        scrypt::crypto_pwhash_scryptsalsa208sha256_str(
            encoded.as_mut_ptr(),
            password.as_ptr(),
            password.as_bytes().len() as u64,
            opslimit,
            memlimit,
        ),
        0
    );
    let encoded_text = unsafe { CStr::from_ptr(encoded.as_ptr()) }
        .to_str()
        .unwrap();
    assert!(encoded_text.starts_with("$7$"));
    assert_eq!(
        scrypt::crypto_pwhash_scryptsalsa208sha256_str_verify(
            encoded.as_ptr(),
            password.as_ptr(),
            password.as_bytes().len() as u64,
        ),
        0
    );
    assert_eq!(
        scrypt::crypto_pwhash_scryptsalsa208sha256_str_needs_rehash(
            encoded.as_ptr(),
            opslimit,
            memlimit
        ),
        0
    );
    assert_eq!(
        scrypt::crypto_pwhash_scryptsalsa208sha256_str_needs_rehash(
            encoded.as_ptr(),
            opslimit / 2,
            memlimit
        ),
        1
    );
}

#[test]
fn aes256gcm_availability_contract_and_vectors_match_upstream() {
    assert_eq!(
        size_of::<crypto_aead_aes256gcm_state>(),
        aes256gcm::crypto_aead_aes256gcm_statebytes()
    );
    assert_eq!(align_of::<crypto_aead_aes256gcm_state>(), 16);
    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_messagebytes_max(),
        if usize::BITS >= 37 {
            68_719_476_704usize
        } else {
            usize::MAX - aes256gcm::crypto_aead_aes256gcm_abytes()
        }
    );

    let key = hex_decode("92ace3e348cd821092cd921aa3546374299ab46209691bc28b8752d17f123c20");
    let nonce = hex_decode("00112233445566778899aabb");
    let ad = hex_decode("00000000ffffffff");
    let message = hex_decode("00010203040506070809");
    let expected_ciphertext = hex_decode("e27abdd2d2a53d2f136b");
    let expected_mac = hex_decode("9a4a2579529301bcfb71c78d4060f52c");

    assert_eq!(aes256gcm::crypto_aead_aes256gcm_is_available(), 0);
    let mut unavailable_out = message.clone();
    let mut unavailable_mac = [0u8; 16];
    let mut unavailable_maclen = 0u64;
    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_encrypt_detached(
            unavailable_out.as_mut_ptr(),
            unavailable_mac.as_mut_ptr(),
            &mut unavailable_maclen,
            message.as_ptr(),
            message.len() as u64,
            ad.as_ptr(),
            ad.len() as u64,
            ptr::null(),
            nonce.as_ptr(),
            key.as_ptr(),
        ),
        -1
    );
    assert_eq!(errno(), libc::ENOSYS);

    let init = core::sodium_init();
    assert!(init == 0 || init == 1);
    let available = aes256gcm::crypto_aead_aes256gcm_is_available();
    if available == 0 {
        let mut out = message.clone();
        let mut mac = [0u8; 16];
        let mut maclen = 0u64;
        assert_eq!(
            aes256gcm::crypto_aead_aes256gcm_encrypt_detached(
                out.as_mut_ptr(),
                mac.as_mut_ptr(),
                &mut maclen,
                message.as_ptr(),
                message.len() as u64,
                ad.as_ptr(),
                ad.len() as u64,
                ptr::null(),
                nonce.as_ptr(),
                key.as_ptr(),
            ),
            -1
        );
        assert_eq!(errno(), libc::ENOSYS);
        return;
    }

    let mut ciphertext = message.clone();
    let mut mac = [0u8; 16];
    let mut maclen = 0u64;
    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_encrypt_detached(
            ciphertext.as_mut_ptr(),
            mac.as_mut_ptr(),
            &mut maclen,
            message.as_ptr(),
            message.len() as u64,
            ad.as_ptr(),
            ad.len() as u64,
            ptr::null(),
            nonce.as_ptr(),
            key.as_ptr(),
        ),
        0
    );
    assert_eq!(maclen, 16);
    assert_eq!(ciphertext, expected_ciphertext);
    assert_eq!(mac, expected_mac.as_slice());

    let mut decrypted = ciphertext.clone();
    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_decrypt_detached(
            decrypted.as_mut_ptr(),
            ptr::null_mut(),
            ciphertext.as_ptr(),
            ciphertext.len() as u64,
            mac.as_ptr(),
            ad.as_ptr(),
            ad.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        ),
        0
    );
    assert_eq!(decrypted, message);

    let mut state = MaybeUninit::<crypto_aead_aes256gcm_state>::zeroed();
    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_beforenm(state.as_mut_ptr(), key.as_ptr()),
        0
    );
    let state = unsafe { state.assume_init() };

    let mut afternm_ciphertext = message.clone();
    let mut afternm_mac = [0u8; 16];
    let mut afternm_maclen = 0u64;
    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_encrypt_detached_afternm(
            afternm_ciphertext.as_mut_ptr(),
            afternm_mac.as_mut_ptr(),
            &mut afternm_maclen,
            message.as_ptr(),
            message.len() as u64,
            ad.as_ptr(),
            ad.len() as u64,
            ptr::null(),
            nonce.as_ptr(),
            &state,
        ),
        0
    );
    assert_eq!(afternm_maclen, 16);
    assert_eq!(afternm_ciphertext, expected_ciphertext);
    assert_eq!(afternm_mac, expected_mac.as_slice());

    let mut afternm_plaintext = afternm_ciphertext.clone();
    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_decrypt_detached_afternm(
            afternm_plaintext.as_mut_ptr(),
            ptr::null_mut(),
            afternm_ciphertext.as_ptr(),
            afternm_ciphertext.len() as u64,
            afternm_mac.as_ptr(),
            ad.as_ptr(),
            ad.len() as u64,
            nonce.as_ptr(),
            &state,
        ),
        0
    );
    assert_eq!(afternm_plaintext, message);
}

#[test]
fn aes256gcm_detached_in_place_round_trip_preserves_ciphertext_on_auth_failure() {
    let init = core::sodium_init();
    assert!(init == 0 || init == 1);

    if aes256gcm::crypto_aead_aes256gcm_is_available() == 0 {
        return;
    }

    let key = hex_decode("92ace3e348cd821092cd921aa3546374299ab46209691bc28b8752d17f123c20");
    let nonce = hex_decode("00112233445566778899aabb");
    let ad = hex_decode("00000000ffffffff");
    let message = hex_decode("00010203040506070809");

    let mut in_place = message.clone();
    let mut mac = [0u8; 16];
    let mut maclen = 0u64;
    let in_place_ptr = in_place.as_mut_ptr();
    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_encrypt_detached(
            in_place_ptr,
            mac.as_mut_ptr(),
            &mut maclen,
            in_place_ptr.cast_const(),
            in_place.len() as u64,
            ad.as_ptr(),
            ad.len() as u64,
            ptr::null(),
            nonce.as_ptr(),
            key.as_ptr(),
        ),
        0
    );
    assert_eq!(maclen, 16);
    assert_ne!(in_place, message);

    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_decrypt_detached(
            in_place_ptr,
            ptr::null_mut(),
            in_place_ptr.cast_const(),
            in_place.len() as u64,
            mac.as_ptr(),
            ad.as_ptr(),
            ad.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        ),
        0
    );
    assert_eq!(in_place, message);

    let mut failed_buffer = {
        let mut ciphertext = message.clone();
        let ciphertext_ptr = ciphertext.as_mut_ptr();
        assert_eq!(
            aes256gcm::crypto_aead_aes256gcm_encrypt_detached(
                ciphertext_ptr,
                mac.as_mut_ptr(),
                &mut maclen,
                ciphertext_ptr.cast_const(),
                ciphertext.len() as u64,
                ad.as_ptr(),
                ad.len() as u64,
                ptr::null(),
                nonce.as_ptr(),
                key.as_ptr(),
            ),
            0
        );
        ciphertext
    };
    let expected_ciphertext = failed_buffer.clone();
    let failed_ptr = failed_buffer.as_mut_ptr();
    mac[0] ^= 0x80;
    assert_eq!(
        aes256gcm::crypto_aead_aes256gcm_decrypt_detached(
            failed_ptr,
            ptr::null_mut(),
            failed_ptr.cast_const(),
            failed_buffer.len() as u64,
            mac.as_ptr(),
            ad.as_ptr(),
            ad.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        ),
        -1
    );
    assert_eq!(failed_buffer, expected_ciphertext);
}
