#!/bin/bash

FROM_DIR=/home/users/jarmusch/llvm-commit-debug-felipe/DATABASE

LOGFILE=$FROM_DIR/LOG_BISECT_SPECHPC_${SPECHPC_BENCH}_${TODAY}.out

BISECT_ROOT=/home/users/jarmusch/llvm-commit-debug-felipe
SCRIPTS_DIRS=${BISECT_ROOT}/bisect_scripts

# BUILD LLVM
${SCRIPTS_DIRS}/build_llvm.sh &>> $LOGFILE 
LLVM_BUILD_EXIT=$?

echo "********************************************************************* " &>> $LOGFILE
echo "**************** LLVM BUILD ERRORS = $LLVM_BUILD_EXIT *********************** " &>> $LOGFILE
echo "********************************************************************* " &>> $LOGFILE

if [[ $LLVM_BUILD_EXIT != 0 ]]
then
  LLVM_BUILD_EXIT=125
  cd $FROM_DIR
  exit $LLVM_BUILD_EXIT
fi

#BUILD SPECHPC
${SCRIPTS_DIRS}/buildrun_app.sh &>> $LOGFILE

# Grep for something in the application that is being tested
grep "Build successes" $LOGFILE | grep -v None
SPECHPC_BUILD_EXIT=$?

grep Success $LOGFILE
SPECHPC_EXE_EXIT=$?

if [[ $SPECHPC_BUILD_EXIT != 0 ]]
then
  echo "********************************************************************* " &>> $LOGFILE
  echo "**** ERROR BUILDING THE APP **************** " &>> $LOGFILE
  echo "********************************************************************* " &>> $LOGFILE
  cd $FROM_DIR
  exit $SPECHPC_BUILD_EXIT
fi

if [[ $SPECHPC_EXE_EXIT != 0 ]]
then
  echo "********************************************************************* " &>> $LOGFILE
  echo "**** ERROR EXECUTING THE APP **************** " &>> $LOGFILE
  echo "********************************************************************* " &>> $LOGFILE
  cd $FROM_DIR
  exit $SPECHPC_EXE_EXIT
fi

echo "********************************************************************* " &>> $LOGFILE
echo "**** APP SUCCESS **************** " &>> $LOGFILE
echo "********************************************************************* " &>> $LOGFILE


cd $FROM_DIR

exit 0
