#!/usr/bin/env tarantool

local mqtt = require('mqtt')
local fiber = require('fiber')

local function say(msg)
	local yaml = require('yaml')
	require('log').error(yaml.encode(msg))
end

conn = mqtt.new()

ok, msg = conn:on_message(function(mid, topic, payload)
  say({">>>>>>>>>>>>> ON_MESSAGE", mid, topic, payload})
end)

ok, msg = conn:connect({host="0.0.0.0", port=1883})
say({'CONNETED', ok, emsg})

ok, emsg = conn:subscribe('devices/#')
say({'SUBSCRIBE', ok, emsg})

fiber.create(function()
  while true do
    ok, emsg = conn:publish("devices/UnwiredOne/get", "1")
    say({'publish -> get(1)', ok, emsg})
    fiber.sleep(2)
  end
end)
