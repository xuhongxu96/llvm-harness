#! /bin/bash

set -o pipefail
set -e
set -x

source "$(dirname $0)/deps.sh"
if [[ $? -ne 0 ]]; then
  exit 1
fi

# alive2

mkdir -p ${DEP_ALIVE2_DIR}
git clone https://github.com/AliveToolkit/alive2 ${DEP_ALIVE2_SOURCE_DIR}
git -C ${DEP_ALIVE2_SOURCE_DIR} checkout ${DEP_ALIVE2_VERSION}
cmake -S ${DEP_ALIVE2_SOURCE_DIR} -B ${DEP_ALIVE2_BUILD_DIR} -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja -C ${DEP_ALIVE2_BUILD_DIR}
cmake -S ${DEP_ALIVE2_SOURCE_DIR} -B ${DEP_ALIVE2_BUILD_DIR} -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=${DEP_LLVM_BUILD_DIR} -DBUILD_TV=1
ninja -C ${DEP_ALIVE2_BUILD_DIR}
if [[ ${LLVM_HARNESS_SKIP_INSTALL:-0} != 1 ]]; then
  sudo ninja -C ${DEP_ALIVE2_BUILD_DIR} install
fi
