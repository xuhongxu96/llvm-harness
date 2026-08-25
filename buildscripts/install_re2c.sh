#! /bin/bash

set -o pipefail
set -e
set -x

source "$(dirname $0)/deps.sh"
if [[ $? -ne 0 ]]; then
  exit 1
fi

# re2c

mkdir -p ${DEP_RE2C_DIR}
wget https://github.com/skvadrik/re2c/releases/download/${DEP_RE2C_VERSION}/re2c-${DEP_RE2C_VERSION}.tar.xz -O ${DEP_RE2C_DIR}/re2c-${DEP_RE2C_VERSION}.tar.xz
tar -xavf ${DEP_RE2C_DIR}/re2c-${DEP_RE2C_VERSION}.tar.xz --directory ${DEP_RE2C_DIR}
cmake -S ${DEP_RE2C_SOURCE_DIR} -B ${DEP_RE2C_BUILD_DIR} -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja -C ${DEP_RE2C_BUILD_DIR}
if [[ ${LLVM_HARNESS_SKIP_INSTALL:-0} != 1 ]]; then
  sudo ninja -C ${DEP_RE2C_BUILD_DIR} install
fi
