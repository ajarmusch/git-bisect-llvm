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

LLVM_BUILD=$CI_WORKING_DIR/../build
LLVM_INSTALL=$CI_WORKING_DIR/../llvm-install
LLVM_TEST_SUITE_BUILD=$CI_WORKING_DIR/../testing_sollve_external


# BUILD LLVM TEST SUITE
cmd echo LD_LIBRARY_PATH=$LD_LIBRARY_PATH
cmd echo PATH=$PATH
cmd export PATH=$LLVM_INSTALL/bin:$PATH
cmd which clang
cmd clang --version
cmd cmake $LLVM_TEST_SUITE_REPO \
 -B $LLVM_TEST_SUITE_BUILD \
 -DCMAKE_BUILD_TYPE=Release \
 -DTEST_SUITE_SOLLVEVV_ROOT=$SOLLVE_VV_REPO \
 -DTEST_SUITE_LIT=$LLVM_BUILD/bin/llvm-lit \
 -DCMAKE_C_COMPILER=clang \
 -DCMAKE_CXX_COMPILER=clang++ \
 -DTEST_SUITE_SUBDIRS="./External/sollve_vv" \
 -DTEST_SUITE_OFFLOADING_FLAGS="-fopenmp-targets=nvptx64-nvidia-cuda\;--cuda-path=$CUDA_ROOT\;-Xopenmp-target\;-march=sm_90" \
 -DTEST_SUITE_OFFLOADING_LDFLAGS="-fopenmp-targets=nvptx64-nvidia-cuda\;--cuda-path=$CUDA_ROOT\;-Xopenmp-target\;-march=sm_90\;-lomptarget" \
 -DTEST_SUITE_LIT_FLAGS=-vv \
 -DSYSTEM_GPU=nvidia
cmd make -C $LLVM_TEST_SUITE_BUILD -j16




# RUN LLVM TEST SUITE
cmd cd $LLVM_TEST_SUITE_BUILD
cmd $LLVM_BUILD/bin/llvm-lit -v -j 12 -o results.json . || true
