## This module extracts the "essence" of a graph, or a list of
## characteristics that describe its structure. These are paired
## with paths to main entities to train a model.
##
## Here are some things that go into the "essence" of a graph:
##  verb type: is it a "to be" verb or not?
##  agent: simple or complex or question agent?
##  recipient: simple or complex or question recipient?

import kdg

const
  OfEdges = [
    "is_possessed_by", "has_part", "is_part_of", "is_goal_of",
    "type_of", "is_inside_location"
  ]

  
type
  ObjEssence = object
    name: string
    blank: bool
    isQuestion: bool
    hasOf: bool
    hasModifier: bool
    hasComplement: bool
    # hasWith*: bool
  Essence* = object
    toBe*: bool
    eventEntityRelations*: seq[ObjEssence]

proc `$`(oe: ObjEssence): string =
  result = ""
  if oe.blank: return
  result.add(oe.name)
  if oe.isQuestion: result.add("?")
  if oe.hasOf: result.add("o")
  if oe.hasModifier: result.add("m")
  if oe.hasComplement: result.add("c")

proc `$`*(ess: Essence): string =
  result = ""
  if ess.toBe:
    result.add("+")
  else:
    result.add("-")

  for oe in ess.eventEntityRelations:
    result.add($oe)
    result.add(",")

proc distTo*(essFrom, essTo: Essence): int =
  if essFrom.toBe != essTo.toBe: return -1
  for relation in essFrom.eventEntityRelations:
    if relation notin essTo.eventEntityRelations:
      return -1
  return essTo.eventEntityRelations.len - essFrom.eventEntityRelations.len

proc getObjEssence(kgraph: KDG, name: string): ObjEssence =
  result.name = name
  if kgraph == blankGraph:
    result.blank = true
  else:
    result.blank = false
    if kgraph["instance_of"] @= "?":
      result.isQuestion = true
    if kgraph["complement_word"] != blankGraph:
      result.hasComplement = true
    if kgraph[OfEdges] != blankGraph:
      result.hasOf = true

proc getEssence*(kgraph: KDG): Essence =
  result.toBe = kgraph["instance_of"] @= "be"
  newSeq(result.eventEntityRelations, 0)
  result.eventEntityRelations.add(getObjEssence(kgraph, "^"))

  result.eventEntityRelations.add(getObjEssence(kgraph["agent"], "a"))
  result.eventEntityRelations.add(getObjEssence(kgraph["recipient"], "r"))
  result.eventEntityRelations.add(getObjEssence(kgraph["modifier"], "m"))
  result.eventEntityRelations.add(getObjEssence(kgraph["dependent"], "d"))
  result.eventEntityRelations.add(getObjEssence(kgraph["target"], "t"))

when isMainModule:
  import kclient
  let kgraphs = kparse("how many schools are in the school district of philadelphia?")
  kgraphs.map(proc(x: seq[KDG]) = echo x[0].getEssence())

