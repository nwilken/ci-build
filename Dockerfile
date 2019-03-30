FROM alpine:3.8
MAINTAINER Nate Wilken <wilken@asu.edu>

ENV DOCKER_BASE_VERSION=0.0.4
ENV CONSUL_VERSION=1.4.0
ENV VAULT_VERSION=1.0.2
ENV NOTARY_VERSION=0.6.1

ENV HASHICORP_RELEASES=https://releases.hashicorp.com

RUN addgroup -g 513 docker && \
    apk update && \
    apk add --no-cache bash ca-certificates curl gnupg libcap openssl git openssh make gcc musl-dev libffi-dev openssl-dev python-dev docker py-pip jq gettext && \
    pip install --upgrade pip && \
    pip install --no-cache-dir docker-compose && \
    pip install --no-cache-dir python-gilt && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    wget ${HASHICORP_RELEASES}/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip && \
    wget ${HASHICORP_RELEASES}/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS && \
    wget ${HASHICORP_RELEASES}/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS.sig docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS && \
    grep ${DOCKER_BASE_VERSION}_linux_amd64.zip docker-base_${DOCKER_BASE_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip && \
    cp bin/gosu bin/dumb-init /bin && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify consul_${CONSUL_VERSION}_SHA256SUMS.sig consul_${CONSUL_VERSION}_SHA256SUMS && \
    grep consul_${CONSUL_VERSION}_linux_amd64.zip consul_${CONSUL_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /bin consul_${CONSUL_VERSION}_linux_amd64.zip && \
    wget ${HASHICORP_RELEASES}/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
    wget ${HASHICORP_RELEASES}/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS && \
    wget ${HASHICORP_RELEASES}/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify vault_${VAULT_VERSION}_SHA256SUMS.sig vault_${VAULT_VERSION}_SHA256SUMS && \
    grep vault_${VAULT_VERSION}_linux_amd64.zip vault_${VAULT_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /bin vault_${VAULT_VERSION}_linux_amd64.zip && \
    cd /tmp && \
    rm -rf /tmp/build && \
    wget https://github.com/theupdateframework/notary/releases/download/v${NOTARY_VERSION}/notary-Linux-amd64 && \
    mv notary-Linux-amd64 /bin/notary && \
    chmod +x /bin/notary && \
    apk del gnupg openssl gcc musl-dev libffi-dev openssl-dev python-dev && \
    rm -rf /root/.gnupg && \
    addgroup -g 1000 jenkins && \
    adduser -D -h /home/jenkins -s /bin/bash -u 1000 -G jenkins jenkins && \
    chmod 755 /home/jenkins && \
    mkdir -p /home/jenkins/.ssh && \
    echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> /home/jenkins/.ssh/config && \
    chmod 0600 /home/jenkins/.ssh/config && chown -R jenkins:jenkins /home/jenkins/.ssh

VOLUME /usr/src/app

WORKDIR /usr/src/app

CMD ["/bin/bash"]
