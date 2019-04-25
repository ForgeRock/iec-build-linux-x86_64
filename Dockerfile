#
# Copyright 2019 ForgeRock AS
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

FROM golang:1.12.3-stretch

ENV CONTAINER_NAME linux-x86_64

RUN apt-get update -y && apt-get install -y \
    libtool \
    autoconf \
    automake

WORKDIR /root

ADD https://download.libsodium.org/libsodium/releases/libsodium-1.0.17.tar.gz .
RUN tar xf libsodium-1.0.17.tar.gz && \
    cd libsodium-1.0.17 && \
    ./configure && \
    make install

ADD https://github.com/zeromq/libzmq/releases/download/v4.2.5/zeromq-4.2.5.tar.gz .
RUN tar xf zeromq-4.2.5.tar.gz && \
    cd zeromq-4.2.5 && \
    ./autogen.sh && \
    ./configure --with-libsodium --without-docs --enable-drafts && \
    make install

WORKDIR /root/iec
