local configuration = {
  routes = {
    { path = "/fortune",
      address = "http://fortune:3000",
      middlewares = {"test_middleware"}},
    },
  host = "0.0.0.0",
  port = 3000,
}

return configuration
