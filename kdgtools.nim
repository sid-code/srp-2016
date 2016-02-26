import sequtils
import kdg

# A simple transformation. This takes any node in the tree and makes it the
# root node of the tree.

proc hoistNode*(kgraph: KDG, node: KNode, newEdge: string): KDG =
  var searchQueue: seq[tuple[parent: KDG, child: KDG]] = @[(kgraph, kgraph)]
  while searchQueue.len > 0:
    let (curParent, curChild) = searchQueue.pop()
    if curChild.node == node:
      curParent.children.keepItIf(it.to.node != node)
      curChild.children.add((newEdge, kgraph))
      return curChild

    for child in curChild.children:
      searchQueue.add((curChild, child.to))

proc hoistAgent*(kgraph: KDG): KDG =
  for child in kgraph.children:
    if child.edgeType == "agent":
      return kgraph.hoistNode(child.to.node, "performed_action")

  return kgraph
