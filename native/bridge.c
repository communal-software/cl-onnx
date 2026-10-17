#include <onnxruntime_c_api.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static const OrtApi *api;
static _Thread_local char error_text[2048];
typedef struct { OrtEnv *env; OrtSession *session; } Session;

static int check(OrtStatus *status) {
    if (!status) return 0;
    snprintf(error_text, sizeof(error_text), "%s", api->GetErrorMessage(status));
    api->ReleaseStatus(status);
    return -1;
}
const char *con_error(void) { return error_text; }
int con_init(void) {
    api = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    if (!api) { snprintf(error_text, sizeof(error_text), "Incompatible ONNX Runtime C API"); return -1; }
    return 0;
}
const char *con_version(void) { return OrtGetApiBase()->GetVersionString(); }
void con_close(Session *s) {
    if (!s) return;
    if (s->session) api->ReleaseSession(s->session);
    if (s->env) api->ReleaseEnv(s->env);
    free(s);
}
Session *con_open(const char *path, int threads) {
    Session *s = calloc(1, sizeof(Session));
    OrtSessionOptions *options = NULL;
    if (!s) { snprintf(error_text, sizeof(error_text), "Session allocation failed"); return NULL; }
    if (check(api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "cl-onnx", &s->env))) goto fail;
    if (check(api->CreateSessionOptions(&options))) goto fail;
    if (check(api->SetIntraOpNumThreads(options, threads))) goto fail;
    if (check(api->CreateSession(s->env, path, options, &s->session))) goto fail;
    api->ReleaseSessionOptions(options);
    return s;
fail:
    if (options) api->ReleaseSessionOptions(options);
    con_close(s);
    return NULL;
}
int con_count(Session *s, int output, size_t *count) {
    return check(output ? api->SessionGetOutputCount(s->session, count) : api->SessionGetInputCount(s->session, count));
}
int con_info(Session *s, int output, size_t index, char **name, int *dtype, size_t *rank, int64_t *dims, size_t capacity) {
    OrtAllocator *allocator = NULL;
    OrtTypeInfo *info = NULL;
    const OrtTensorTypeAndShapeInfo *tensor = NULL;
    ONNXTensorElementDataType type;
    int result = -1;
    *name = NULL;
    if (check(api->GetAllocatorWithDefaultOptions(&allocator))) return -1;
    if (check(output ? api->SessionGetOutputTypeInfo(s->session,index,&info) : api->SessionGetInputTypeInfo(s->session,index,&info))) goto done;
    if (check(api->CastTypeInfoToTensorInfo(info,&tensor))) goto done;
    if (!tensor) { snprintf(error_text,sizeof(error_text),"Only tensor inputs/outputs are supported"); goto done; }
    if (check(api->GetTensorElementType(tensor,&type))) goto done;
    *dtype = (int)type;
    if (check(api->GetDimensionsCount(tensor,rank))) goto done;
    if (*rank > capacity) { snprintf(error_text,sizeof(error_text),"Tensor rank exceeds metadata capacity"); goto done; }
    if (check(api->GetDimensions(tensor,dims,*rank))) goto done;
    if (check(output ? api->SessionGetOutputName(s->session,index,allocator,name) : api->SessionGetInputName(s->session,index,allocator,name))) goto done;
    result = 0;
done:
    if (info) api->ReleaseTypeInfo(info);
    return result;
}
void con_free_name(char *name) {
    OrtAllocator *allocator = NULL;
    if (!check(api->GetAllocatorWithDefaultOptions(&allocator))) allocator->Free(allocator,name);
}
OrtValue *con_tensor(int type, const int64_t *dims, size_t rank) {
    OrtAllocator *allocator = NULL;
    OrtValue *value = NULL;
    if (check(api->GetAllocatorWithDefaultOptions(&allocator))) return NULL;
    if (check(api->CreateTensorAsOrtValue(allocator,dims,rank,(ONNXTensorElementDataType)type,&value))) return NULL;
    return value;
}
int con_data(OrtValue *value, void **data) { return check(api->GetTensorMutableData(value,data)); }
int con_shape(OrtValue *value, int *dtype, size_t *rank, int64_t *dims, size_t capacity) {
    OrtTensorTypeAndShapeInfo *info = NULL;
    ONNXTensorElementDataType type;
    int result = -1;
    if (check(api->GetTensorTypeAndShape(value,&info))) return -1;
    if (check(api->GetTensorElementType(info,&type))) goto done;
    *dtype = (int)type;
    if (check(api->GetDimensionsCount(info,rank))) goto done;
    if (*rank > capacity) { snprintf(error_text,sizeof(error_text),"Tensor rank exceeds metadata capacity"); goto done; }
    if (check(api->GetDimensions(info,dims,*rank))) goto done;
    result = 0;
done:
    api->ReleaseTensorTypeAndShapeInfo(info);
    return result;
}
void con_release(OrtValue *value) { if (value) api->ReleaseValue(value); }
OrtRunOptions *con_options(void) {
    OrtRunOptions *options = NULL;
    return check(api->CreateRunOptions(&options)) ? NULL : options;
}
int con_terminate(OrtRunOptions *options) { return check(api->RunOptionsSetTerminate(options)); }
void con_release_options(OrtRunOptions *options) { if (options) api->ReleaseRunOptions(options); }
int con_run(Session *s, OrtRunOptions *options, const char *const *names, const OrtValue *const *values,
            size_t count, const char *const *out_names, size_t out_count, OrtValue **outputs) {
    return check(api->Run(s->session,options,names,values,count,out_names,out_count,outputs));
}
