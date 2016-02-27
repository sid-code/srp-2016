import sequtils
import kdg

# inverse edge types.
# for example, inverse of "agent" is "performed_action"
const
  inverseEdgeTypes =
    {"agent":          "performed_action",
     "objective":      "required_for",
     "next_event":     "previous_event",
     "instance_of":    "has_instance",
     "is_subclass_of": "has_subclass",
     "modifier":       "modifies"}

proc invertEdge(edge: string): string =
  for pair in inverseEdgeTypes:
    let (k, v) = pair
    if edge == k: return v
    if edge == v: return k

  if edge[0] == '!':
    return edge[1..^1]
  else:
    return "!" & edge

# A simple transformation. This takes any node in the tree and makes it the
# root node of the tree.

proc hoistNodeSingleDepth(kgraph: KDG, node: KNode, newEdge: string = nil):
                          tuple[success: bool, kgraph: KDG] =
  var childToHoist: KDG = nil
  var edge = newEdge
  result.success = false

  if kgraph.node == node:
    result.success = true
    result.kgraph = kgraph
    return

  for child in kgraph.children:
    let childGraph = child.to
    if childGraph.node == node:
      result.success = true
      childToHoist = childGraph
      if isNil(edge):
        edge = invertEdge(child.edgeType)

  if result.success:
    kgraph.children.keepItIf(it.to.node != node)

    childToHoist.children.add((edge, kgraph))
    result.kgraph = childToHoist

proc findPathTo(kgraph: KDG, node: KNode): tuple[found: bool, path: seq[KNode]] =
  result.found = false
  let current = kgraph.node
  result.path = @[current]
  if kgraph.node == node:
    result.found = true
    return

  for child in kgraph.children:
    let (childEdge, childGraph) = child
    let (childHasPath, path) = childGraph.findPathTo(node)
    if childHasPath:
      result.found = true
      result.path.add(path)
      return

proc hoistNode*(kgraph: KDG, node: KNode): tuple[success: bool, kgraph: KDG] =
  let (found, path) = kgraph.findPathTo(node)
  if not found:
    return (false, nil)

  var currentGraph = kgraph
  for step in path:
    let (success, newGraph) = currentGraph.hoistNodeSingleDepth(step)
    if success:
      currentGraph = newGraph
    else:
      return (false, nil)

  return (true, currentGraph)

proc hoistAgent*(kgraph: KDG): tuple[success: bool, kgraph: KDG] =
  for child in kgraph.children:
    if child.edgeType == "agent":
      return kgraph.hoistNode(child.to.node)

  return (false, kgraph)
