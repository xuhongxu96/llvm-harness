#! /bin/bash

set -o pipefail
set -e
set -x

#-=============================================================================
# This script is used to install the dependencies of llvm-harness.
#
# - LLVM: https://github.com/llvm/llvm-project
# - alive2: https://github.com/AliveToolkit/alive2
# - Required python dependencies: requirements.txt
#
# All the dependencies will be downloaded into the $LLVM_HARNESS_DEPS_DIR
# directory and install into the system. Therefore, this script requires
# the root permission When necessary, the source code will be kept.
#
# It will also create a virtual environment for Python3 dependencies.
#-=============================================================================


source "$(dirname $0)/deps.sh"
if [[ $? -ne 0 ]]; then
  exit 1
fi


#-================================
# LLVM: Preprocessing
#-================================

# llvm

bash ${LLVM_HARNESS_INSTALL_SCRIPT_DIR}/install_llvm.sh

#-================================
# alive2
#-================================

# Z3

bash ${LLVM_HARNESS_INSTALL_SCRIPT_DIR}/install_z3.sh

# re2c

bash ${LLVM_HARNESS_INSTALL_SCRIPT_DIR}/install_re2c.sh

# alive2

bash ${LLVM_HARNESS_INSTALL_SCRIPT_DIR}/install_alive2.sh

#-================================
# backend-tv
#-================================

# # aslp-server
# 
# curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
# mkdir -p ~/.config/nix
# printf "extra-trusted-users = $LLVM_HARNESS_ADMIN_USERNAME\nexperimental-features = nix-command flakes\n" | tee -a ~/.config/nix/nix.conf
# PATH=~/.nix-profile/bin:$PATH
# 
# # antlr4
# 
# mkdir -p ${DEP_ANTLR4_SOURCE_DIR}
# wget https://www.antlr.org/download/antlr-${DEP_ANTLR4_VERSION}-complete.jar -O ${DEP_ANTLR4_SOURCE_DIR}/antlr-complete.jar
# wget https://www.antlr.org/download/antlr4-cpp-runtime-${DEP_ANTLR4_VERSION}-source.zip -O ${DEP_ANTLR4_SOURCE_DIR}/antlr-runtime.zip
# unzip ${DEP_ANTLR4_SOURCE_DIR}/antlr-runtime.zip -d ${DEP_ANTLR4_SOURCE_DIR}
# cmake -S ${DEP_ANTLR4_SOURCE_DIR} -B ${DEP_ANTLR4_BUILD_DIR} -G Ninja \
#   -DCMAKE_BUILD_TYPE=Release -DANTLR4_INSTALL=ON
# ninja -C ${DEP_ANTLR4_BUILD_DIR}
# sudo ninja -C ${DEP_ANTLR4_BUILD_DIR} install
# 
# # backend-tv
# 
# mkdir -p ${DEP_BACKEND_TV_DIR}
# git clone https://github.com/regehr/alive2 ${DEP_BACKEND_TV_SOURCE_DIR}
# git -C ${DEP_BACKEND_TV_SOURCE_DIR} checkout ${DEP_BACKEND_TV_VERSION}
# mkdir -p ${DEP_BACKEND_TV_BUILD_DIR}
# nix build 'github:katrinafyi/pac-nix#aslp-server' -o ${DEP_BACKEND_TV_BUILD_DIR}/aslp
# nix build 'nixpkgs#varnish' -o ${DEP_BACKEND_TV_BUILD_DIR}/varnish
# cmake -S ${DEP_BACKEND_TV_SOURCE_DIR} -B ${DEP_BACKEND_TV_BUILD_DIR} -DBUILD_TV=1 \
#   -DLLVM_DIR=${DEP_LLVM_BUILD_DIR}/lib/cmake/llvm \
#   -DANTLR4_JAR_LOCATION=${DEP_ANTLR4_SOURCE_DIR}/antlr-complete.jar \
#   -G Ninja -DCMAKE_BUILD_TYPE=Release
# ninja -C ${DEP_BACKEND_TV_BUILD_DIR}

#-================================
# llubi (legacy)
#-================================

bash ${LLVM_HARNESS_INSTALL_SCRIPT_DIR}/install_llubi.sh

#-================================
# Python dependencies
#-================================

bash ${LLVM_HARNESS_INSTALL_SCRIPT_DIR}/install_py_deps.sh

#-================================
# LLVM: Postprocessing
#-================================

bash ${LLVM_HARNESS_INSTALL_SCRIPT_DIR}/postinstall.sh

