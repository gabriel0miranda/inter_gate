local httpserver = require("http.server")
local httpheaders = require("http.headers")
local client = require("src/client")

local server = {
  config = {},
  http_server = {},
}

function Health(request)
  local res_headers = httpheaders.new()
  res_headers:append(":status", "200")
  assert(request:write_headers(res_headers, false))
  assert(request:write_chunk("[SYSTEMS OK]", true))
end

function Proxy(req_headers, req_body, request, address)
  local res_headers, res_body = client:request(req_headers, req_body, address)
  if res_headers ~= nil then
    assert(request:write_headers(res_headers, false))
    assert(request:write_chunk(res_body, true))
  else
    res_headers = httpheaders.new()
    res_headers:append(":status", "504")
    res_headers:append("content-type", "text/plain")
    assert(request:write_headers(res_headers, false))
    assert(request:write_chunk("[TIMED OUT]", true))
    print("Error while proxying request to "..address..": "..res_body)
  end

end

function Handle(httpsrv, request)
  local req_headers = assert(request:get_headers())
  local req_method = req_headers:get(":method")
  local req_path = req_headers:get(":path")
  local req_body = assert(request:get_body_as_string())
  print(string.format('[%s] "%s %s HTTP/%g"  "%s" "%s"',
		os.date("%d/%b/%Y:%H:%M:%S %z"),
    req_method or "",
    req_headers:get(":path") or "",
    request.connection.version,
    req_headers:get("referer") or "-",
    req_headers:get("user-agent") or "-"
  ))

  if req_path == "/health" then
      Health(request)
      return
  else
    for _, route in pairs(server.config["routes"]) do
      if route.path == req_path then
        Proxy(req_headers, req_body, request, route.address)
        return
      end
    end
    local res_headers = httpheaders.new()
    res_headers:append(":status", "404")
    res_headers:append("content-type", "text/plain")
    assert(request:write_headers(res_headers, req_method == "HEAD"))
    if req_method ~= "HEAD" then
      assert(request:write_chunk("[NOT FOUND]", true))
    end
  end
end

function Onerror(httpsrv, context, op, err, errno)
  local msg = op .. " on " .. tostring(context) .. " failed"
  if err then
    msg = msg .. ": " .. tostring(err)
  end
  print(msg)
end

function server:create(config)
  self.config = config
  self.http_server = assert(httpserver.listen {
    host = self.config["host"],
    port = self.config["port"],
    onerror = Onerror,
    onstream = Handle,
    tls = self.config["tls"],
  })
end

function server:start()
  assert(self.http_server:listen(10))
  do
    local bound_port = select(3, self.http_server:localname())
    print("Escutando na porta "..bound_port)
  end
  assert(self.http_server:loop())
end

return server
