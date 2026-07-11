FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    dnsutils \
    git \
    iproute2 \
    jq \
    nano \
    procps \
    sudo \
    tzdata \
    vim-tiny \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["sleep", "infinity"]

