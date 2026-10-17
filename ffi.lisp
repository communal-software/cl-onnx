(in-package #:cl-onnx)

(define-condition onnx-error (error)
  ((message :initarg :message :reader error-message))
  (:report (lambda (condition stream) (write-string (error-message condition) stream))))

(cffi:load-foreign-library
 (or (uiop:getenv "CL_ONNX_LIBRARY")
     (namestring (asdf:system-relative-pathname
                  "cl-onnx" #+darwin ".native/bridge/libcl_onnx.dylib"
                            #-darwin ".native/bridge/libcl_onnx.so"))))

(cffi:defcfun ("con_error" %error) :string)
(cffi:defcfun ("con_init" %init) :int)
(cffi:defcfun ("con_version" runtime-version) :string)
(cffi:defcfun ("con_open" %open) :pointer (path :string) (threads :int))
(cffi:defcfun ("con_close" %close) :void (session :pointer))
(cffi:defcfun ("con_count" %count) :int (session :pointer) (output :int) (count :pointer))
(cffi:defcfun ("con_info" %info) :int (session :pointer) (output :int) (index :size)
  (name :pointer) (dtype :pointer) (rank :pointer) (dims :pointer) (capacity :size))
(cffi:defcfun ("con_free_name" %free-name) :void (name :pointer))
(cffi:defcfun ("con_tensor" %tensor) :pointer (dtype :int) (dims :pointer) (rank :size))
(cffi:defcfun ("con_data" %data) :int (tensor :pointer) (data :pointer))
(cffi:defcfun ("con_shape" %shape) :int (tensor :pointer) (dtype :pointer) (rank :pointer)
  (dims :pointer) (capacity :size))
(cffi:defcfun ("con_release" %release) :void (tensor :pointer))
(cffi:defcfun ("con_options" %options) :pointer)
(cffi:defcfun ("con_release_options" %release-options) :void (options :pointer))
(cffi:defcfun ("con_terminate" %terminate) :int (options :pointer))
(cffi:defcfun ("con_run" %run) :int (session :pointer) (options :pointer)
  (names :pointer) (values :pointer) (count :size) (out-names :pointer)
  (out-count :size) (outputs :pointer))

(defun check-status (status)
  (unless (zerop status) (error 'onnx-error :message (%error))))

(defun check-pointer (pointer)
  (when (cffi:null-pointer-p pointer) (error 'onnx-error :message (%error)))
  pointer)

(check-status (%init))
