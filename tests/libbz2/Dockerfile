FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libbz2-1.0 \
      libbz2-dev \
      bzip2 \
      bash \
      build-essential \
      ca-certificates \
      coreutils \
      file \
      jq \
      perl \
      pkg-config \
      python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libbz2/ /validator/tests/libbz2/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libbz2/docker-entrypoint.sh /validator/tests/libbz2/tests/run.sh \
 && if [ -d /validator/tests/libbz2/tests/cases ]; then \
      find /validator/tests/libbz2/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
