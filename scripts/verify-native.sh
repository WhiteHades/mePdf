#!/usr/bin/env sh

set -eu

cmake -S . -B .tmp/native-build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build .tmp/native-build
ctest --test-dir .tmp/native-build --output-on-failure
