#!/bin/bash

set -e

PWD=$(pwd)

rm -rf results/

cd ${PWD}/TSVC_2
make clean && rm -rf ./bin/

cd ${PWD}/STREAM
make clean

cd ${PWD}/Dhrystone
make clean

echo "Cleaned all results."
