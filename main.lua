local config = require("src/config")
local server = require("src/server")

-- load configuration from path
config:load(os.getenv("CONFIG_PATH"))

server:create(config)

server:start()
