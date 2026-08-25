#! /bin/bash

set -o pipefail
set -e
set -x

source "$(dirname $0)/deps.sh"
if [[ $? -ne 0 ]]; then
  exit 1
fi

# Z3

mkdir -p ${DEP_Z3_DIR}
wget https://github.com/Z3Prover/z3/archive/refs/tags/z3-${DEP_Z3_VERSION}.zip -O ${DEP_Z3_DIR}/z3-${DEP_Z3_VERSION}.zip
unzip ${DEP_Z3_DIR}/z3-${DEP_Z3_VERSION}.zip -d ${DEP_Z3_DIR}
cmake -S ${DEP_Z3_SOURCE_DIR} -B ${DEP_Z3_BUILD_DIR} -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja -C ${DEP_Z3_BUILD_DIR}
if [[ ${LLVM_HARNESS_SKIP_INSTALL:-0} != 1 ]]; then
  sudo ninja -C ${DEP_Z3_BUILD_DIR} install
fi
