#! /bin/bash

set -o pipefail
set -e
set -x

source "$(dirname $0)/deps.sh"
if [[ $? -ne 0 ]]; then
  exit 1
fi

#-================================
# Python dependencies
#-================================

# We assume that the python3 executable is available in the PATH.
PYTHON3=python${DEP_PY3_VERSION}
if ! command -v ${PYTHON3} > /dev/null 2>&1; then
  echo "Error: Python ${DEP_PY3_VERSION} is not installed. We require the version as your GDB is reliant on it. Please install it first."
  exit 1
fi
${PYTHON3} -m venv ${DEP_PY3_VENV_DIR}

#-================================
# tree-sitter
#-================================

# We need the tree-sitter C library to build the tree-sitter Python bindings.
mkdir -p ${DEP_TREE_SITTER_DIR}
git clone https://github.com/tree-sitter/tree-sitter.git ${DEP_TREE_SITTER_SOURCE_DIR}
git -C ${DEP_TREE_SITTER_SOURCE_DIR} checkout ${DEP_TREE_SITTER_VERSION}
mkdir -p ${DEP_PY3_VENV_DIR}/include
cp -r ${DEP_TREE_SITTER_SOURCE_DIR}/lib/src/ ${DEP_PY3_VENV_DIR}/include/tree_sitter

#-================================
# Python packages
#-================================

source ${DEP_PY3_VENV_DIR}/bin/activate
REQUIREMENTS_TXT=${LLVM_HARNESS_INSTALL_SCRIPT_DIR}/requirements.txt
if [[ ! -f ${REQUIREMENTS_TXT} ]]; then
  REQUIREMENTS_TXT=$(cd $(dirname $0) && pwd)/../requirements.txt
fi
pip install -r ${REQUIREMENTS_TXT}