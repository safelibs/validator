use std::path::PathBuf;
use std::process::Command;

fn run_checked(mut command: Command, context: &str) {
    let output = command.output().expect(context);
    if !output.status.success() {
        panic!(
            "{context} failed\nstdout:\n{}\nstderr:\n{}",
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr)
        );
    }
}

#[test]
fn release_cdylib_matches_full_symbol_manifest() {
    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let lib_path = manifest_dir.join("target/release/libsodium.so");
    let expected_manifest = manifest_dir.join("cabi/expected/full.symbols");
    let kinds_manifest = manifest_dir.join("cabi/expected/upstream-kinds.tsv");

    let mut cargo = Command::new("cargo");
    cargo
        .current_dir(&manifest_dir)
        .args(["build", "--release"]);
    run_checked(cargo, "cargo build --release");

    let mut check = Command::new(manifest_dir.join("tools/check-symbols.sh"));
    check
        .current_dir(&manifest_dir)
        .arg("--expected")
        .arg(&expected_manifest)
        .arg("--kinds")
        .arg(&kinds_manifest)
        .arg(&lib_path);
    run_checked(check, "symbol check");
}
