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

log.tracef("Setting timeout to 0")
assert(srv_skt:settimeout(0))

log.tracef("Binding TCP socket to %s:%s", host, port)
assert(skt_utils.wait_for(srv_skt, srv_skt.bind, host, port))

log.infof("Server socket successfully bound to %s:%s [%s]", srv_skt:getsockname())

log.tracef("Server Socket listening")
assert(skt_utils.wait_for(srv_skt, srv_skt.listen))

log.tracef("Server Socket accepting")
local conn = assert(skt_utils.wait_for(srv_skt, "accept"))

log.tracef("Setting timeout to 0 on acceptec connection")
assert(conn:settimeout(0))

log.infof("Connection accepted from %s:%s [%s], waiting for 'ping'", conn:getpeername())

log.tracef("Receiving on connection")
local recv = assert(skt_utils.wait_for(conn, conn.receive))

log.debugf("Received [%s] from client", inspect(recv))
assert(recv == "ping", string.format("expected 'ping', got %s", inspect(recv)))

log.infof("Received 'ping', sending 'pong'", conn:getpeername())
log.tracef("Sending 'pong'")
assert(skt_utils.wait_for(conn, "send", "pong\n"))

log.infof("'pong' sent, press any key to terminate the socket")
local _ = io.read()

conn:shutdown()
conn:close()
srv_skt:close()
