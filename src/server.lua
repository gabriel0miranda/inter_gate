local server {
  config = {},
}

local default_config = {
  routes = {
    {1, "/hello_world", "http://localhost:8081", {"test_middleware"}},
  }
}
function server:create(config)
  if config ~= nil then
    self.config = config
  else
    self.config = default_config
  end
end

function server:handle_request(skt)
  local data, err = skt:receive()
end
return server
