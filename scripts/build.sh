#!/bin/bash -eE

# Copyright 2020 TON DEV SOLUTIONS LTD.
#
# Licensed under the SOFTWARE EVALUATION License (the "License"); you may not use
# this file except in compliance with the License.  You may obtain a copy of the
# License at:
#
# https://www.ton.dev/licenses
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific TON DEV software governing permissions and limitations
# under the License.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

if [ "${INSTALL_DEPENDENCIES}" = "yes" ]; then
    echo "INFO: install dependencies..."
    sudo apt update && sudo apt -y install \
        build-essential \
        cargo \
        ccache \
        cmake \
        gcc \
        gperf \
        g++ \
        libgflags-dev \
        libmicrohttpd-dev \
        libreadline-dev \
        libssl-dev \
        libz-dev \
        ninja-build \
        pkg-config \
        zlib1g-dev
    echo "INFO: install dependencies... DONE"
fi

rm -rf "${TON_SRC_DIR}"

echo "INFO: clone ${TON_GITHUB_REPO} (${TON_GITHUB_BRANCH})..."
git clone --recursive "${TON_GITHUB_REPO}" --branch "${TON_GITHUB_BRANCH}" "${TON_SRC_DIR}"
echo "INFO: clone ${TON_GITHUB_REPO} (${TON_GITHUB_BRANCH})... DONE"

# TODO remove after fix upstream
cd "${TON_SRC_DIR}"
git apply "${NET_TON_DEV_SRC_TOP_DIR}/patches/0001-Fix-for-neighbours-unreliability.patch"

echo "INFO: build a node..."
mkdir -p "${TON_BUILD_DIR}"
cd "${TON_BUILD_DIR}"
#cmake -DCMAKE_BUILD_TYPE=Release ..
#cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
#cmake --build .
cmake .. -G "Ninja" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DPORTABLE=ON -DTON_ARCH=corei7-avx
ninja
echo "INFO: build a node... DONE"

echo "INFO: build utils (convert_address)..."
cd "${NET_TON_DEV_SRC_TOP_DIR}/utils/convert_address"
cargo build --release
cp "${NET_TON_DEV_SRC_TOP_DIR}/utils/convert_address/target/release/convert_address" "${TON_BUILD_DIR}/utils/"
echo "INFO: build utils (convert_address)... DONE"

echo "INFO: build utils (tonos-cli)..."
git clone https://github.com/tonlabs/TVM-linker.git --branch tonlabscli/prepare-msg "${TONOS_CLI_SRC_DIR}"
cd "${TONOS_CLI_SRC_DIR}/TVM-linker/tonlabs-cli/" && cargo build --release
cp "${TONOS_CLI_SRC_DIR}/TVM-linker/tonlabs-cli/target/release/tonlabs-cli" "${TON_BUILD_DIR}/utils/tonos-cli"
echo "INFO: build utils (tonos-cli)... DONE"
