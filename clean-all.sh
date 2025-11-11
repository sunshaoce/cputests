#!/bin/bash

set -e

rm -rf results/

cd TSVC_2
make clean && rm -rf ./bin/

echo "Cleaned all previous results."
