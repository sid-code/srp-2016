import cachedapi, strutils, cgi, json, options
export options

import kdg, kdgtools

const
  # kparserURL = "http://requestb.in/1dtii3k1"
  kparserURL = "http://bioai8core.fulton.asu.edu/kparser/ParserServlet"

var kparserAPI = newCachedAPI("kparser", kparserURL)

proc makeRequest(text: string, corefs = false): Option[string] =
  let params = {"text": text, "useCoreference": $corefs}.toTable()
  return kparserAPI.get(params)

proc getNodeType(data: JsonNode): KNodeType =
  let jtrue = newJBool(true)
  if data["isEvent"] == jtrue: ntEvent
  elif data["isASemanticRole"] == jtrue: ntSemRole
  elif data["isClass"] == jtrue: ntClass
  elif data["isEntity"] == jtrue: ntEntity
  else: ntEntity # it's could be a coreferent but I don't know what that even is

proc convertSingle(single: JsonNode): tuple[edge: string, kgraph: KDG] =
  assert single.hasKey("data")
  let data = single["data"]
  let nodeType = getNodeType(data)
  let name = data["word"].str
  let node = KNode(name: name, typ: nodeType)
  var kgraph = newKDG(node)

  let edge = if data.hasKey("Edge"): data["Edge"].str else: "root"

  assert single.hasKey("children")
  let children = single["children"]
  assert children.kind == JArray
  for child in children.items():
    let (childEdge, childKDG) = convertSingle(child)
    kgraph.addEdge(node, childEdge, childKDG)

  return (edge, kgraph)

proc convertToKDGs(data: JsonNode): seq[KDG] =
  newSeq(result, 0)

  assert data.kind == JArray
  for item in data.items():
    assert item.kind == JObject
    let (edge, kgraph) = convertSingle(item)
    assert edge == "root"
    result.add(kgraph)

proc parseKDGJson(kdgJson: string): seq[KDG] {.procvar.} =
  try:
    let parsed = parseJson(kdgJson)
    return convertToKDGs(parsed)
  except:
    return @[blankGraph]

proc kparse*(text: string): Option[seq[KDG]] =
  let resp = makeRequest(text)
  return resp.map(parseKDGJson)
