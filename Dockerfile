FROM amazonlinux:2 AS base

RUN set -x && \
    yum update -y && \
    yum clean all -y && \
    rm -rf /var/cache/yum /var/log/yum.log

FROM asuuto/hashicorp-installer:latest AS installer

RUN /install-hashicorp-tool "docker-base" "0.0.4"
RUN /install-hashicorp-tool "consul" "1.9.4"
RUN /install-hashicorp-tool "vault" "1.6.3"

FROM base AS build

RUN set -x && \
    yum install -y tar curl gzip && \
    curl -sSL "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o docker-compose && \
    chmod +x docker-compose && \
    curl -sSL https://download.docker.com/linux/static/stable/x86_64/docker-20.10.5.tgz -o /docker.tgz && \
    tar xvfz /docker.tgz

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
    yum install -y git tar zip python-pip jq gettext && \
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
COPY --from=build /docker /usr/local/bin

WORKDIR /
CMD ["/bin/bash"]
