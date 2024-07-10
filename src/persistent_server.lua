local log = require "log"
log.level = "info"

local inspect = require "inspect"
local parse = require "parsearg"
local socket = require "socket"

local skt_utils = require "skt_utils"

local host, port = parse(arg)

log.debugf("Parsed Host: %s, Parsed Port: %s", host, port)

log.infof("Starting server socket on %s:%s", host, port)

log.tracef("Creating TCP socket")
local srv_skt = socket.tcp()

log.tracef("Binding TCP socket to %s:%s", host, port)
assert(srv_skt:bind(host, port))

log.infof("Server socket successfully bound to %s:%s [%s]", srv_skt:getsockname())

log.tracef("Server Socket listening")
assert(srv_skt:listen())

log.info("Starting server loop")
local connections = {}
while true do
  local receivers = { srv_skt }
  for _, sock in pairs(connections) do
    table.insert(receivers, sock)
  end
  log.tracef("socket select on server and existing connections")
  local recv_ready, _, err = socket.select(receivers, {}, nil)

  if err and err ~= "timeout" then
    error(string.format("Error selecting sockets: %s", inspect(err)))
  end

  if recv_ready and #recv_ready >= 1 then
    log.debugf("recv ready:\n%s", inspect(recv_ready))
    for _, sock in ipairs(recv_ready) do
      if sock == srv_skt then
        log.tracef("Server Socket accepting")
        local conn, accpt_err = srv_skt:accept()
        if conn and not accpt_err then
          local peername = table.concat(table.pack(conn:getpeername()), ':')
          connections[peername] = conn
        elseif accpt_err and accpt_err ~= "timeout" then
          srv_skt:close()
          error(string.format("Unexpected error during accept: %s", inspect(err)))
        end
      else
        local peername = table.concat(table.pack(sock:getpeername()), ':')
        log.tracef("Receiving on connection %s:%s", sock:getpeername())
        local recv, recv_err = sock:receive()
        if recv_err == "closed" then
          log.infof("Socket %s:%s closed", sock:getpeername())
          connections[peername] = nil
          sock:shutdown()
          sock:close()
        elseif recv_err == "timeout" then
          log.warnf("Timeout after select returned ready")
        elseif recv_err then
          log.errorf("Unexpected error on %s:%s", sock:getpeername())
          connections[peername] = nil
          sock:shutdown()
          sock:close()
        else
          log.debugf("Received [%s] from client", inspect(recv))
          log.tracef("Sending message to client")
          assert(sock:send(string.format("hello, %s:%s [%s]!\n", sock:getpeername())))
        end
      end
    end
  end
end
