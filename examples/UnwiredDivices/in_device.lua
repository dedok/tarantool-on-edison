#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local log = require('log')

-- Setup replication
box.cfg{replication_source = __HOST__}

-- Setup Unwired Device gateway
local function setup_gateway(on_message)

  local mqtt = require('mqtt')

  local conn = mqtt.new()

  local ok, emsg

  ok, emsg = conn:on_message(on_message)

  if not ok then
    log.error('mqtt:on_message error %s', emsg)
    return nil
  end

  ok, emsg = conn:connect({host="0.0.0.0", port=1883})
  if not ok then
    log.error('mqtt:connect error %s', emsg)
    return nil
  end

  ok, emsg = conn:subscribe('devices/#')
  if not ok then
    log.error('mqtt:subscribe error %s', emsg)
    return nil
  end

  return conn
end

-- Reference to table (space)
local msgs = box.space.msgs

conn = setup_gateway(
  function(mid, topic, payload)
    msgs:auto_increment{topic, payload}
  end)


-- Cleanup work
fiber.create(function()
  local tester = box.space.tester
  while true do
    msgs:delete{}
    fiber.sleep(10.0)
  end
end)
