## Represents a model that can be "trained" on (essence, path to main object)
## pairs.

import tables
import hashes
import strutils

import essence
import kdg

type
  EPModel = Table[Essence, CountTable[Path]]
  Path = seq[string]

proc hash(ess: Essence): Hash =
  var h: Hash = 0
  h = h !& hash($ess)
  result = !$h

proc hash(path: Path): Hash =
  var h: Hash = 0
  for edge in path:
    h = h !& hash(edge)
  result = !$h

proc initEPModel*: EPModel = initTable[Essence, CountTable[Path]]()

proc addPair*(model: var EPModel, ess: Essence, path: Path) =
  if not model.hasKey(ess):
    model[ess] = initCountTable[Path]()

  if not model[ess].hasKey(path):
    model[ess][path] = 1
  else:
    inc model[ess][path]

iterator predictions(model: EPModel, ess: Essence): tuple[distance: int, ct: CountTable[Path]] =
  for key, ctable in model.pairs():
    let dist = ess.distTo(key)
    echo ess, "  ", key, "  ", dist
    if dist > -1:
      yield (dist, ctable)

proc getMainObject*(kgraph: KDG, model: EPModel): KDG =
  let ess = getEssence(kgraph)
  var bestDistance = high(int)
  var bestAttempt = blankGraph
  for dist, prediction in model.predictions(ess):
    var predict = prediction
    sort predict
    echo dist, " ", predict
    for path, count in predict.pairs():
      let attempt = kgraph.dig(path[1..^1])
      if attempt != blankGraph:
        if dist < bestDistance:
          bestDistance = dist
          bestAttempt = attempt

  return bestAttempt

  
