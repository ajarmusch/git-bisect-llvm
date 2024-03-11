#!/bin/bash

FROM_DIR=/git-bisect-llvm/DATABASE

# Create directory if it doesn't exist
#mkdir -p "$FROM_DIR" || { echo "Failed to create directory $FROM_DIR"; exit 1; }

TODAY=$(date '+%Y-%m-%d')
LOGFILE="$FROM_DIR/LOG_BISECT_${TODAY}.out"

LOGFILE=$FROM_DIR/LOG_BISECT_${TODAY}.out

BISECT_ROOT=/git-bisect-llvm
SCRIPTS_DIRS=${BISECT_ROOT}/scripts

LLVM_SOLLVE_DIR=${BISECT_ROOT}/llvm-sollve

original_dir=$(pwd)
cd ${LLVM_SOLLVE_DIR}
# BUILD LLVM
${LLVM_SOLLVE_DIR}/nvidia-llvm.sh &>> $LOGFILE 
LLVM_BUILD_EXIT=$?
cd "$original_dir"

echo "********************************************************************* " &>> $LOGFILE
echo "**************** LLVM BUILD ERRORS = $LLVM_BUILD_EXIT *********************** " &>> $LOGFILE
echo "********************************************************************* " &>> $LOGFILE

if [[ $LLVM_BUILD_EXIT != 0 ]]
then
  LLVM_BUILD_EXIT=125
  cd $FROM_DIR
  exit $LLVM_BUILD_EXIT
fi

original_dir=$(pwd)
cd ${LLVM_SOLLVE_DIR}
#BUILD SOLLVE V&V
${LLVM_SOLLVE_DIR}/nvidia-sollve-vv.sh &>> $LOGFILE
cd "$original_dir"

# Grep for something in the application that is being tested
grep "Passed" $LOGFILE | grep -v None
SOLLVEVV_BUILD_EXIT=$?

grep "Passed" $LOGFILE | grep -v None
SOLLVEVV_EXE_EXIT=$?

if [[ $SOLLVEVV_BUILD_EXIT != 0 ]]
then
  echo "********************************************************************* " &>> $LOGFILE
  echo "**** ERROR BUILDING THE APP **************** " &>> $LOGFILE
  echo "********************************************************************* " &>> $LOGFILE
  cd $FROM_DIR
  exit $SOLLVEVV_BUILD_EXIT
fi

if [[ $SOLLVEVV_EXE_EXIT != 0 ]]
then
  echo "********************************************************************* " &>> $LOGFILE
  echo "**** ERROR EXECUTING THE APP **************** " &>> $LOGFILE
  echo "********************************************************************* " &>> $LOGFILE
  cd $FROM_DIR
  exit $SOLLVEVV_EXE_EXIT
fi

echo "********************************************************************* " &>> $LOGFILE
echo "**** APP SUCCESS **************** " &>> $LOGFILE
echo "********************************************************************* " &>> $LOGFILE


cd $FROM_DIR

exit 0
