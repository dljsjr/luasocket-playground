local inspect = require "inspect"
local log = require "log"
local m = {}

function m.wait_for(skt, method, ...)
  log.tracef("skt wait for %s", method)
  assert(
    type(method) == "string" or type(method) == "function",
    string.format("bad argument #2 to 'wait_for', expected string or function, received %s", type(method))
  )
  local skt_fn, fn_name
  if type(method) == "string" then
    fn_name = method
    skt_fn = assert(skt[method],
      string.format("no method named '%s' available on socket table passed as arg #1 to 'wait_for'", method))
  else
    local fn_list = getmetatable(skt) and getmetatable(skt).__index or {}
    for k, v in pairs(fn_list) do
      if v == method then
        fn_name = k
      end
    end
    skt_fn = method
  end
  log.tracef("skt wait for %s function name %s", method, fn_name)

  local print_args = {}
  for _, v in pairs(table.pack(...)) do
    table.insert(print_args, inspect(v))
  end
  local arg_string = string.format(string.rep("%s", select("#", ...), ", "), table.unpack(print_args))
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

  log.tracef("skt wait for complete, result: %s, err: %s", inspect(result), inspect(err))
  return result, err
end

return m
