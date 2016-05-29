#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local log = require('log')
local yaml = require('yaml')

-- Entry point
box.cfg {

  listen = '*:3301',

  -- NOTE Setup replicas here [[
  replication_source = {'192.168.1.43:3301', '192.168.1.45:3301'},
  -- ]]

  log_level = 3,
  wal_mode='write'
}

local loop = fiber.create(function()

  local device_1 = box.space.device_1

  -- Loop
  while 0 == 0 do

    log.error('cycle')

    for _, tuple in
        pairs(device_1.index.devices:select({'device'}, {iterator="LT"})) do
      local id = tuple:unpack()
      log.error("==== New message ===")
      log.error(yaml.encode(tuple))
      log.error("=== Deleted ===")
      log.error(yaml.encode(device_1:delete({id})))
    end

    fiber.sleep(1)
  end
end)
