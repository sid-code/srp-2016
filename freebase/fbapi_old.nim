import strutils, httpclient, cgi, json, os

const
  fbapiURL = "http://0.0.0.0:8080/"

proc makeRequest(query: string, limit = 5): string =
  let fullURL = "$1?query=$2".format(fbapiURL, encodeURL(query))
  let resp = getContent(fullURL)
  return resp

# converts /en/blabla to fb:en.blabla
proc normalizeEntityName*(name: string): string {.procvar.} =
  "fb:" & name.replace('/', '.')[1..^1]

proc search*(query: string): seq[string] =
  newSeq(result, 0)
  let parsed = parseJson(makeRequest(query))
  let results = parsed["result"]
  for res in results.items:
    if res.hasKey("id"):
      result.add(res["id"].getStr())
    else:
      result.add(res["mid"].getStr())


when isMainModule:
  discard search(paramStr(1))


