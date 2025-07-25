local unit = require("luaunit")

TestServer = {}
function TestServer:setUp()

  self.config = {
    routes = {},
    host = "0.0.0.0",
    port = 3000,
    tls = false
  }

  self.httpserver = {}
  function self.httpserver:listen(table)
    local svr = {}
    function svr:listen(timeout)
      return true
    end
    function svr:localname()
      return nil, nil, 3000
    end
    function svr:loop()
      return true
    end
    return svr
  end

  self.server = require("../src/server")

  self.client = require("http.request")

  self.stream = {}
  function self.stream:get_headers()
    local httpheaders = require("http.headers")
    local headers = httpheaders.new()
    return headers
  end
  function self.stream:get_body_as_string()
    return "[TESTING]"
  end
  function self.stream:write_headers(_, _)
    return true
  end
  function self.stream:write_chunk(_, _)
    return true
  end

  self.httpsrv = {}
end

function TestServer:testCreation()
  self.server:create(self.config)
  unit.assertNotEquals(self.server.config, {})
  unit.assertNotEquals(self.server.http_server, {})
end

function TestServer:testStart()
  self.server.http_server = self.httpserver:listen({})
  self.server:start()
  unit.assertTrue(self.server.http_server_started)
end

function TestServer:testHealth()
  local headers, body = self.server:health()
  unit.assertEquals(headers:get(":status"),"200")
  unit.assertEquals(body,"[SYSTEMS OK]")
end

TestConfig = {}

TestClient = {}







os.exit(unit.LuaUnit.run())
