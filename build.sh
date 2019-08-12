#!/usr/bin/env bash
set -e

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

# This script will download the IEC Core source code, build the IEC components and create distributables containing the
# components. The script is intended to be run inside the docker container where the IEC dependencies were built.

# Set the variables required by the build process
root_dir=$(pwd)
bin_dir=${root_dir}/build/bin
lib_dir=${root_dir}/build/lib
inc_dir=${root_dir}/build/include
dist_dir=${root_dir}/build/dist
src_dir=${root_dir}/build/src/stash.forgerock.org/iot/identity-edge-controller-core/
# If IEC_CORE_SRC is set then use it for the src dir
if [[ -n ${IEC_CORE_SRC} ]]; then
    src_dir=${IEC_CORE_SRC}
fi
GOPATH=${root_dir}/build

# Clean the build output directories
rm -rf ${bin_dir} && mkdir -p ${bin_dir}
rm -rf ${lib_dir} && mkdir -p ${lib_dir}
rm -rf ${inc_dir} && mkdir -p ${inc_dir}
rm -rf ${dist_dir} && mkdir -p ${dist_dir}

# Fetch the IEC Core source and its dependencies
go get -u -d -t stash.forgerock.org/iot/identity-edge-controller-core/...

# Set the version and platform information variables
source ${src_dir}/version/platform-linux-x86_64.txt
source ${src_dir}/version/version.txt

# If IEC_CORE_SRC is set then prepend it to GOPATH before building the IEC components
# We create a symbolic link in order to add the full project path to the GOPATH
if [[ -n ${IEC_CORE_SRC} ]]; then
    mkdir -p /tmp/iec-gopath/src/stash.forgerock.org/iot/identity-edge-controller-core/
    ln -s ${IEC_CORE_SRC}/* /tmp/iec-gopath/src/stash.forgerock.org/iot/identity-edge-controller-core/
    GOPATH=/tmp/iec-gopath:${GOPATH}
fi

# Build the IEC components
go build -ldflags "${VERSION_INFO}" -tags 'logicrichos securerichos' -o ${bin_dir}/iecservice stash.forgerock.org/iot/identity-edge-controller-core/cmd/iecservice
go build -ldflags "${VERSION_INFO}" -tags 'logicrichos securerichos' -o ${bin_dir}/iecutil stash.forgerock.org/iot/identity-edge-controller-core/cmd/iecutil
go build -ldflags "${VERSION_INFO}" -tags 'logicrichos securerichos' -o ${bin_dir}/libiecclient.so -buildmode=c-shared stash.forgerock.org/iot/identity-edge-controller-core/cmd/iecsdk

# Copy over the IEC dependencies
cp -P /usr/local/lib/libsodium.so* ${lib_dir}
cp -P /usr/local/lib/libzmq.so* ${lib_dir}

# Copy over the IEC C SDK library and include files
cp ${bin_dir}/libiecclient.so ${lib_dir}
cp ${bin_dir}/libiecclient.h ${inc_dir}
cp ${src_dir}/cmd/iecsdk/libiectypes.h ${inc_dir}

# Build the SDK examples
mkdir -p ${bin_dir}/examples/simpleclient
/usr/bin/x86_64-linux-gnu-gcc ${src_dir}/cmd/iecsdk/deploy/examples/simpleclient/simpleclient.c \
    -o ${bin_dir}/examples/simpleclient/simpleclient -I${inc_dir} -L${lib_dir} -liecclient -lsodium -lzmq

# Create a tarball that contains all the files required to install the IEC Service
tar -czf ${dist_dir}/iec-service-${PLATFORM}-${TRUST}-${VERSION_NUMBER}.tgz \
    -C ${bin_dir} iecutil iecservice \
    -C ${src_dir}/cmd/iecservice/deploy iec-config.json \
    -C ${src_dir}/cmd/iecservice/deploy/linux iec.service install.sh \
    -C ${lib_dir}/.. lib

# Create a tarball that contains all the files required to install the IEC C SDK
tar -czf ${dist_dir}/iec-sdk-${PLATFORM}-${TRUST}-${VERSION_NUMBER}.tgz \
    -C ${bin_dir} iecutil \
    -C ${src_dir}/cmd/iecsdk/deploy examples sdk-config.json build-examples.sh run-examples.sh \
    -C ${root_dir}/build lib include \
    -C ${bin_dir} examples
