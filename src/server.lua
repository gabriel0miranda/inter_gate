local httpserver = require("http.server")
local httpheaders = require("http.headers")
local client = require("src/client")

local server = {
  config = {},
  http_server = {},
  cqueues_socket = {},
}

local default_config = {
  routes = {
    { path = "/hello_world", address = "http://fortune.section0:4000",middlewares = {"test_middleware"}},
    { path = "/health", address = "http://localhost:3000", middlewares = {}},
  },
  host = "0.0.0.0",
  port = 3000
}

function Health(request)
  local res_headers = httpheaders.new()
  res_headers:append(":status", "200")
  assert(request:write_headers(res_headers, false))
  assert(request:write_chunk("[SYSTEMS OK]", true))
end

function Proxy(req_headers, req_body, request, address)
  local res_headers, res_body = client:request(req_headers, req_body, address)
  assert(request:write_headers(res_headers, false))
  assert(request:write_chunk(res_body, true))

end

function Handle(httpsrv, request)
  local req_headers = assert(request:get_headers())
  local req_method = req_headers:get(":method")
  local req_path = req_headers:get(":path")
  local req_body = assert(request:get_body_as_string())
  assert(io.stdout:write(string.format('[%s] "%s %s HTTP/%g"  "%s" "%s"\n',
		os.date("%d/%b/%Y:%H:%M:%S %z"),
    req_method or "",
    req_headers:get(":path") or "",
    request.connection.version,
    req_headers:get("referer") or "-",
    req_headers:get("user-agent") or "-"
  )))

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
  assert(io.stderr:write(msg, "\n"))
end

function server:create(config)
  if config ~= nil then
    self.config = config
  else
    self.config = default_config
  end
  self.http_server = assert(httpserver.listen {
    host = self.config["host"],
    port = self.config["port"],
    onerror = Onerror,
    onstream = Handle,
    tls = false,
  })
end

function server:start()
  assert(self.http_server:listen())
  do
    local bound_port = select(3, self.http_server:localname())
    assert(io.stderr:write(string.format("Escutando na porta %d\n", bound_port)))
  end
  assert(self.http_server:loop())
end

return server
