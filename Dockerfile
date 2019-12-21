FROM amazonlinux:2 AS base

RUN set -x && \
    yum update -y && \
    yum clean all -y && \
    rm -rf /var/cache/yum /var/log/yum.log

FROM asuuto/hashicorp-installer:latest AS installer

RUN /install-hashicorp-tool "docker-base" "0.0.4"
RUN /install-hashicorp-tool "consul" "1.4.0"
RUN /install-hashicorp-tool "vault" "1.1.2"

FROM base AS build

RUN set -x && \
    curl -sSL "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o docker-compose && \
    chmod +x docker-compose

FROM base AS final
LABEL maintainer="Nate Wilken <wilken@asu.edu>"

ARG USERID=1000
ARG GROUPID=1000
ARG USER=jenkins
ARG GROUP=jenkins

RUN set -x && \
    yum install -y shadow-utils && \
    groupadd -g 513 docker && \
    groupadd -g ${GROUPID} ${GROUP} && \
    useradd -M -N -s /bin/bash -u ${USERID} -g ${GROUPID} ${USER} && \
    yum remove -y shadow-utils && \
    curl -sSL https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo && \
    curl -sSL https://download.docker.com/linux/centos/gpg -o /etc/pki/rpm-gpg/docker-gpg && \
    yum install -y git tar docker-ce-cli python-pip jq gettext && \
    yum clean all -y && \
    rm -rf /var/cache/yum /var/log/yum.log && \
    pip install --upgrade pip && \
    pip install awscli s3cmd python-gilt j2cli && \
    rm -rf /root/.cache/pip

WORKDIR /home/${USER}
RUN set -x && \
    chmod 755 . && \
    mkdir -p .ssh && \
    echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> .ssh/config && \
    chmod 600 .ssh/config && \
    chown -R ${USER}:${GROUP} .

COPY --from=installer /software/docker-base/bin /bin
COPY --from=installer /software/consul /bin
COPY --from=installer /software/vault /bin
COPY --from=build /docker-compose /usr/local/bin

WORKDIR /
CMD ["/bin/bash"]
