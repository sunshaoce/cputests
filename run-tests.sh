#!/bin/bash

set -e
STDBUF="stdbuf -oL -eL"

ENABLE_ALL=${ENABLE_ALL:=1}
ENABLE_TSVC=${ENABLE_TSVC:=1}
ENABLE_STREAM=${ENABLE_STREAM:=1}
ENABLE_DHRYSTONE=${ENABLE_DHRYSTONE:=1}

CC1=${CC1:=gcc}
CC2=${CC2:=clang}
CC1FLAGS=${CC1FLAGS:=}
CC2FLAGS=${CC2FLAGS:=}

cc_type() {
  cc_path=$1
  cc_basename=$(basename "$cc_path")
  if [[ "$cc_basename" == *"clang"* ]]; then
    echo "clang"
  elif [[ "$cc_basename" == *"gcc"* ]] || [[ "$cc_basename" == *"g++"* ]] ; then
    echo "GNU"
  else
    echo "unknown"
    exit 1
  fi
}

TIMESTAMP=$(date +"%Y_%m_%d-%H_%M_%S")
CC1TY=$(cc_type "$CC1")
CC1OUT=results/${TIMESTAMP}/${CC1TY}
CC2TY=$(cc_type "$CC2")
CC2OUT=results/${TIMESTAMP}/${CC2TY}
mkdir -p $CC1OUT $CC2OUT

echo -e "CC1:        $CC1" | tee ./$CC1OUT/compiler.log
echo -e "CC1TY:      $CC1TY" | tee -a ./$CC1OUT/compiler.log
echo -e "CC1FLAGS:   $CC1FLAGS" | tee -a ./$CC1OUT/compiler.log
echo -e "CC1VERSION: \n$($CC1 --version)" | tee -a ./$CC1OUT/compiler.log
echo -e "CC2:        $CC2" | tee ./$CC2OUT/compiler.log
echo -e "CC2TY:      $CC2TY" | tee -a ./$CC2OUT/compiler.log
echo -e "CC2FLAGS:   $CC2FLAGS" | tee -a ./$CC2OUT/compiler.log
echo -e "CC2VERSION: \n$($CC2 --version)" | tee -a ./$CC2OUT/compiler.log

if [ "$ENABLE_TSVC" -eq 1 ]; then
  echo "Running TSVC tests..."
  cd TSVC_2
  make clean && rm -rf ./bin/
  make -j COMPILER="$CC1TY" CC="$CC1" TESTS="s111"
  make -j COMPILER="$CC2TY" CC="$CC2" TESTS="s111"

  echo "Running tests with $CC1..."
  $STDBUF ./bin/${CC1TY}/tsvc_vec_default 2>&1 | tee ../$CC1OUT/tsvc_output.log
  echo "Running tests with $CC2..."
  $STDBUF ./bin/${CC2TY}/tsvc_vec_default 2>&1 | tee ../$CC2OUT/tsvc_output.log
  make clean && rm -rf ./bin/
fi

if [ "$ENABLE_STREAM" -eq 1 ]; then
  echo "Running STREAM tests..."
  cd ../STREAM
  make clean
  make CC="$CC1" CFLAGS="$CC1FLAGS" -j
  $STDBUF ./stream_c.exe 2>&1 | tee ../$CC1OUT/stream_output.log
  make clean
  make CC="$CC2" CFLAGS="$CC2FLAGS" -j
  $STDBUF ./stream_c.exe 2>&1 | tee ../$CC2OUT/stream_output.log
  make clean
fi

if [ "$ENABLE_DHRYSTONE" -eq 1 ]; then
  echo "Running Dhrystone tests..."
  cd ../dhrystone
  make clean
  make CC="$CC1" -j
  $STDBUF echo 100000000 | ./dhrystone 2>&1 | tee ../$CC1OUT/dhrystone_output.log
  make clean
  make CC="$CC2" -j
  $STDBUF echo 100000000 | ./dhrystone 2>&1 | tee ../$CC2OUT/dhrystone_output.log
  make clean
fi

echo "SUCCESS!"
