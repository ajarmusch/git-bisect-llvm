#!/bin/bash -e

if [[ $# -ne 1 ]] ; then
  echo "usage: $0 <ci-working-dir>"
  exit 1
fi

if [[ -z ${ARTIFACTS+x} ]] ; then
  echo warning: environment variable is not set: ARTIFACTS
  echo disabling automatic saving of artifacts
else
  mkdir -p $ARTIFACTS
fi


save() {
    if [[ ! -z ${ARTIFACTS+x} ]] ; then
      cp $@ $ARTIFACTS/.
    else
      true
    fi
}


GREEN='\033[0;32m'
NC='\033[0m'
cmd() {
  echo -e "${GREEN}+ $@ ${NC}"
  eval "$@"
}


cmd_tee() {
  echo -e "${GREEN}+ ${@:2} | tee $1 ${NC}"
  eval "${@:2}" | tee $1
}



# SET ENVIRONMENT VARIABLES
. ./env-nvidia.sh
if [[ -z ${CUDA_ROOT+x} ]] ; then
  echo "error: missing environment variable; please set CUDA_ROOT"
  exit 1
fi

cmd echo LD_LIBRARY_PATH=$LD_LIBRARY_PATH
cmd echo PATH=$PATH

cmd which clang
cmd clang --version

cmd which cmake
cmd cmake --version

cmd which ninja
cmd ninja --version


CI_WORKING_DIR=$1
LLVM_REPO=$CI_WORKING_DIR/../llvm-project
LLVM_TEST_SUITE_REPO=$CI_WORKING_DIR/../llvm-test-suite
SOLLVE_VV_REPO=$CI_WORKING_DIR/../sollve_vv
HECBENCH_REPO=$CI_WORKING_DIR/../hecbench

LLVM_BUILD=$CI_WORKING_DIR/../build
LLVM_INSTALL=$CI_WORKING_DIR/../llvm-install
LLVM_TEST_SUITE_BUILD=$CI_WORKING_DIR/../testing_sollve_external


# CLONE LLVM TEST SUITE
R=llvm-test-suite
L=$R-commit.txt
if [[ ! -d $LLVM_TEST_SUITE_REPO ]] ; then
  cmd git clone --depth=1 https://github.com/llvm/$R.git $LLVM_TEST_SUITE_REPO
fi
cmd_tee $L git -C $LLVM_TEST_SUITE_REPO log -1
cmd save $L


# CLONE SOLLVE VV
R=sollve_vv
L=$R-commit.txt
if [[ ! -d $SOLLVE_VV_REPO ]] ; then
  cmd git clone https://github.com/SOLLVE/$R.git $SOLLVE_VV_REPO
fi
cmd git -C $SOLLVE_VV_REPO checkout b3a4c2334ac2670ce02ca819907aa2d08eb1ce6d
cmd_tee $L git -C $SOLLVE_VV_REPO log -1
cmd save $L


# CLONE LLVM PROJECT
R=llvm-project
L=$R-commit.txt
if [[ ! -d $LLVM_REPO ]] ; then
  cmd git clone --depth=1 https://github.com/llvm/$R.git $LLVM_REPO
fi
cmd_tee $L git -C $LLVM_REPO log -1
cmd save $L


# BUILD LLVM
LLVM_TARGETS="X86;NVPTX"
LLVM_RUNTIMES="openmp"
LLVM_PROJECTS="clang;flang;mlir"
cmd mkdir $LLVM_BUILD
cmd cmake $LLVM_REPO/llvm \
 -B $LLVM_BUILD \
 -G Ninja \
 -DCMAKE_INSTALL_PREFIX=$LLVM_INSTALL \
 -DLLVM_ENABLE_PROJECTS=\"${LLVM_PROJECTS}\" \
 -DLLVM_ENABLE_RUNTIMES=\"${LLVM_RUNTIMES}\" \
 -DLLVM_ENABLE_ASSERTIONS=ON \
 -DLLVM_BUILD_EXAMPLES=ON \
 -DLLVM_TARGETS_TO_BUILD=\"${LLVM_TARGETS}\" \
 -DCMAKE_C_COMPILER=clang \
 -DCMAKE_CXX_COMPILER=clang++ \
 -DCMAKE_BUILD_TYPE=Release \
 -DRUNTIMES_CMAKE_ARGS="-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=True" \
 -DLIBOMPTARGET_BUILD_AMDGPU_PLUGIN=OFF \
 -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_ROOT
cmd ninja -C $LLVM_BUILD -j16
cmd ninja -C $LLVM_BUILD install -j16

cat <<EOF >$LLVM_INSTALL/bin/x86_64-unknown-linux-gnu-clang++.cfg
-L '<CFGDIR>/../lib'
-Wl,-rpath='<CFGDIR>/../lib'
EOF
cmd cp $LLVM_INSTALL/bin/x86_64-unknown-linux-gnu-clang++.cfg $LLVM_INSTALL/bin/x86_64-unknown-linux-gnu-clang.cfg

