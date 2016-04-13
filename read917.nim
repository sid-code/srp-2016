import json
import tables
import httpclient
import sexp
import strutils
import sequtils

import kdg
import kclient
import answering
import essence
import essencePathModel

import dandelion/dandelion
import freebase/fbapi

const
  file = "./train917.json"
  contents = staticRead(file)

  green = "\e[0;32m"
  red = "\e[0;31m"
  bgreen = "\e[1;32m"
  bred = "\e[1;31m"
  reset = "\e[0m"

let parsed = parseJson(contents)

proc simpleComponents(sexp: SexpNode): tuple[s: bool, lhs: string, rhs: string] =
  result.s = false
  assert sexp.kind == SList
  let elems = sexp.getElems()

  if elems.len != 2: return

  let lhs = elems[0]
  let rhs = elems[1]

  if lhs.kind == SSymbol:
    let lhsv = lhs.getSymbol()
    if lhsv == "count":
      return simpleComponents(rhs)

    if rhs.kind == SSymbol:
      result.s = true
      result.lhs = lhsv
      result.rhs = rhs.getSymbol()


var total = parsed.len
var totalNotBroken = 0
var totalSimple = 0
var totalFound = 0
var totalNotFound = 0

var model = initEPModel()

for node in parsed.items():

  var utterance = node["utterance"].str & "?"
  fixEntities(utterance, maxDistance=0)
  let targetFormula = node["targetFormula"].str

  let kgraphsOption = kparse(utterance)
  if not kgraphsOption.isSome():
    when defined(showPaths): echo red, utterance, ": SKIPPING, parse failed", reset
    continue

  let kgraphs = kgraphsOption.get

  if kgraphs.len != 1 or kgraphs[0] == blankGraph:
    when defined(showPaths): echo red, utterance, ": SKIPPING, broken parse", reset
    continue

  inc totalNotBroken

  let kgraph = kgraphs[0]
  let essence = getEssence(kgraph)

  let sexp = parseSexp(targetFormula)
  let (simple, lhs, rhs) = simpleComponents(sexp)
  if not simple:
    when defined(showPaths): echo red, utterance, ": SKIPPING, not simple", reset
    continue

  inc totalSimple

  var found = false
  let objs = extractAllObjects(kgraph)
  var searches = "" # debug variable, displayed if no match is found
  for path, desc in objs.pairs:
    let matchedEntitiesO = fbapi.search(desc.join(" ")).map(
      proc (x: seq[string]): seq[string] = x.map(normalizeEntityName))

    if matchedEntitiesO.isSome:
      let matchedEntities = matchedEntitiesO.get
      searches.add(desc.join(" "))
      searches.add("->")
      searches.add($matchedEntities)
      searches.add("\n")
      if rhs in matchedEntities:
        found = true
        let pathStr = path.join(" -> ")
        when defined(showPaths): echo essence, bgreen, utterance, ": ", pathStr, reset
        model.addPair(essence, path)

  if found:
    inc totalFound

  else:
    when defined(showPaths): echo bred, utterance, ": NOT FOUND", reset
    when defined(showPaths): echo searches
    inc totalNotFound

echo "Total:                ", total
echo "Total not broken:     ", totalNotBroken
echo "Total simple:         ", totalSimple
echo "Total found:          ", totalFound, " (", int(100 * totalFound / totalSimple), "% simple)"
echo "Total not found:      ", totalNotFound
