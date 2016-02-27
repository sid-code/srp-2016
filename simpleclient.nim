import os, asyncdispatch
import kdg, kclient, kdgtools

let params = commandLineParams()
if params.len < 1:
  echo "usage: simpleclient \"Who killed Abraham Lincoln?\""
else:
  let sentence = params[0]
  let kdgs = waitFor kparse(sentence)
  echo "Here is the agent-hoisted KDG for \"" & sentence & "\""
  for kg in kdgs: echo kg.hoistAgent().kgraph
