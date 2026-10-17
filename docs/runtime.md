# Runtime and ownership

A session executes an ONNX graph. Tensors own native storage; release each resource explicitly after its last use.

```lisp
(cl-onnx:with-session (session "tests/fixtures/add.onnx")
  (let ((input (cl-onnx:make-tensor #(2 4) '(2))) (outputs nil))
    (unwind-protect
         (progn
           (setf outputs (cl-onnx:run session (list (cons "x" input))))
           (cl-onnx:tensor-data (cdar outputs))) ; => #(3.0 5.0)
      (mapc (lambda (pair) (cl-onnx:release (cdr pair))) outputs)
      (cl-onnx:release input))))
```

## Interfaces

| Operation | Result |
|---|---|
| `open-session path :threads 1` | Owned CPU session; runtime resolves graph external data |
| `session-inputs`, `session-outputs` | Lists of `value-info` records: name, dtype, shape; `-1` denotes dynamic dimensions |
| `make-tensor data shape :dtype :f32` | Owned tensor; supported types are `:f32`, `:i32`, `:i64`; NIL data zero-fills |
| `tensor-data tensor :start 0 :end nil` | Copied flat vector, optionally a storage slice |
| `tensor-shape`, `tensor-dtype` | Tensor metadata |
| `run session inputs :options nil` | Alist of output names and owned tensors; inputs are borrowed |
| `make-run-options`, `terminate-run` | Per-call termination handle and cross-thread stop signal |
| `release` | Idempotent cleanup; accepts NIL |

Scalars have shape NIL; zero-length dimensions are supported. Data length must match the shape. Input names must match session inputs exactly. Unsupported element types and native failures signal `onnx-error`.

## Lifetime and threading

Keep the session, all input tensors and run options alive until `run` returns. Outputs have independent ownership and remain valid until released. Closed resources reject further native access. Metadata is copied into Lisp values.

`terminate-run` may be called from another thread while `run` executes. Wait for `run` to return before releasing its resources, including the termination handle. Use new run options after termination. Callers synchronize release against access; finalizers do not replace explicit cleanup.
