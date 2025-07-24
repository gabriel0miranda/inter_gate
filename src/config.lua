local config = {
  routes = {},
  host = "0.0.0.0",
  port = 3000,
  tls = false
}

function config:load(path)
  if io.open(path,"r") ~= nil then
    print("Found config file in "..path)
    local config_from_file = dofile(path)
    self.routes = config_from_file.routes
    self.host = config_from_file.host
    self.port = config_from_file.port
    self.tls = config_from_file.tls
    return
  end
  print("Could not find config file in "..path.."\nUsing default configuration...")
end

return config
