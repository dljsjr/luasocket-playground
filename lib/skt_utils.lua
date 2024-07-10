local inspect = require "inspect"
local log = require "log"
local socket = require "socket"

local m = {}

local function _skt_utils_parse(skt, method, ...)
  assert(
    type(method) == "string" or type(method) == "function",
    string.format("bad argument #2 for `skt_utils` wrapper, expected string or function, received %s", type(method))
  )
  local skt_fn, fn_name
  if type(method) == "string" then
    fn_name = method
    skt_fn = assert(skt[method],
      string.format("no method named '%s' available on socket table passed as arg #1 to `skt_utils` wrapper", method))
  else
    local fn_list = getmetatable(skt) and getmetatable(skt).__index or {}
    for k, v in pairs(fn_list) do
      if v == method then
        fn_name = k
      end
    end
    skt_fn = method
  end

  local print_args = {}
  for _, v in pairs(table.pack(...)) do
    table.insert(print_args, inspect(v))
  end
  local arg_string = string.format(string.rep("%s", select("#", ...), ", "), table.unpack(print_args))
  return fn_name, skt_fn, arg_string
end

local function _poll_nonblocking(skt, readsocks, writesocks, fn_name, skt_fn, arg_string, ...)
  log.tracef("starting nonblocking poll for skt:%s(%s), calling once to see if ready", fn_name, arg_string)
  local result, err = skt_fn(skt, ...)

  if err == "timeout" then log.debugf("timeout calling skt:%s(%s), going to select loop", fn_name, arg_string) end

  if err and err ~= "timeout" then
    return result, err
  end

  while not result do
    log.tracef("Socket select before skt:%s(%s)", fn_name, arg_string)
    local recv_ready, send_ready, select_err = socket.select(readsocks, writesocks, nil)
    log.tracef("Socket select complete.\nrecvr:\n%s,\nsendr:\n%s,\nerr: %s", inspect(recv_ready), inspect(send_ready), inspect(select_err))
    if select_err and select_err ~= "timeout" then error(string.format("Unexpected select err: %s", inspect(err))) end
    for _, sock in ipairs(recv_ready or {}) do
      if sock == skt then
        result, err = skt_fn(skt, ...)
        if err then log.debugf("skt:%s(%s) err: %s", fn_name, arg_string, err) end
        break
      end
    end

    for _, sock in ipairs(send_ready or {}) do
      if sock == skt then
        result, err = skt_fn(skt, ...)
        if err then log.debugf("skt:%s(%s) err: %s", fn_name, arg_string, err) end
        break
      end
    end
    if err and err ~= "timeout" then
      break
    end
  end

  log.tracef("skt nonblocking poll for %s complete, result: %s, err: %s", fn_name, inspect(result), inspect(err))
  return result, err
end

function m.poll_nonblocking_read(skt, method, ...)
  log.tracef("skt poll nonblocking for %s", method)
  local fn_name, skt_fn, arg_string = _skt_utils_parse(skt, method, ...)
  log.tracef("skt poll nonblocking %s function name %s", method, fn_name)
  log.debugf("polling skt:%s(%s)", fn_name, arg_string)
  return _poll_nonblocking(skt, { skt }, nil, fn_name, skt_fn, arg_string, ...)
end

function m.poll_nonblocking_write(skt, method, ...)
  log.tracef("skt poll nonblocking for %s", method)
  local fn_name, skt_fn, arg_string = _skt_utils_parse(skt, method, ...)
  log.tracef("skt poll nonblocking %s function name %s", method, fn_name)
  log.debugf("polling skt:%s(%s)", fn_name, arg_string)
  return _poll_nonblocking(skt, nil, { skt }, fn_name, skt_fn, arg_string, ...)
end

function m.wait_for(skt, method, ...)
  log.tracef("skt wait for %s", method)
  local fn_name, skt_fn, arg_string = _skt_utils_parse(skt, method, ...)
  log.tracef("skt wait for %s function name %s", method, fn_name)
  log.debugf("waiting for skt:%s(%s)", fn_name, arg_string)
  local result, err = nil, nil
  while not result do
    print(string.format("waiting for skt:%s(%s), press any key to continue", fn_name, arg_string))
    local _ = io.read()
    result, err = skt_fn(skt, ...)
    if err then log.debugf("skt:%s(%s) err: %s", fn_name, arg_string, err) end
    if err ~= nil and err ~= "timeout" then
      break
    end
  end

  log.tracef("skt wait for %s complete, result: %s, err: %s", fn_name, inspect(result), inspect(err))
  return result, err
end

return m
