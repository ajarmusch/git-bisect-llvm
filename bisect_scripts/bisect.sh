#!/bin/bash
KNOWN_BAD=68f0edfa359fde3fb4f5ec391a4afe96f3905aaf
KNOWN_GOOD=249cf356ef21d0b6ed0d1fa962f3fc5a9e3fcc9e
cd llvm-project_DIR

git bisect start
git bisect bad $KNOWN_BAD
git bisect good $KNOWN_GOOD

git bisect run ./run_llvmBuild_app.sh
git bisect reset
