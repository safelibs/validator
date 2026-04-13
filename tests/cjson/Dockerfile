FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      cmake \
      pkg-config \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY cjson/ /validator/tests/cjson/
COPY port/ /validator/port/

RUN if [ -f /validator/port/original/CMakeLists.txt ]; then \
      cmake \
        -S /validator/port/original \
        -B /tmp/cjson-original-build \
        -DENABLE_CJSON_TEST=OFF \
        -DENABLE_CJSON_UTILS=ON \
        -DBUILD_SHARED_AND_STATIC_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX=/usr; \
      cmake --build /tmp/cjson-original-build -j"$(nproc)"; \
      cmake --install /tmp/cjson-original-build; \
      ldconfig; \
      rm -rf /tmp/cjson-original-build; \
    else \
      apt-get update; \
      apt-get install -y --no-install-recommends libcjson-dev; \
      rm -rf /var/lib/apt/lists/*; \
    fi

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/cjson/docker-entrypoint.sh \
    /validator/tests/cjson/tests/run.sh
