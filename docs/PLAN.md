# Coverage

`cl-onnx` provides CPU graph execution through ONNX Runtime's C API. A small native bridge owns C API table access; Lisp owns resource wrappers and error translation.

| Component | Status |
|---|---|
| Private GitHub origin and sourcehut mirror; MIT license | Implemented |
| CPU sessions and input/output metadata | Implemented |
| F32, I32 and I64 tensors, scalar/empty shapes, storage slices | Implemented |
| Native execution and run termination | Implemented |
| Explicit resource ownership and offline fixtures | Implemented |
| SBCL on macOS ARM64, ONNX Runtime 1.31.0 | Verified |

## Limitations

Accelerator configuration, other element types, non-tensor model values and other Lisp/platform combinations are unverified or outside this binding's current interface. The inference integration's broader coverage is tracked in [cl-inference ONNX limitations](https://github.com/communal-software/cl-inference/issues/72).
