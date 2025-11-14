#!/bin/bash

set -e
STDBUF="stdbuf -oL -eL"
ROOT_DIR=$(pwd)

SKIP_ALL=${SKIP_ALL:=0}
ENABLE_TSVC=${ENABLE_TSVC:=0}
ENABLE_STREAM=${ENABLE_STREAM:=0}
ENABLE_DHRYSTONE=${ENABLE_DHRYSTONE:=0}
ENABLE_COREMARK=${ENABLE_COREMARK:=0}
ENABLE_LINPACK=${ENABLE_LINPACK:=0}
ENABLE_WHETSTONE=${ENABLE_WHETSTONE:=0}

if [ "$SKIP_ALL" -eq 0 ]; then
  ENABLE_TSVC=1
  ENABLE_STREAM=1
  ENABLE_DHRYSTONE=1
  ENABLE_COREMARK=1
fi

green() { echo -e "\033[1;32m$*\033[0m"; }
red() { echo -e "\033[1;31m$*\033[0m"; }
cc_type() {
  cc_path=$1
  cc_basename=$(basename "$cc_path")
  if [[ "$cc_basename" == *"clang"* ]]; then
    echo "clang"
  elif [[ "$cc_basename" == *"gcc"* ]] || [[ "$cc_basename" == *"g++"* ]] ; then
    echo "GNU"
  else
    red "unknown compiler type!!!"
    exit 1
  fi
}

CC1=${CC1:=gcc}
CC2=${CC2:=clang}
CC1FLAGS=${CC1FLAGS:=}
CC2FLAGS=${CC2FLAGS:=}

TIMESTAMP=$(date +"%Y_%m_%d-%H_%M_%S")
CC1TY=$(cc_type "$CC1")
CC1OUT=${ROOT_DIR}/results/${TIMESTAMP}/${CC1TY}
CC2TY=$(cc_type "$CC2")
CC2OUT=${ROOT_DIR}/results/${TIMESTAMP}/${CC2TY}
mkdir -p $CC1OUT $CC2OUT

echo -e "CC1: $CC1" | tee $CC1OUT/compiler.log
echo -e "CC1TY: $CC1TY" | tee -a $CC1OUT/compiler.log
echo -e "CC1FLAGS: $CC1FLAGS" | tee -a $CC1OUT/compiler.log
echo -e "CC1VERSION: \n$($CC1 --version)" | tee -a $CC1OUT/compiler.log
echo -e "CC2: $CC2" | tee $CC2OUT/compiler.log
echo -e "CC2TY: $CC2TY" | tee -a $CC2OUT/compiler.log
echo -e "CC2FLAGS: $CC2FLAGS" | tee -a $CC2OUT/compiler.log
echo -e "CC2VERSION: \n$($CC2 --version)" | tee -a $CC2OUT/compiler.log

if [ "$ENABLE_TSVC" -eq 1 ]; then
  green "Running TSVC tests..."
  cd ${ROOT_DIR}/TSVC_2
  make clean && rm -rf ./bin/
  make -j COMPILER="$CC1TY" CC="$CC1" TESTS="s111"
  make -j COMPILER="$CC2TY" CC="$CC2" TESTS="s111"

  green "Running TSVC tests with $CC1..."
  $STDBUF ./bin/${CC1TY}/tsvc_vec_default 2>&1 | tee $CC1OUT/tsvc_output.log
  green "Running TSVC tests with $CC2..."
  $STDBUF ./bin/${CC2TY}/tsvc_vec_default 2>&1 | tee $CC2OUT/tsvc_output.log
  make clean && rm -rf ./bin/
fi

if [ "$ENABLE_STREAM" -eq 1 ]; then
  green "Running STREAM tests..."
  cd ${ROOT_DIR}/STREAM
  green "Running STREAM tests with $CC1..."
  make clean
  make CC="$CC1" CFLAGS="$CC1FLAGS" -j
  $STDBUF ./stream_c.exe 2>&1 | tee $CC1OUT/stream_output.log
  green "Running STREAM tests with $CC2..."
  make clean
  make CC="$CC2" CFLAGS="$CC2FLAGS" -j
  $STDBUF ./stream_c.exe 2>&1 | tee $CC2OUT/stream_output.log
  make clean
fi

if [ "$ENABLE_DHRYSTONE" -eq 1 ]; then
  green "Running Dhrystone tests..."
  cd ${ROOT_DIR}/dhrystone
  green "Running dhrystone tests with $CC1..."
  make clean
  make CC="$CC1" -j
  $STDBUF echo 100000000 | ./dhrystone 2>&1 | tee $CC1OUT/dhrystone_output.log
  green "Running dhrystone tests with $CC2..."
  make clean
  make CC="$CC2" -j
  $STDBUF echo 100000000 | ./dhrystone 2>&1 | tee $CC2OUT/dhrystone_output.log
  make clean
fi

if [ "$ENABLE_COREMARK" -eq 1 ]; then
  green "Running CoreMark tests..."
  cd ${ROOT_DIR}/coremark
  green "Running CoreMark tests with $CC1..."
  make clean
  make CC="$CC1" -j
  mv ./run1.log ${CC1OUT}/coremark_output_run1.log
  mv ./run2.log ${CC1OUT}/coremark_output_run2.log
  green "Running CoreMark tests with $CC2..."
  make clean
  make CC="$CC2" -j
  mv ./run1.log ${CC2OUT}/coremark_output_run1.log
  mv ./run2.log ${CC2OUT}/coremark_output_run2.log
  make clean
fi

if [ "$ENABLE_LINPACK" -eq 1 ]; then
  green "Running Linpack tests..."
  cd ${ROOT_DIR}/linpackc
  green "Running Linpack tests with $CC1..."
  make clean
  make CC="$CC1" -j
  $STDBUF ./linpackc 2>&1 | tee $CC1OUT/linpack_output.log
  green "Running Linpack tests with $CC2..."
  make clean
  make CC="$CC2" -j
  $STDBUF ./linpackc 2>&1 | tee $CC2OUT/linpack_output.log
  make clean
fi

if [ "$ENABLE_WHETSTONE" -eq 1 ]; then
  green "Running Whetstone tests..."
  cd ${ROOT_DIR}/whetstone
  green "Running Whetstone tests with $CC1..."
  make clean
  make CC="$CC1" -j
  $STDBUF ./whetdc 300000 2>&1 | tee $CC1OUT/whetstone_output.log
  green "Running Whetstone tests with $CC2..."
  make clean
  make CC="$CC2" -j
  $STDBUF ./whetdc 300000 2>&1 | tee $CC2OUT/whetstone_output.log
  make clean
fi

green "$0 SUCCESS!"
