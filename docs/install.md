# Installation

Build the C bridge, register the Lisp project, then load `cl-onnx`. Python is unnecessary for loading or running a model.

## macOS ARM64

Install a C compiler and CMake, then:

```sh
./build-native.sh
ln -s ~/git/cl-onnx ~/quicklisp/local-projects/cl-onnx
```

The build script downloads the pinned ONNX Runtime 1.31.0 CPU archive, verifies its SHA256, and builds against its official header. Native files stay in `.native/`. Keep that directory with the project; the bridge links to the runtime distribution there.[^upstream]

```lisp
(asdf:load-system "cl-onnx")
(cl-onnx:runtime-version) ; => "1.31.0"
```

## Custom installation

Set `ONNXRUNTIME_ROOT` to a 1.31.0 distribution containing `include/` and `lib/`, then run the build script. Set `CL_ONNX_LIBRARY` to override the bridge library's absolute path at Lisp load time. The bridge checks C API compatibility when loaded; a missing library produces a loader error.

## Tests

`asdf:test-system "cl-onnx"` executes committed tiny ONNX graphs offline, including termination of an active native loop and subsequent reuse of the session. No model downloads are needed after the runtime is installed.

Regenerate fixtures with development-only Python:

```sh
uv run --with onnx==1.20.1 python tools/fixtures.py
```

[^upstream]: [ONNX Runtime C installation and API](https://onnxruntime.ai/docs/get-started/with-c.html). ONNX Runtime remains separately licensed; retain the notices shipped in its distribution.
