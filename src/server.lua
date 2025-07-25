local httpserver = require("http.server")
local httpheaders = require("http.headers")
local client = require("src/client")

local server = {
  config = {},
  http_server = {},
  http_server_started = false,
}

function server:health()
  local res_headers = httpheaders.new()
  res_headers:append(":status", "200")
  local res_body = "[SYSTEMS OK]"
  return res_headers, res_body
end

function server:proxy(req_headers, req_body, address)
  local res_headers, res_body = client:request(req_headers, req_body, address)
  if res_headers ~= nil then
    return res_headers, res_body
  else
    res_headers = httpheaders.new()
    res_headers:append(":status", "504")
    res_headers:append("content-type", "text/plain")
    res_body = "[TIMED OUT]"
    error("Error while proxying request to "..address..": "..res_body)
    return res_headers, res_body
  end

end

function Handle(httpsrv, stream)
  local req_headers = assert(stream:get_headers())
  local req_method = req_headers:get(":method")
  local req_path = req_headers:get(":path")
  local req_body = assert(stream:get_body_as_string())
  print(string.format('[%s] "%s %s HTTP/%g"  "%s" "%s"',
		os.date("%d/%b/%Y:%H:%M:%S %z"),
    req_method or "",
    req_headers:get(":path") or "",
    stream.connection.version,
    req_headers:get("referer") or "-",
    req_headers:get("user-agent") or "-"
  ))

  if req_path == "/health" then
      local res_headers, res_body = server:health()
      assert(stream:write_headers(res_headers, false), "Could not write headers")
      assert(stream:write_chunk(res_body, true), "Could not write chunk")
      return 0
  else
    for _, route in pairs(server.config["routes"]) do
      if route.path == req_path then
        local res_headers, res_body = server:proxy(req_headers, req_body, route.address)
        assert(stream:write_headers(res_headers, false), "Could not write headers")
        assert(stream:write_chunk(res_body, true), "Could not write chunk")
        return 0
      end
    end
    local res_headers = httpheaders.new()
    res_headers:append(":status", "404")
    res_headers:append("content-type", "text/plain")
    assert(stream:write_headers(res_headers, req_method == "HEAD"))
    if req_method ~= "HEAD" then
      assert(stream:write_chunk("[NOT FOUND]", true))
      return 0
    end
  end
end

function Onerror(httpsrv, context, op, err, errno)
  local msg = op .. " on " .. tostring(context) .. " failed"
  if err then
    msg = msg .. ": " .. tostring(err)
  end
  error(msg)
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
  return 0
end

function server:start()
  assert(self.http_server:listen(10))
  do
    local bound_port = select(3, self.http_server:localname())
    print("Escutando na porta "..bound_port)
    self.http_server_started = true
  end
  assert(self.http_server:loop())
end

return server
