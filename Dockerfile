FROM alpine:3.9
MAINTAINER Nate Wilken <wilken@asu.edu>

ENV DOCKER_BASE_VERSION=0.0.4
ENV CONSUL_VERSION=1.4.0
ENV VAULT_VERSION=1.1.2

ENV HASHICORP_RELEASES=https://releases.hashicorp.com

WORKDIR /home/jenkins
RUN addgroup -g 1000 jenkins \
 && adduser -D -h /home/jenkins -s /bin/bash -u 1000 -G jenkins jenkins \
 && chmod 755 . \
 && mkdir -p .ssh \
 && echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> .ssh/config \
 && chmod 0600 .ssh/config \
 && chown -R jenkins:jenkins .

RUN addgroup -g 513 docker

WORKDIR /tmp
RUN apk update \
 && apk add --no-cache bash less curl git openssh make docker jq python groff gettext \
 && apk add --no-cache --virtual .build-deps gnupg gcc musl-dev libffi-dev openssl-dev python-dev py-pip \
 && pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir python-gilt \
 && pip install --no-cache-dir awscli s3cmd \
 && pip install --no-cache-dir docker-compose \
 && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C \
 && wget ${HASHICORP_RELEASES}/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip \
 && wget ${HASHICORP_RELEASES}/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS \
 && wget ${HASHICORP_RELEASES}/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig \
 && gpg --batch --verify docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS \
 && set -o pipefail && grep docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS | sha256sum -c \
 && unzip -d /bin -j docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip bin/gosu bin/dumb-init \
 && rm docker-base_* \
 && wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip \
 && wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS \
 && wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig \
 && gpg --batch --verify consul_${CONSUL_VERSION}_SHA256SUMS.sig consul_${CONSUL_VERSION}_SHA256SUMS \
 && set -o pipefail && grep consul_${CONSUL_VERSION}_linux_amd64.zip consul_${CONSUL_VERSION}_SHA256SUMS | sha256sum -c \
 && unzip -d /bin consul_${CONSUL_VERSION}_linux_amd64.zip \
 && rm consul_* \
 && wget ${HASHICORP_RELEASES}/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \
 && wget ${HASHICORP_RELEASES}/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS \
 && wget ${HASHICORP_RELEASES}/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig \
 && gpg --batch --verify vault_${VAULT_VERSION}_SHA256SUMS.sig vault_${VAULT_VERSION}_SHA256SUMS \
 && set -o pipefail && grep vault_${VAULT_VERSION}_linux_amd64.zip vault_${VAULT_VERSION}_SHA256SUMS | sha256sum -c \
 && unzip -d /bin vault_${VAULT_VERSION}_linux_amd64.zip \
 && rm vault_* \
 && rm -rf /root/.gnupg \
 && rm -rf /root/.cache \
 && apk del --purge --no-cache .build-deps

WORKDIR /
CMD ["/bin/bash"]
