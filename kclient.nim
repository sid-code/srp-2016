import asyncdispatch, httpclient, strutils, cgi, json

import kdg, kdgtools

const
  # kparserURL = "http://requestb.in/1dtii3k1"
  kparserURL = "http://bioai8core.fulton.asu.edu/kparser/ParserServlet"

let client = newAsyncHttpClient()

proc makeRequest(text: string, corefs = false): Future[string] {.async.} =
  let fullURL = "$1?text=$2&useCoreference=$3".format(kparserURL, encodeUrl(text), corefs)
  let resp = await client.get(fullURL)
  return resp.body

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

proc kparse*(text: string): Future[seq[KDG]] {.async.} =
  let resp = await makeRequest(text)
  let parsed = parseJson(resp)
  
  return convertToKDGs(parsed)
