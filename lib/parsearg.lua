local inspect = require "inspect"
local log = require "log"

local DEFAULT_HOST = "127.0.0.1"
local DEFAULT_PORT = "9999"

return function(args)
  local host, port, loglevel
  local idx, var = next(args)
  while idx do
    if idx >= 1 then
      if var == "--log" or var == "-l" or string.find((var or ""), "^--log=") then
        local matched = string.match(var, "--log=([%g]+)")
        if matched then
          loglevel = matched
        else
          idx, var = next(args, idx)
          loglevel = var
        end
        log.tracef("parsed log level: %s", loglevel)
      elseif var == "--host" or var == "-h" or string.find((var or ""), "^--host=") then
        local matched = string.match(var, "--host=([%g]+)")
        if matched then
          host = matched
        else
          idx, var = next(args, idx)
          host = var
        end
        log.tracef("parsed host: %s", host)
      elseif var == "--port" or var == "-p" or string.find((var or ""), "^--port=") then
        local matched = string.match(var, "--port=([%g]+)")
        if matched then
          port = matched
        else
          idx, var = next(args, idx)
          port = var
        end
        log.tracef("parsed port: %s", port)
      else
        log.warnf("Unexpected arg %s", inspect(var))
      end
    end
    idx, var = next(args, idx)
  end

  if loglevel then log.level = loglevel end
  return (host or DEFAULT_HOST), (port or DEFAULT_PORT)
end
