import os, asyncdispatch
import kdg, kclient, kdgtools

let params = commandLineParams()
let appFilename = paramStr(0)
if params.len < 1:
  echo "use it like this: " & appFileName & " \"Who killed Abraham Lincoln?\""
else:
  let sentence = params[0]
  let kdgs = waitFor kparse(sentence)
  echo "Here is the agent-hoisted KDG for \"" & sentence & "\""
  for kg in kdgs: echo kg.hoistAgent()
