#! /bin/bash

set -o pipefail
set -e
set -x

source "$(dirname $0)/deps.sh"
if [[ $? -ne 0 ]]; then
  exit 1
fi

#-================================
# llubi (legacy)
#-================================

mkdir -p ${DEP_LLUBI_LEGACY_DIR}
git clone https://github.com/dtcxzyw/llvm-ub-aware-interpreter ${DEP_LLUBI_LEGACY_SOURCE_DIR}
git -C ${DEP_LLUBI_LEGACY_SOURCE_DIR} checkout ${DEP_LLUBI_LEGACY_VERSION}
cmake -S ${DEP_LLUBI_LEGACY_SOURCE_DIR} -B ${DEP_LLUBI_LEGACY_BUILD_DIR} -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_DIR=${DEP_LLVM_BUILD_DIR}/lib/cmake/llvm
ninja -C ${DEP_LLUBI_LEGACY_BUILD_DIR}
if [[ ${LLVM_HARNESS_SKIP_INSTALL:-0} != 1 ]]; then
  sudo mv ${DEP_LLUBI_LEGACY_BUILD_DIR}/llubi /usr/local/bin/llubi_legacy
fi
