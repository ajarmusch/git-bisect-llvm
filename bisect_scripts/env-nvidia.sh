#!/bin/bash

# export CCACHE_DIR=/scratch/sollve/ccache

export CUDA_ROOT=/packages/cuda/12.0.1
export PATH=$CUDA_ROOT/bin:$PATH
export PATH=/usr/local/llvm/16.0.6/bin:/opt/spack-bootstrap/view/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_ROOT/lib64:$LD_LIBRARY_PATH