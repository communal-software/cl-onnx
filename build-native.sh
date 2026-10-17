#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p .native
if [ -n "${ONNXRUNTIME_ROOT:-}" ]; then
  root=$ONNXRUNTIME_ROOT
else
  if [ "$(uname -s)-$(uname -m)" != Darwin-arm64 ]; then
    echo 'Set ONNXRUNTIME_ROOT to an ONNX Runtime 1.31.0 CPU distribution for this platform.' >&2
    exit 1
  fi
  root="$PWD/.native/onnxruntime-osx-arm64-1.31.0"
  if [ ! -d "$root" ]; then
    curl -fL --retry 2 https://github.com/microsoft/onnxruntime/releases/download/v1.31.0/onnxruntime-osx-arm64-1.31.0.tgz -o .native/runtime.tgz
    echo '1031b36dd3bdaa8d976a6130d9cf2a05e9be320b93ae804f8427b91dc3432afc  .native/runtime.tgz' | shasum -a 256 -c -
    tar -xzf .native/runtime.tgz -C .native
  fi
fi
cmake -S native -B .native/bridge -DONNXRUNTIME_ROOT="$root" -DCMAKE_BUILD_TYPE=Release
cmake --build .native/bridge
