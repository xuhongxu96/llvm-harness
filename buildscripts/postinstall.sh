#! /bin/bash

set -o pipefail
set -e
set -x

source "$(dirname $0)/deps.sh"
if [[ $? -ne 0 ]]; then
  exit 1
fi

#-================================
# LLVM: Postprocessing
#-================================

# Pull the latest commits to make sure the repo is up-to-date.
git -C ${DEP_LLVM_SOURCE_DIR} checkout main
git -C ${DEP_LLVM_SOURCE_DIR} pull origin main

#-================================
# Cleanup dependencies
#-================================

rm -rf ${DEP_LLVM_BUILD_DIR} \
  ${DEP_CCACHE_DIR} \
  ${DEP_Z3_DIR} \
  ${DEP_RE2C_DIR} \
  ${DEP_ALIVE2_DIR} \
  ${DEP_LLUBI_LEGACY_DIR} \
  ${DEP_ANTLR4_DIR}
