# 4. Runtime, GUI, and Crypto Dependent Usage Cases

## Phase Name

Runtime, GUI, and Crypto Dependent Usage Cases

## Implement Phase ID

`impl_phase_04_runtime_crypto_usage_cases`

## Preexisting Inputs

- `tests/cjson/` concrete phase 1 output directory.
- `tests/libcsv/` concrete phase 1 output directory.
- `tests/libjson/` concrete phase 1 output directory.
- `tests/libxml/` concrete phase 1 output directory.
- `tests/libyaml/` concrete phase 1 output directory.
- `tests/libuv/` concrete phase 1 output directory.
- `tests/libarchive/` concrete phase 2 output directory.
- `tests/libbz2/` concrete phase 2 output directory.
- `tests/liblzma/` concrete phase 2 output directory.
- `tests/libzstd/` concrete phase 2 output directory.
- `tests/giflib/` concrete phase 3 output directory.
- `tests/libexif/` concrete phase 3 output directory.
- `tests/libjpeg-turbo/` concrete phase 3 output directory.
- `tests/libpng/` concrete phase 3 output directory.
- `tests/libtiff/` concrete phase 3 output directory.
- `tests/libvips/` concrete phase 3 output directory.
- `tests/libwebp/` concrete phase 3 output directory.
- `repositories.yml` canonical manifest and package list; consume it unchanged.
- `test.sh`
- `tools/testcases.py`
- `tools/run_matrix.py`
- `tools/verify_proof_artifacts.py`
- `tests/_shared/run_library_tests.sh`
- Existing `tests/libsdl/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing `tests/libsodium/` manifest, Dockerfile, dependent fixture, sample fixtures, and usage scripts.
- Existing tracked `artifacts/results/`, `artifacts/logs/`, `artifacts/casts/`, `artifacts/proof/original-validation-proof.json`, and `site/` evidence. Consume these artifacts in place; do not refetch, recollect, rediscover, regenerate, expand, or reorder dependent inventories.

## New Outputs

- 4 new usage testcase manifest entries.
- 4 new executable usage scripts.

## File Changes

- Modify `tests/libsdl/testcases.yml`.
- Add `tests/libsdl/tests/cases/usage/usage-python3-pygame-key-event.sh`.
- Add `tests/libsdl/tests/cases/usage/usage-python3-pygame-mask-collision.sh`.
- Modify `tests/libsodium/testcases.yml`.
- Add `tests/libsodium/tests/cases/usage/usage-python3-nacl-public-box.sh`.
- Add `tests/libsodium/tests/cases/usage/usage-php83-sodium-sign-detached.sh`.

## Implementation Details

- Apply the global testcase entry contract to all 4 new manifest entries:
  - Use the new script filename without `.sh` as each manifest entry `id`.
  - Set `kind: usage`.
  - Set `timeout_seconds: 180`.
  - Use a semantic `title`.
  - Use a client-behavior `description`.
  - Set `client_application` to one of the existing identifiers named below.
  - Set `command` exactly to `bash /validator/tests/<library>/tests/cases/usage/<script>.sh`.
  - Tags must include `usage` and one or more behavior tags already consistent with the library's local manifest style, such as `runtime`, `gui`, or `crypto`.
- Use only these existing dependent client identifiers:
  - `libsdl`: `python3-pygame`
  - `libsodium`: `python3-nacl` and `php8.3-cli`
- Do not modify any `tests/<library>/tests/fixtures/dependents.json`.
- Do not modify `repositories.yml`; it remains the fixed canonical manifest and package list.
- Do not modify any affected `tests/<library>/Dockerfile`; every dependent package required by the planned clients is already installed.
- `libsdl`:
  - `usage-python3-pygame-key-event.sh`: export `PYGAME_HIDE_SUPPORT_PROMPT=1` and `SDL_VIDEODRIVER=dummy` before Python starts, initialize pygame, post a `KEYDOWN` event for `pygame.K_a`, pump the event queue, and assert that exact key event is received.
  - `usage-python3-pygame-mask-collision.sh`: export `PYGAME_HIDE_SUPPORT_PROMPT=1` and `SDL_VIDEODRIVER=dummy`, create two `pygame.Surface((10, 10), pygame.SRCALPHA)` objects, fill them transparent, draw opaque overlapping rectangles, build masks with `pygame.mask.from_surface`, call `overlap` with a fixed offset, and assert the returned collision coordinate is the expected tuple.
- `libsodium`:
  - `usage-python3-nacl-public-box.sh`: use PyNaCl `PrivateKey.generate()`, derive two public keys, encrypt with `Box`, decrypt, and assert plaintext round trip.
  - `usage-php83-sodium-sign-detached.sh`: run PHP CLI using `sodium_crypto_sign_keypair`, `sodium_crypto_sign_detached`, and `sodium_crypto_sign_verify_detached`, then assert verification returns true.
- Make all new scripts executable.

## Verification Phases

- Phase ID: `check_phase_04_manifest_contract`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_04_runtime_crypto_usage_cases`
- Purpose: validate all testcase additions and final cumulative counts before threshold/doc/artifact updates.
- Commands:

```bash
python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --check \
  --min-source-cases 95 \
  --min-usage-cases 193 \
  --min-cases 288

python3 tools/testcases.py \
  --config repositories.yml \
  --tests-root tests \
  --list-summary
```

- Phase ID: `check_phase_04_matrix_smoke`
- Type: `check`
- Fixed `bounce_target`: `impl_phase_04_runtime_crypto_usage_cases`
- Purpose: run the affected GUI/runtime/crypto libraries with casts and verify selected proof output.
- Commands:

```bash
rm -rf /tmp/validator-more-cases-phase04
bash test.sh \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase04 \
  --record-casts \
  --library libsdl \
  --library libsodium

python3 tools/verify_proof_artifacts.py \
  --config repositories.yml \
  --tests-root tests \
  --artifact-root /tmp/validator-more-cases-phase04 \
  --proof-output /tmp/validator-more-cases-phase04/proof/original-validation-proof.json \
  --library libsdl \
  --library libsodium \
  --min-source-cases 10 \
  --min-usage-cases 21 \
  --min-cases 31 \
  --require-casts
```

## Success Criteria

- Phase 4 adds exactly 4 usage cases across `libsdl` and `libsodium` while leaving source cases unchanged.
- Manifest validation reports final target totals of 95 source cases, 193 usage cases, and 288 total cases.
- The list summary shows the final target totals: 95 source, 193 usage, and 288 total.
- The phase 4 matrix smoke passes with casts and selected proof totals of 10 source cases, 21 usage cases, and 31 total cases.
- Runtime scripts execute headlessly and do not require a real display, audio device, entropy service beyond normal container support, or network.
- Temporary verifier output under `/tmp/validator-more-cases-phase04` is not committed.
- `repositories.yml`, affected library Dockerfiles, dependent fixtures, prepared inventories, current tracked artifacts, proof data, and rendered site evidence are preserved unchanged unless explicitly updated by existing tools.

## Git Commit Requirement

The implementer must commit all phase 4 scoped work to git before yielding. Do not yield with uncommitted phase 4 file changes.
