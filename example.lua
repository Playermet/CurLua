local libcurl = require 'curl'

local curl = libcurl.init()
curl:perform{
  url = 'http://example.com',
  postfields = { a = 1, b = 2}
}

info = curl:info()
print('Response code:', info.response_code)
print('Content type:',  info.content_type)
