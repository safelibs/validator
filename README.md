# Validators for SafeLibs

The SafeLibs projects aims to rewrite loadbearing libraries in memory safe languages.
To support this, we need to have thorough testsets of actual applications dependent on these libraries.
This repository has these test sets.

## Structure

For each libary `LIBNAME`:

- `tests/LIBNAME/Dockerfile`: defines a docker image that installs LIBNAME and the relevant dependent applications. The "original" version of `LIBNAME` (e.g. from the normal apt repos) is installed.
- `tests/LIBNAME/docker-entrypoint.sh`: The entrypoint. It should install all replacement debs from `/safedebs/*.deb` (which will be specified with `-v` to `docker run`) if provided, then run the tests and exits cleanly if they all pass.
- `tests/LIBNAME/tests/`: The tests. They should make sure that the libraries work. The tests should not know or depend on which version (safe or original) of the library they're running on. It is a violation to check.
- `test.sh`: runs all the tests (or a specific `LIBNAME` test if needed)

## Evidence

The CI of this repository:

- runs tests for both the original and the safe version
- reports the results
- records an asciicinema of the safe version runs (tests should run with `bash -x` for viewability)
- publishes a github pages of the result (if on main branch)
