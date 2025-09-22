local httpserver = require("http.server")
local httpheaders = require("http.headers")
local client = require("src/client")
local ssl_ctx = require('openssl.ssl.context')
local x509 = require('openssl.x509')
local pkey = require('openssl.pkey')

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
    print("Error while proxying request to "..address..": "..res_body)
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
  print(msg)
end

function server:create(config)
  self.config = config

  local ssl_context
  if self.config["tls"] then
    local privkey_file = assert(io.open(self.config["privk_path"],"r"))
    local privkey_content = privkey_file:read("*a")
    local privkey = pkey.new(privkey_content,"PEM")
    local cert_file = assert(io.open(self.config["cert_path"],"r"))
    local cert_content = cert_file:read("*a")
    local cert = x509.new(cert_content,"PEM")
    ssl_context = ssl_ctx.new('TLS',true)
    ssl_context:setCertificate(cert)
    ssl_context:setPrivateKey(privkey)
  end

  self.http_server = assert(httpserver.listen {
    host = self.config["host"],
    port = self.config["port"],
    --family = family,
    onerror = Onerror,
    onstream = Handle,
    tls = self.config["tls"],
    ctx = ssl_context,
    v6only = self.config["ipv6"]
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
