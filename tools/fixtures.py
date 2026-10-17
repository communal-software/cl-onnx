"""Regenerate offline test graphs: uv run --with onnx==1.20.1 python tools/fixtures.py."""
from pathlib import Path
import onnx
from onnx import helper as h, TensorProto as T
root=Path(__file__).resolve().parents[1]/'tests/fixtures'
def save(name,nodes,inputs,outputs,initializers=()):
 m=h.make_model(h.make_graph(nodes,name,inputs,outputs,list(initializers)),opset_imports=[h.make_opsetid('',14)],ir_version=7)
 onnx.checker.check_model(m);onnx.save(m,root/name)
info=h.make_tensor_value_info
save('add.onnx',[h.make_node('Add',['x','one'],['y'])],[info('x',T.FLOAT,[2])],[info('y',T.FLOAT,[2])],
 [h.make_tensor('one',T.FLOAT,[2],[1,1])])
body=h.make_graph([h.make_node('Identity',['condition'],['continue']),h.make_node('Add',['state','one'],['next'])],
 'count',[info('iteration',T.INT64,[]),info('condition',T.BOOL,[]),info('state',T.INT64,[])],
 [info('continue',T.BOOL,[]),info('next',T.INT64,[])],[h.make_tensor('one',T.INT64,[],[1])])
save('loop.onnx',[h.make_node('Loop',['iterations','yes','zero'],['total'],body=body)],
 [info('iterations',T.INT64,[])],[info('total',T.INT64,[])],
 [h.make_tensor('yes',T.BOOL,[],[True]),h.make_tensor('zero',T.INT64,[],[0])])
