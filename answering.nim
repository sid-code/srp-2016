import kdg, kdgtools, kclient, asyncdispatch, os, strutils, tables

proc getPartOf(kgraph: KDG): KDG =
  let partOf = kgraph["is_inside_location", "is_possessed_by", "is_part_of", "is_goal_of", "type_of"]
  if partOf == blankGraph:
    return kgraph
  else:
    return partOf

proc extractObject*(kgraph: KDG): KDG =
  let objective = kgraph["objective"]
  if objective != blankGraph:
    return extractObject(objective)

  if kgraph["instance_of"] @= "be":
    let recip = kgraph["recipient"]
    if recip == blankGraph:
      let agent = kgraph["agent"]
      return agent
    else:
      return getPartOf(recip)
  else:
    let inside = kgraph["is_inside_location", "prep_during"]
    if inside != blankGraph:
      return inside

    let recip = kgraph["recipient"]
    if recip != blankGraph:
      return getPartOf(recip)

    let agent = kgraph["agent"]
    if agent != blankGraph:
      return agent

  return blankGraph

proc extractAllObjects*(kgraph: KDG): Table[seq[string], seq[string]] =
  var res = initTable[seq[string], seq[string]]()
  kgraph.traverseWithPath(proc (subgraph: KDG, path: seq[string], depth: int) =
    if subgraph.node.typ != ntEntity: return
    let information = getEntityInformation(subgraph)
    if information.len > 0:
      res[path] = information)
  return res


when isMainModule:
  let kgraphs = kparse("How old do you have to be to play Monopoly?")
  echo extractAllObjects(kgraphs[0])
