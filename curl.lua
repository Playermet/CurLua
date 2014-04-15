-----------------------------------------------------------
--  FFI
-----------------------------------------------------------
local ffi = require 'ffi'
do
  -- Loading additional libs, if you need
  local libs = {
    -- 'zlib1.dll',
    -- 'libeay32.dll',
    -- 'ssleay32.dll',
    -- 'libssh2.dll'
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
--  Type conversion
-----------------------------------------------------------
local type_converters = {
  ['char*[1]']  = ffi.string;
  ['long[1]']   = tonumber;
  ['double[1]'] = tonumber;
}


-----------------------------------------------------------
--  Codes
-----------------------------------------------------------
local option_codes = {
  autoreferer             = 58,
  buffersize              = 98,
  cainfo                  = 10065,
  capath                  = 10097,
  closepolicy             = 72,
  connecttimeout          = 78,
  cookie                  = 10022,
  cookiefile              = 10031,
  cookiejar               = 10082,
  cookielist              = 10135,
  cookiesession           = 96,
  crlf                    = 27,
  customrequest           = 10036,
  debugdata               = 10095,
  debugfunction           = 20094,
  dns_cache_timeout       = 92,
  dns_use_global_cache    = 91,
  egdsocket               = 10077,
  encoding                = 10102,
  errorbuffer             = 10010,
  failonerror             = 45,
  file                    = 10001,
  filetime                = 69,
  followlocation          = 52,
  forbid_reuse            = 75,
  fresh_connect           = 74,
  ftp_account             = 10134,
  ftp_create_missing_dirs = 110,
  ftp_response_timeout    = 112,
  ftp_skip_pasv_ip        = 137,
  ftp_ssl                 = 119,
  ftp_use_eprt            = 106,
  ftp_use_epsv            = 85,
  ftpappend               = 50,
  ftplistonly             = 48,
  ftpport                 = 10017,
  ftpsslauth              = 129,
  header                  = 42,
  headerfunction          = 20079,
  http200aliases          = 10104,
  http_version            = 84,
  httpauth                = 107,
  httpget                 = 80,
  httpheader              = 10023,
  httppost                = 10024,
  httpproxytunnel         = 61,
  ignore_content_length   = 136,
  infile                  = 10009,
  infilesize              = 14,
  infilesize_large        = 30115,
  interface               = 10062,
  ioctldata               = 10131,
  ioctlfunction           = 20130,
  ipresolve               = 113,
  krb4level               = 10063,
  low_speed_limit         = 19,
  low_speed_time          = 20,
  maxconnects             = 71,
  maxfilesize             = 114,
  maxfilesize_large       = 30117,
  maxredirs               = 68,
  netrc                   = 51,
  netrc_file              = 10118,
  nobody                  = 44,
  noprogress              = 43,
  nosignal                = 99,
  port                    = 3,
  post                    = 47,
  postfields              = 10015,
  postfieldsize           = 60,
  postfieldsize_large     = 30120,
  postquote               = 10039,
  prequote                = 10093,
  private                 = 10103,
  progressdata            = 10057,
  progressfunction        = 20056,
  proxy                   = 10004,
  proxyauth               = 111,
  proxyport               = 59,
  proxytype               = 101,
  proxyuserpwd            = 10006,
  put                     = 54,
  quote                   = 10028,
  random_file             = 10076,
  range                   = 10007,
  readfunction            = 20012,
  referer                 = 10016,
  resume_from             = 21,
  resume_from_large       = 30116,
  share                   = 10100,
  source_postquote        = 10128,
  source_prequote         = 10127,
  source_quote            = 10133,
  source_url              = 10132,
  source_userpwd          = 10123,
  ssl_cipher_list         = 10083,
  ssl_ctx_data            = 10109,
  ssl_ctx_function        = 20108,
  ssl_verifyhost          = 81,
  ssl_verifypeer          = 64,
  sslcert                 = 10025,
  sslcertpasswd           = 10026,
  sslcerttype             = 10086,
  sslengine               = 10089,
  sslengine_default       = 90,
  sslkey                  = 10087,
  sslkeytype              = 10088,
  sslversion              = 32,
  stderr                  = 10037,
  tcp_nodelay             = 121,
  telnetoptions           = 10070,
  timecondition           = 33,
  timeout                 = 13,
  timevalue               = 34,
  transfertext            = 53,
  unrestricted_auth       = 105,
  upload                  = 46,
  url                     = 10002,
  useragent               = 10018,
  userpwd                 = 10005,
  verbose                 = 41,
  writedata               = 10001,
  writefunction           = 20011,
  writeheader             = 10029,
  writeinfo               = 10040,
}

local option_utils = {
  postfields = function (post_data)
    if type(post_data) == 'string' then
      return post_data
    end

    if type(post_data) == 'table' then
      local tmp = {}
      for k,v in pairs(post_data) do
        tmp[#tmp+1] = k .. '=' .. v
      end
      return table.concat(tmp, '&')
    end
  end;

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

local info_data = {
  effective_url           = {1048577, 'char*[1]'},
  response_code           = {2097154, 'long[1]'},
  http_connectcode        = {2097174, 'long[1]'},
  filetime                = {2097166, 'long[1]'},
  total_time              = {3145731, 'double[1]'},
  namelookup_time         = {3145732, 'double[1]'},
  connect_time            = {3145733, 'double[1]'},
  appconnect_time         = {3145761, 'double[1]'},
  pretransfer_time        = {3145734, 'double[1]'},
  starttransfer_time      = {3145745, 'double[1]'},
  redirect_time           = {3145747, 'double[1]'},
  redirect_count          = {2097172, 'long[1]'},
  redirect_url            = {1048607, 'char*[1]'},
  size_upload             = {3145735, 'double[1]'},
  size_download           = {3145736, 'double[1]'},
  speed_download          = {3145737, 'double[1]'},
  speed_upload            = {3145738, 'double[1]'},
  header_size             = {2097163, 'long[1]'},
  request_size            = {2097164, 'long[1]'},
  ssl_verifyresult        = {2097165, 'long[1]'},
  content_length_download = {3145743, 'double[1]'},
  content_length_upload   = {3145744, 'double[1]'},
  content_type            = {1048594, 'char*[1]'},
  private                 = {1048597, 'char*[1]'},
  httpauth_avail          = {2097175, 'long[1]'},
  proxyauth_avail         = {2097176, 'long[1]'},
  os_errno                = {2097177, 'long[1]'},
  num_connects            = {2097178, 'long[1]'},
  primary_ip              = {1048608, 'char*[1]'},
  primary_port            = {2097192, 'long[1]'},
  local_ip                = {1048617, 'char*[1]'},
  local_port              = {2097194, 'long[1]'},
  lastsocket              = {2097181, 'long[1]'},
  ftp_entry_path          = {1048606, 'char*[1]'},

  -- ssl_engines          = {4194331, 'curl_slist[1]'},
  -- curlinfo_cookielist  = {4194332, 'curl_slist[1]'}
  -- certinfo             = {4194338,'curl_certinfo[1]'}
  -- tls_session          = {?, 'curl_tlsinfo[1]'}
  -- condition_unmet      = {?, 'long[1]'},
  -- rtsp_session_id      = {?, 'char*[1]'},
  -- rtsp_client_cseq     = {?, 'long[1]'},
  -- rtsp_server_cseq     = {?, 'long[1]'},
  -- rtsp_cseq_recv       = {?, 'long[1]'},
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

local function easy_getinfo(handle, key)
  local data = info_data[key]
  if data then
    local code = data[1]
    local type = data[2]

    local result = ffi.new(type)
    lib.curl_easy_getinfo(handle, code, result)
    if result[0] ~= nil then
      return type_converters[type](result[0])
    end
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
