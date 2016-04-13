## This is a little library to abstract away the HTTP part of accessing an API.
## To avoid querying the api repeatedly, results are cached using sqlite.
## It encapsulates: one endpoint, one cache for the results of this endpoint

import db_sqlite, tables, options, httpclient
from cgi import encodeURL
export tables, options

# utility proc
proc encodeParams(params: Table[string, string]): string =
  result = ""
  for k, v in params.pairs():
    result.add("&")
    result.add(k)
    result.add("=")
    result.add(encodeURL(v))
  result[0] = '?'

type
  CachedAPI* = object of RootObj
    name*: string
    endpoint*: string

proc openDB(capi: CachedAPI): DbConn =
  return open(capi.name & "cache.db", "user", "pass", capi.name)

proc init(capi: CachedAPI) =
  let db = capi.openDB()
  db.exec(sql"CREATE TABLE IF NOT EXISTS cache (key TEXT UNIQUE not null, value TEXT not null)")
  db.close()

proc getFromCache(capi: CachedAPI, key: string): Option[string] =
  let db = capi.openDB()
  let query = sql"SELECT value FROM cache WHERE key = ?"
  let value = db.getValue(query, key)
  db.close()
  if value.len > 0:
    return some(value)
  else:
    return none(string)

proc putInCache(capi: CachedAPI, key, value: string) =
  let db = capi.openDB()
  let query = sql"INSERT OR IGNORE INTO cache (key, value) VALUES (?, ?)"
  db.exec(query, key, value)
  db.close()

proc getNoCache(capi: CachedAPI, paramStr: string): string =
  let url = capi.endpoint & paramStr
  let resFromAPI = getContent(url)
  capi.putInCache(paramStr, resFromAPI)
  return resFromAPI

proc get*(capi: CachedAPI, path: string, params: Table[string, string]): Option[string] =
  let encodedParams = path & encodeParams(params)
  let resultFromCache = capi.getFromCache(encodedParams)
  if resultFromCache.isSome():
    return some(resultFromCache.unsafeGet())
  
  try:
    return some(capi.getNoCache(encodedParams))
  except:
    stderr.write(capi.name, " error: ", getCurrentExceptionMsg(), "\n")
    return none(string)

proc get*(capi: CachedAPI, params: Table[string, string]): Option[string] =
  capi.get("", params)

proc newCachedAPI*(name, endpoint: string): CachedAPI =
  result = CachedAPI(name: name, endpoint: endpoint)
  result.init()

when isMainModule:
  let capi = CachedAPI(name: "dummy", endpoint: "dummy")
  capi.init()
  capi.putInCache("?some_value=5", "cool result")
  echo capi.get({"some_value": "5"}.toTable())

