local copas = require("copas")
local socket = require("socket")
local config = require("config")
local server = require("server")

local address = "*"
local port = os.getenv("PORT")
local ssl_params = {
  wrap = {
    mode = "server",
    protocol = "any",
  }
}

config:load(os.getenv("CONFIG_PATH"))
server:create(config)

local server_socket = assert(socket.bind(address, port))

copas.addthread(function()
  copas.addserver(server_socket, copas.handler(server.handle_request,ssl_params), "0")
  copas.waitforexit()
  copas.removeserver(server_socket)
end)

copas()
