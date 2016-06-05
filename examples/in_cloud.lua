#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local log = require('log')
local yaml = require('yaml')

-- Init
box.cfg {
  listen = '*:3301',
  log_level = 3,
  wal_mode = 'write'
}

box.once('give_rights', function()
  box.schema.user.grant('guest', 'read,write,execute', 'universe')
end)

-- Add spaces. Each device have own space for brotcast messages to cloud
function add_device(device_name)
  local device = box.schema.space.create(device_name, {if_not_exists = true})
  device:create_index('message_bus', {if_not_exists = true})
  return add_device
end

add_device('edison_1')('edison_2')

-- Setup replication
box.cfg {
  -- FIXME Add here your hosts
  replication_source = { '192.168.1.43:3301', '192.168.1.45:3301'}
}

-- Entry point
--
function cloud_work()

  local function process_messages(device)
    -- Loop over new messages
    for _, tuple in pairs(device:select({0}, {iterator="GE"})) do
      local id = tuple:unpack()
      log.error(yaml.encode(tuple))
      device:delete({id})
    end
  end

  -- For easy understanding we add devices manually
  local devices = { box.space.edison_1, box.space.edison_2 }

  -- Loop over devices
  while 0 == 0 do
    log.error('process_message_bus - cycle')
    for _, device in pairs(devices) do
      process_messages(device)
    end
    fiber.sleep(1)
  end

end

-- Start fiber thread
fiber.create(cloud_work)
