(defpackage #:cl-onnx
  (:use #:cl)
  (:export #:onnx-error #:runtime-version #:open-session #:session #:release
           #:session-inputs #:session-outputs #:value-info #:value-info-name
           #:value-info-dtype #:value-info-shape #:tensor #:make-tensor
           #:tensor-shape #:tensor-dtype #:tensor-data #:run #:make-run-options
           #:terminate-run #:with-session #:with-run-options))
