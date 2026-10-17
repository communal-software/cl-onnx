# cl-onnx

Common Lisp bindings to ONNX Runtime for model inference.

[Installation](docs/install.md) · [Runtime and ownership](docs/runtime.md) · [Coverage](docs/PLAN.md)

```sh
./build-native.sh
sbcl --non-interactive --eval '(require :asdf)' --eval '(asdf:test-system "cl-onnx")'
```

The CPU bindings and offline fixtures are verified on SBCL/macOS ARM64 with ONNX Runtime 1.31.0. [MIT](LICENSE).
