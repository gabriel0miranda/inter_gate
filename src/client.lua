local httprequest = require("http.request")

local client = {}

function client:request(headers, body, address)
  local request = httprequest.new_from_uri(address..headers:get(":path"))
  request:set_body(body)
  request.headers = headers
  local res_headers, stream = request:go()
  local res_body = assert(stream:get_body_as_string())
  if res_headers:get(":status") ~= "200" then
    error(res_body)
  end

  return res_headers, res_body
end

return client
