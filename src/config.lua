local config = {
  routes = {},
  host = "0.0.0.0",
  port = 3000,
  tls = false,
  ipv6 = true,
  cert_path = "/usr/share/inter_gate/fullchain.pem",
  privk_path = "/usr/share/inter_gate/privkey.pem"
}

function config:load(path)
  if path == nil then return end
  if io.open(path,"r") ~= nil then
    print("Found config file in "..path)
    local config_from_file = dofile(path)
    self.routes = config_from_file.routes or self.routes
    self.host = config_from_file.host or self.host
    self.port = config_from_file.port or self.port
    self.tls = config_from_file.tls or self.tls
    self.ipv6 = config_from_file.ipv6 or self.ipv6
    self.cert_path = config_from_file.cert_path or self.cert_path
    self.privk_path = config_from_file.privk_path or self.privk_path
    return
  end
  print("Could not find config file in "..path.."\nUsing default configuration...")
end

return config
