FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      libyaml-dev \
      pkg-config \
 && rm -rf /var/lib/apt/lists/*

RUN triplet="$(gcc -print-multiarch)" \
 && mkdir -p \
      "/validator/tests/libyaml/original-package-root/usr/include" \
      "/validator/tests/libyaml/original-package-root/usr/lib/$triplet/pkgconfig" \
 && cp -a /usr/include/yaml.h /validator/tests/libyaml/original-package-root/usr/include/ \
 && cp -a /usr/lib/"$triplet"/libyaml*.so* /validator/tests/libyaml/original-package-root/usr/lib/"$triplet"/ \
 && if [ -f /usr/lib/"$triplet"/libyaml.a ]; then cp -a /usr/lib/"$triplet"/libyaml.a /validator/tests/libyaml/original-package-root/usr/lib/"$triplet"/; fi \
 && cp -a /usr/lib/"$triplet"/pkgconfig/yaml-0.1.pc /validator/tests/libyaml/original-package-root/usr/lib/"$triplet"/pkgconfig/

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libyaml/ /validator/tests/libyaml/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/libyaml/docker-entrypoint.sh \
    /validator/tests/libyaml/tests/run.sh
