local log = require "log"
log.level = "info"

local inspect = require "inspect"
local parse = require "parsearg"
local socket = require "socket"

local skt_utils = require "skt_utils"

local host, port = parse(arg)

log.debugf("Parsed Host: %s, Parsed Port: %s", host, port)

log.infof("Starting client socket on %s:%s", host, port)

log.tracef("Creating TCP socket")
local client_skt = socket.tcp()

log.tracef("Setting timeout to 0")
assert(client_skt:settimeout(0))

log.tracef("Client Socket connecting")
assert(skt_utils.wait_for(client_skt, "connect", host, port))

log.infof("Client socket successfully connected to %s:%s [%s], sending 'ping'", client_skt:getpeername())
log.debugf("Client socket local info: %s:%s [%s]", client_skt:getsockname())

log.tracef("Client Socket sending")
assert(skt_utils.wait_for(client_skt, "send", 'ping\n'))

log.infof("Client sent 'ping', waiting for 'pong'")
log.tracef("Receiving")
local recv = assert(skt_utils.wait_for(client_skt, "receive"))

log.debugf("Received [%s] from server", inspect(recv))
assert(recv == "pong", string.format("expected 'pong', got %s", inspect(recv)))

log.infof("Received 'pong'")

log.infof("'pong' received, press any key to terminate the socket")
local _ = io.read()

client_skt:shutdown()
client_skt:close()
