ARG bashver=latest

# FROM bash:${bashver}
FROM centos:7
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]
RUN yum install -y wget

# ARG TINI_VERSION=v0.19.0
ARG TARGETPLATFORM
ARG LIBS_VER_SUPPORT=0.3.0
ARG LIBS_VER_FILE=0.4.0
ARG LIBS_VER_ASSERT=2.1.0
ARG LIBS_VER_DETIK=1.1.0
ARG UID=1001
ARG GID=115


# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL maintainer="Bats-core Team"
LABEL org.opencontainers.image.authors="Bats-core Team"
LABEL org.opencontainers.image.title="Bats"
LABEL org.opencontainers.image.description="Bash Automated Testing System"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/bats/bats"
LABEL org.opencontainers.image.source="https://github.com/bats-core/bats-core"
LABEL org.opencontainers.image.base.name="docker.io/bash"


COPY ./docker /tmp/docker
# default to amd64 when not running in buildx environment that provides target platform
# RUN /tmp/docker/install_tini.sh "${TARGETPLATFORM-linux/amd64}"
# Install bats libs
RUN /tmp/docker/install_libs.sh support ${LIBS_VER_SUPPORT}
RUN /tmp/docker/install_libs.sh file ${LIBS_VER_FILE}
RUN /tmp/docker/install_libs.sh assert ${LIBS_VER_ASSERT}
RUN /tmp/docker/install_libs.sh detik ${LIBS_VER_DETIK}

RUN yum install -y epel-release
# Install parallel and accept the citation notice (we aren't using this in a
# context where it make sense to cite GNU Parallel).
RUN yum install -y parallel ncurses file bzip2 which cronie sudo libfaketime strace && \
    mkdir -p ~/.parallel && touch ~/.parallel/will-cite \
    && mkdir /code

RUN ln -s /opt/bats/bin/bats /usr/local/bin/bats
COPY . /opt/bats/
RUN sudo cp /opt/bats/sudoers /etc/
RUN sudo chown root:root /etc/sudoers

RUN rm -rf /etc/localtime
RUN ln -s /usr/share/zoneinfo/America/Toronto /etc/localtime

WORKDIR /code


# ENTRYPOINT ["/usr/sbin/init", "--", "bash", "echo hi"]
ENTRYPOINT ["bats", "/opt/bats/test"]

