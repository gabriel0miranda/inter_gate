local config = {
  routes = {},
  host = "0.0.0.0",
  port = 3000,
}

function config:load(path)
  if io.open(path,"r") ~= nil then
    print("Found config file in "..path)
    local config_from_file = dofile(path)
    self.routes = config_from_file.routes
    self.host = config_from_file.host
    self.port = config_from_file.port
    return
  end
  print("Could not find config file in "..path)
end

return config
