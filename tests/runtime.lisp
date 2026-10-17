(in-package #:cl-onnx/tests)
(in-suite :cl-onnx)

(test native-metadata-tensors-and-execution
  (ox:with-session (session (fixture "add.onnx"))
    (is (string= "1.31.0" (ox:runtime-version)))
    (let ((info (first (ox:session-inputs session))))
      (is (equal "x" (ox:value-info-name info)))
      (is (eq :f32 (ox:value-info-dtype info)))
      (is (equal '(2) (ox:value-info-shape info))))
    (let ((input (ox:make-tensor #(2 4) '(2))) (outputs nil))
      (unwind-protect
           (progn
             (setf outputs (ox:run session (list (cons "x" input))))
             (is (equalp #(3f0 5f0) (ox:tensor-data (cdar outputs))))
             (is (equal '(2) (ox:tensor-shape (cdar outputs))))
             (is (eq :f32 (ox:tensor-dtype (cdar outputs)))))
        (mapc (lambda (pair) (ox:release (cdr pair))) outputs)
        (ox:release input)
        (ox:release input)))))

(test tensor-types-empty-shapes-and-validation
  (dolist (dtype '(:f32 :i32 :i64))
    (let ((scalar (ox:make-tensor #(3) nil :dtype dtype))
          (empty (ox:make-tensor nil '(1 0 4) :dtype dtype)))
      (unwind-protect
           (progn (is (= 3 (aref (ox:tensor-data scalar) 0)))
                  (is (null (ox:tensor-shape scalar)))
                  (is (zerop (length (ox:tensor-data empty)))))
        (ox:release scalar) (ox:release empty))))
  (signals ox:onnx-error (ox:make-tensor #(1) '(2)))
  (signals ox:onnx-error (ox:make-tensor nil '(-1))))

(test errors-and-closed-resources
  (signals ox:onnx-error (ox:open-session (fixture "missing.onnx")))
  (let ((session (ox:open-session (fixture "add.onnx"))))
    (signals ox:onnx-error (ox:run session nil))
    (let ((wrong (ox:make-tensor #(1 2) '(2) :dtype :i64)))
      (unwind-protect (signals ox:onnx-error (ox:run session (list (cons "x" wrong))))
        (ox:release wrong)))
    (ox:release session) (ox:release session)
    (signals ox:onnx-error (ox:run session nil)))
  (let ((tensor (ox:make-tensor #(1) '(1))))
    (ox:release tensor)
    (signals ox:onnx-error (ox:tensor-data tensor))))

(test native-run-termination-and-session-recovery
  (ox:with-session (session (fixture "loop.onnx"))
    (ox:with-run-options (options)
      (let ((input (ox:make-tensor #(1000000000) nil :dtype :i64))
            (started (bt:make-semaphore)) (failure nil))
        (unwind-protect
             (let ((thread (bt:make-thread
                            (lambda ()
                              (bt:signal-semaphore started)
                              (handler-case
                                  (let ((outputs (ox:run session (list (cons "iterations" input)) :options options)))
                                    (mapc (lambda (pair) (ox:release (cdr pair))) outputs))
                                (ox:onnx-error (e) (setf failure e)))))))
               (bt:wait-on-semaphore started)
               (sleep 0.03)
               (ox:terminate-run options)
               (bt:join-thread thread)
               (is (typep failure 'ox:onnx-error)))
          (ox:release input))))
    (let ((input (ox:make-tensor #(3) nil :dtype :i64)) (outputs nil))
      (unwind-protect
           (progn (setf outputs (ox:run session (list (cons "iterations" input))))
                  (is (= 3 (aref (ox:tensor-data (cdar outputs)) 0))))
        (mapc (lambda (pair) (ox:release (cdr pair))) outputs)
        (ox:release input)))))

(test tensor-data-slices
  (let ((tensor (ox:make-tensor #(1 2 3 4) '(2 2))))
    (unwind-protect
         (progn (is (equalp #(3f0 4f0) (ox:tensor-data tensor :start 2)))
                (is (equalp #() (ox:tensor-data tensor :start 4)))
                (signals ox:onnx-error (ox:tensor-data tensor :end 5))
                (signals ox:onnx-error (ox:tensor-data tensor :start -1)))
      (ox:release tensor))))
