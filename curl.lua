-----------------------------------------------------------
--  FFI
-----------------------------------------------------------
local ffi = require 'ffi'

do
  local libs = {
    'libidn-11.dll',
    'libeay32.dll',
    'ssleay32.dll',
    'zlib1.dll',
    'libssh2.dll'
  }
  for i = 1, #libs do
    ffi.load(libs[i])
  end
end

ffi.cdef [[
  typedef void* CURL;
  typedef char* URL;

  int  curl_version ();
  void curl_free    (char*);

  CURL curl_easy_init      ();
  CURL curl_easy_duphandle (CURL handle);
  void curl_easy_cleanup   (CURL handle);
  void curl_easy_reset     (CURL handle);

  int curl_easy_perform (CURL handle);
  int curl_easy_setopt  (CURL handle, int option, ...);
  int curl_easy_getinfo (CURL handle, int info, ...);

  URL curl_easy_escape   (CURL handle, URL url, int length);
  URL curl_easy_unescape (CURL handle, URL url, int length, int* outlength);
]]

local lib = ffi.load 'libcurl.dll'

-----------------------------------------------------------
--  Codes
-----------------------------------------------------------
local option_codes = {
  port                    = 3,
  timeout                 = 13,
  infilesize              = 14,
  low_speed_limit         = 19,
  low_speed_time          = 20,
  resume_from             = 21,
  crlf                    = 27,
  sslversion              = 32,
  timecondition           = 33,
  timevalue               = 34,
  verbose                 = 41,
  header                  = 42,
  noprogress              = 43,
  nobody                  = 44,
  failonerror             = 45,
  upload                  = 46,
  post                    = 47,
  ftplistonly             = 48,
  ftpappend               = 50,
  netrc                   = 51,
  followlocation          = 52,
  transfertext            = 53,
  put                     = 54,
  autoreferer             = 58,
  proxyport               = 59,
  postfieldsize           = 60,
  httpproxytunnel         = 61,
  ssl_verifypeer          = 64,
  maxredirs               = 68,
  filetime                = 69,
  maxconnects             = 71,
  closepolicy             = 72,
  fresh_connect           = 74,
  forbid_reuse            = 75,
  connecttimeout          = 78,
  httpget                 = 80,
  ssl_verifyhost          = 81,
  http_version            = 84,
  ftp_use_epsv            = 85,
  sslengine_default       = 90,
  dns_use_global_cache    = 91,
  dns_cache_timeout       = 92,
  cookiesession           = 96,
  buffersize              = 98,
  nosignal                = 99,
  proxytype               = 101,
  unrestricted_auth       = 105,
  ftp_use_eprt            = 106,
  httpauth                = 107,
  ftp_create_missing_dirs = 110,
  proxyauth               = 111,
  ftp_response_timeout    = 112,
  ipresolve               = 113,
  maxfilesize             = 114,
  ftp_ssl                 = 119,
  tcp_nodelay             = 121,
  ftpsslauth              = 129,
  ignore_content_length   = 136,
  ftp_skip_pasv_ip        = 137,
  file                    = 10001,
  url                     = 10002,
  proxy                   = 10004,
  userpwd                 = 10005,
  proxyuserpwd            = 10006,
  range                   = 10007,
  infile                  = 10009,
  errorbuffer             = 10010,
  postfields              = 10015,
  referer                 = 10016,
  ftpport                 = 10017,
  useragent               = 10018,
  cookie                  = 10022,
  httpheader              = 10023,
  httppost                = 10024,
  sslcert                 = 10025,
  sslcertpasswd           = 10026,
  quote                   = 10028,
  writeheader             = 10029,
  cookiefile              = 10031,
  customrequest           = 10036,
  stderr                  = 10037,
  postquote               = 10039,
  writeinfo               = 10040,
  progressdata            = 10057,
  interface               = 10062,
  krb4level               = 10063,
  cainfo                  = 10065,
  telnetoptions           = 10070,
  random_file             = 10076,
  egdsocket               = 10077,
  cookiejar               = 10082,
  ssl_cipher_list         = 10083,
  sslcerttype             = 10086,
  sslkey                  = 10087,
  sslkeytype              = 10088,
  sslengine               = 10089,
  prequote                = 10093,
  debugdata               = 10095,
  capath                  = 10097,
  share                   = 10100,
  encoding                = 10102,
  private                 = 10103,
  http200aliases          = 10104,
  ssl_ctx_data            = 10109,
  netrc_file              = 10118,
  source_userpwd          = 10123,
  source_prequote         = 10127,
  source_postquote        = 10128,
  ioctldata               = 10131,
  source_url              = 10132,
  source_quote            = 10133,
  ftp_account             = 10134,
  cookielist              = 10135,
  writefunction           = 20011,
  readfunction            = 20012,
  progressfunction        = 20056,
  headerfunction          = 20079,
  debugfunction           = 20094,
  ssl_ctx_function        = 20108,
  ioctlfunction           = 20130,
  infilesize_large        = 30115,
  resume_from_large       = 30116,
  maxfilesize_large       = 30117,
  postfieldsize_large     = 30120
}

local option_utils = {
  writefunction = function (callback)
    return ffi.cast('size_t (*)(char*, size_t, size_t, void*)', callback)
  end;

  readfunction = function (callback)
    return ffi.cast('size_t (*)(void*, size_t, size_t, void*)', callback)
  end;

  headerfunction = function (callback)
    return ffi.cast('size_t (*)(void*, size_t, size_t, void*)', callback)
  end;

  progressfunction = function (callback)
    return ffi.cast('size_t (*)(void*, double, double, double, double)', callback)
  end;
}

local info_funcs = {
  response_code = function (handle)
    local result = ffi.new('long[1]')
    lib.curl_easy_getinfo(handle, 2097154, result)
    return tonumber(result[0])
  end;

  content_type = function (handle)
    local result = ffi.new('char*[1]')
    lib.curl_easy_getinfo(handle, 1048594, result)
    return ffi.string(result[0])
  end;
}

-----------------------------------------------------------
--  Implementation
-----------------------------------------------------------
local function version()
  return lib.curl_version()
end

local function easy_init()
  local handle = lib.curl_easy_init()
  if handle ~=nil then
    ffi.gc(handle, lib.curl_easy_cleanup)
    return handle
  end
  return false
end

local function easy_duphandle(handle)
  local duplicate = lib.curl_easy_duphandle(handle)
  if handle ~=nil then
    ffi.gc(handle, lib.curl_easy_cleanup)
    return handle
  end
  return false
end

local function easy_reset(handle)
  lib.curl_easy_reset(handle)
end

local function easy_perform(handle)
  return lib.curl_easy_perform(handle);
end

local function easy_setopt(handle, key, val)
  local code = option_codes[key]
  local util = option_utils[key]
  if util then val = util(val) end
  return lib.curl_easy_setopt(handle, code, val)
end

local function easy_getinfo(handle, info)
  local func = info_funcs[info]
  if func then
    return func(handle, info)
  end
end

local function easy_escape(handle, url)
  local len = #url
  url = ffi.new('char[?]', len, url)
  local out_url = lib.curl_easy_escape(handle, url, len)

  local str = ffi.string(out_url)
  lib.curl_free(out_url)
  return str
end

local function easy_unescape(handle, url)
  local len = #url
  url = ffi.new('char[?]', len, url)
  local tmp = ffi.new('int[1]') -- int*
  local out_url = lib.curl_easy_unescape(handle, url, len, tmp)

  local str = ffi.string(out_url)
  lib.curl_free(out_url)
  return str
end


-----------------------------------------------------------
--  Wrapper
-----------------------------------------------------------
local wrapper_mt = {}
wrapper_mt.__index = wrapper_mt

local function wrap(handle)
  local wrapper = {
    handle = handle
  }
  return setmetatable(wrapper, wrapper_mt)
end

local function init()
  return wrap(easy_init())
end

function wrapper_mt:reset()
  easy_reset(self.handle)
end

function wrapper_mt:clone()
  return wrap(easy_duphandle(self.handle))
end

function wrapper_mt:options(options)
  for key, val in pairs(options) do
    easy_setopt(self.handle, key, val)
  end
end

function wrapper_mt:perform(options)
  self:options(options)
  return easy_perform(self.handle)
end

function wrapper_mt:escape(url)
  return easy_escape(self.handle, url)
end

function wrapper_mt:unescape(url)
  return easy_unescape(self.handle, url)
end


info_mt = {}
function info_mt:__index(key)
  return easy_getinfo(self.handle, key)
end

function wrapper_mt:info()
  local info = {
    handle = self.handle
  }
  return setmetatable(info, info_mt)
end

-----------------------------------------------------------
--  Interface
-----------------------------------------------------------
return {
  version = version;
  init    = init;
}
