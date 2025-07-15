local config = {
}

function config:load(path)
  config["routes"] = {
    { path = "/fortune", address = "http://fortune:3000",middlewares = {"test_middleware"}},
  }
  config["host"] = "0.0.0.0"
  config["port"] = 3000
end

return config
