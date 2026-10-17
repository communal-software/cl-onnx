(asdf:defsystem "cl-onnx"
  :description "Common Lisp bindings to ONNX Runtime for model inference"
  :author "George Watson"
  :license "MIT"
  :version "0.0.1"
  :depends-on ("cffi" "uiop")
  :serial t
  :components ((:file "package") (:file "ffi") (:file "runtime"))
  :in-order-to ((asdf:test-op (asdf:test-op "cl-onnx/tests"))))

(asdf:defsystem "cl-onnx/tests"
  :depends-on ("cl-onnx" "fiveam" "bordeaux-threads")
  :serial t
  :components ((:file "tests/package") (:file "tests/runtime"))
  :perform (asdf:test-op (op component)
             (declare (ignore op component))
             (unless (uiop:symbol-call :cl-onnx/tests :run-tests)
               (error "cl-onnx tests failed"))))
