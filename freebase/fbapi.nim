import ../cachedapi, strutils, json

import os
template getDataFile(fileName: string): string =
  staticRead(currentSourcePath().parentDir / fileName).strip()

const
  APIKey = getDataFile("api_key")
  FBEndpoint = "https://www.googleapis.com/freebase/v1/search"
  DefaultLimit = 3

let freebaseAPI = newCachedAPI("freebase", FBEndpoint)
proc formulateQuery(query: string, key = APIKey, limit = DefaultLimit): Table[string, string] =
  {"query": query, "key": key, "limit": $limit}.toTable()

# converts /en/blabla to fb:en.blabla
proc normalizeEntityName*(name: string): string {.procvar.} =
  "fb:" & name.replace('/', '.')[1..^1]

proc extractIDs(jsonStr: string): seq[string] {.procvar.} =
  newSeq(result, 0)
  let parsed = parseJson(jsonStr)
  let results = parsed["result"]
  for res in results.items:
    if res.hasKey("id"):
      result.add(res["id"].getStr())
    if res.hasKey("mid"):
      result.add(res["mid"].getStr())

proc search*(text: string): Option[seq[string]] =
  let params = formulateQuery(text)
  let response = freebaseAPI.get(params)
  return response.map(extractIDs)
