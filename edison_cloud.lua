#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local log = require('log')
local yaml = require('yaml')

-- Entry point
box.cfg {

  listen = '*:3301',

  -- NOTE Setup replicas here [[
  replication_source = { '192.168.1.43:3301', '192.168.1.45:3301'},
  -- ]]

  log_level = 3,
  wal_mode='write'
}

fiber.create(function()

  -- Dump replication messages
  local function dump(space, index)
    log.error(yaml.encode({
      space_name = space.name,
      max = index:max()
    }))
  end

  -- Loop
  while 0 == 0 do

    log.error('cycle')

    for _, space in pairs(box.space) do
      -- Filter spaces by prefix, e.g. device_
      if string.find(space.name, 'device_') then
        dump(space, space.index.primary)
      end
    end

    fiber.sleep(1)
  end
end)
