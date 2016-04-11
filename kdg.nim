import strutils

type
  KNodeType* = enum
    ntEvent, ntSemRole, ntClass, ntEntity
  KNode* = object
    name*: string
    typ*: KNodeType
  KDG* = ref object
    node*: KNode
    children*: seq[tuple[edgeType: string, to: KDG]]

proc newKDG*(root: KNode): KDG =
  new result
  newSeq(result.children, 0)
  result.node = root

proc nodeTypeFormat(nodeType: KNodeType): string =
  case nodeType
    of ntEvent: "E<$1>"
    of ntSemRole: "$1"
    of ntClass: "<$1>"
    of ntEntity: "$1"

proc `==`*(n1, n2: KNode): bool =
  (n1.name == n2.name) and (n1.typ == n2.typ)

proc addEdgeHelper(kgraph: var KDG, fr: KNode, edgeType: string, to: KDG): bool =
  let realNewEdge = (edgeType, to)
  if kgraph.node == fr:
    kgraph.children.add(realNewEdge)
    return true
  else:
    for child in kgraph.children:
      var cto = child.to
      if cto.addEdgeHelper(fr, edgeType, to): return true
    return false

proc addEdge*(kgraph: var KDG, fr: KNode, edgeType: string, to: KDG) =
  discard kgraph.addEdgeHelper(fr, edgeType, to)

proc addEdgeNode*(kgraph: var KDG, fr: KNode, edgeType: string, to: KNode) =
  kgraph.addEdge(fr, edgeType, newKDG(to))

proc traverse*(kgraph: KDG, cb: proc (subgraph: KDG, edgeFrom: string, depth: int), edgeFrom = "root", depth = 0) =
  if kgraph == nil: return
  cb(kgraph, edgeFrom, depth)
  for child in kgraph.children:
    traverse(child.to, cb, child.edgeType, depth + 1)

proc traverseWithPath*(kgraph: KDG, cb: proc (subgraph: KDG, path: seq[string], depth: int), path = @["root"], depth = 0) =
  if kgraph == nil: return
  cb(kgraph, path, depth)
  for child in kgraph.children:
    traverseWithPath(child.to, cb, path & child.edgeType, depth + 1)

proc subgraphFrom*(kgraph: KDG, subRoot: KNode): KDG =
  var subgraph: KDG = nil
  kgraph.traverse(proc (graph: KDG, edgeFrom: string, depth: int) =
    if graph.node == subRoot:
      subgraph = graph)

  return subgraph

proc `$`*(node: KNode): string =
  node.typ.nodeTypeFormat.format(node.name)

proc `$`*(kgraph: KDG): string =
  var res = ""
  kgraph.traverse(proc(subgraph: KDG, edgeFrom: string, depth: int) =
    res &= repeat("  ", depth) & edgeFrom & ": " & $subgraph.node & "\n")
  return res
