import ../cachedapi, levenshtein

import strutils, json
import os

template getDataFile(fileName: string): string =
  staticRead(currentSourcePath().parentDir / fileName).strip()

const
  AppID = getDataFile("app_id")
  APIKey = getDataFile("api_key")
  DandelionEndpoint = "http://api.dandelion.eu/datatxt/nex/v1"

let dandelionAPI = newCachedAPI("dandelion", DandelionEndpoint)
proc formulateQuery(text: string, incld = "abstract,categories", id = AppID, key = APIKey): Table[string, string] =
  {"text": text, "include": incld, "$app_id": id, "$app_key": key}.toTable()

proc dandelion*(text: string): Option[string] =
  let params = formulateQuery(text)
  return dandelionAPI.get(params)

proc normalize(s: string): string =
  s.toLower().replace(" ", "")

proc normalizedDistance(s1, s2: string): int =
  levenshtein(s1.normalize(), s2.normalize())

proc fixEntities*(text: var string, underscore = true,
                 maxDistance = 5) =
  let res = dandelion(text)
  var totalOffset = 0
  if res.isSome:
    let parsed = parseJson(res.get)

    for annot in parsed["annotations"]:
      let start = annot["start"].getNum(-1).int + totalOffset
      if start == -1: continue
      let endp = annot["end"].getNum(-1).int + totalOffset
      if endp == -1: continue
      let label = annot["label"].getStr("")
      if label.len == 0: continue
      let spot = annot["spot"].getStr("")
      if spot.len == 0: return

      # Make sure that the label isn't too far away from the spot
      if normalizedDistance(label, spot) > maxDistance:
        continue
      
      let realLabel = if underscore: label.replace(' ', '_') else: label

      totalOffset += realLabel.len - spot.len

      text[start .. endp-1] = realLabel

when isMainModule:
  echo dandelion("How many first generation particles are there?")
