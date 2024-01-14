# SPDX-License-Identifier: Apache-2.0
#
# Copyright (c) 2022 Patrick Dung

# User has to run/provide their git repo
# when the container is run

ARG BASE_IMAGE="docker.io/ruby:3.2-slim-bookworm"

FROM ${BASE_IMAGE} as build

ARG GOLLUM_VERSION="5.3.2"

ARG GIT_BRANCH_NAME="main"

RUN set -eux && \
    apt-get -y update && \
    apt-get -y install --no-install-suggests \
      libicu-dev cmake make gcc g++ pkg-config git git-man bash docutils python3-pygments sed && \
    rm -rf /var/lib/apt/lists/*

# 1) https://github.com/gollum/docker/issues/2
# gem install --no-document therubyracer
# 2) Seems pygments is not effective
# 3) Not installing because it seems need to update the santizer to use it
# gem install pygments.rb

RUN set -eux && \
    gem install --no-document asciidoctor && \
    gem install --no-document gollum -v ${GOLLUM_VERSION}

# ---------------

FROM ${BASE_IMAGE}

ARG LABEL_IMAGE_URL
ARG LABEL_IMAGE_SOURCE

LABEL org.opencontainers.image.url=${LABEL_IMAGE_URL}
LABEL org.opencontainers.image.source=${LABEL_IMAGE_SOURCE}

RUN set -eux && \
    apt-get -y update && \
    apt-get -y install --no-install-suggests \
      pkg-config git git-man bash vim-tiny docutils python3-pygments sed libjemalloc2 && \
    apt-get -y purge linux-libc-dev && \
    apt-get -y upgrade && apt-get -y autoremove && apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
# Don't use git repo as home directoy \
    groupadd \
      --gid 1000 \
      wiki && \
    useradd --no-log-init \
      --create-home \
      --home-dir /home/wiki \
      --shell /bin/bash \
      --uid 1000 \
      --gid 1000 \
      --key MAIL_DIR=/dev/null \
      wiki && \
    mkdir -p /home/wiki/wikidata && \
    chown wiki:wiki /home/wiki/wikidata && \
    if [ -e /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 ] ; then ln -s /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so.2 ; fi && \
    if [ -e /usr/lib/aarch64-linux-gnu/libjemalloc.so.2 ] ; then ln -s /usr/lib/aarch64-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so.2 ; fi

COPY --from=build /usr/local/bundle/ /usr/local/bundle/
COPY entrypoint.sh /

##USER 1000:1000
USER wiki

VOLUME /home/wiki/wikidata

WORKDIR /home/wiki/wikidata

# For x86_64
#ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
# For arm64
#ENV LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libjemalloc.so.2
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
ENV WIKI_DATA_PATH=/home/wiki/wikidata
ENV GIT_BRANCH_NAME=main

# Locally make gollum assume default branch is main

#ENTRYPOINT ["gollum"]
#ENTRYPOINT gollum /wiki --ref ${GIT_BRANCH_NAME}
#In next line, ${GIT_BRANCH_NAME} would not be deferenced
#ENTRYPOINT ["gollum", "/wiki", "--ref", "${GIT_BRANCH_NAME}"]

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 4567
