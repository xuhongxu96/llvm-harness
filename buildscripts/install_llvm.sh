#! /bin/bash

set -o pipefail
set -e
set -x

source "$(dirname $0)/deps.sh"
if [[ $? -ne 0 ]]; then
  exit 1
fi

#-================================
# LLVM: Preprocessing
#-================================

# llvm

mkdir ${DEP_LLVM_DIR}
git clone https://github.com/llvm/llvm-project ${DEP_LLVM_SOURCE_DIR}
git -C ${DEP_LLVM_SOURCE_DIR} config user.name "llvm-harness"
git -C ${DEP_LLVM_SOURCE_DIR} config user.email "llvm-harness@example.org"
git -C ${DEP_LLVM_SOURCE_DIR} checkout ${DEP_LLVM_VERSION} # We will reuse the repo for the repair task later.
cmake -S ${DEP_LLVM_SOURCE_DIR}/llvm -B ${DEP_LLVM_BUILD_DIR} -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_RTTI=ON \
  -DBUILD_SHARED_LIBS=ON \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS \
  -DLLVM_ENABLE_PROJECTS="llvm;clang"
ninja -C ${DEP_LLVM_BUILD_DIR}
if [[ ${LLVM_HARNESS_SKIP_INSTALL:-0} != 1 ]]; then
  sudo ninja -C ${DEP_LLVM_BUILD_DIR} install
fi

# ccache

mkdir -p ${DEP_CCACHE_DIR}
wget https://github.com/ccache/ccache/releases/download/v${DEP_CCACHE_VERSION}/ccache-${DEP_CCACHE_VERSION}.tar.gz -O ${DEP_CCACHE_DIR}/ccache-${DEP_CCACHE_VERSION}.tar.gz
tar -xavf ${DEP_CCACHE_DIR}/ccache-${DEP_CCACHE_VERSION}.tar.gz --directory ${DEP_CCACHE_DIR}
cmake -S ${DEP_CCACHE_SOURCE_DIR} -B ${DEP_CCACHE_BUILD_DIR} -G Ninja -DCMAKE_BUILD_TYPE=Release
ninja -C ${DEP_CCACHE_BUILD_DIR}
if [[ ${LLVM_HARNESS_SKIP_INSTALL:-0} != 1 ]]; then
  sudo ninja -C ${DEP_CCACHE_BUILD_DIR} install
fi
