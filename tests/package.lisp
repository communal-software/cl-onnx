(defpackage #:cl-onnx/tests
  (:use #:cl #:fiveam)
  (:local-nicknames (#:ox #:cl-onnx) (#:bt #:bordeaux-threads-2))
  (:export #:run-tests))
(in-package #:cl-onnx/tests)
(def-suite :cl-onnx)
(defun run-tests () (run! :cl-onnx))
(defun fixture (name) (asdf:system-relative-pathname "cl-onnx" (concatenate 'string "tests/fixtures/" name)))
