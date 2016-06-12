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

local devices = {}

-- Add spaces. Each device have own space for brotcast messages to cloud
function add_device(device_name)

  -- message bus
  local message_bus = box.schema.space.create(device_name .. '_mbus', {
    if_not_exists = true})
  message_bus:create_index('pk', {if_not_exists = true})

  -- settings
  local settings = box.schema.space.create(device_name .. '_settings', {
    if_not_exists = true})
  settings:create_index('pk', {
    if_not_exists = true,
    type = 'HASH',
    parts = {1, 'STR'}
  })

  -- sensors timeline
  local sensors_timeline = box.schema.space.create(
    device_name .. '_sensors_timeline', {if_not_exists = true})

  sensors_timeline:create_index('pk', {if_not_exists = true})
  sensors_timeline:create_index('ttl', {
    if_not_exists = true,
    type = 'TREE',
    unique = false,
    parts = {2, 'NUM'}
  })

  devices[device_name] = {
    message_bus = message_bus,
    settings = settings,
    sensors_timeline = sensors_timeline
  }

  return add_device
end

-- Add devices
add_device('edison_1')

-- Setup replication
box.cfg {
  -- FIXME Add here your hosts
  replication_source = { '192.168.1.43:3301' }--, '192.168.1.45:3301'}
}


-- API

-- Entry point
--
function cloud_work()

  -- Cloud work helpers
  local function process_sensors_timeline(device)

    local sensors_timeline = device.sensors_timeline
    -- Loop over new messages
    for _, tuple in pairs(sensors_timeline:select()) do
      log.error(yaml.encode(tuple))
    end
  end

  -- Loop over devices
  while true do
    log.error('process_message_bus - cycle')
    for _, device in pairs(devices) do
      process_sensors_timeline(device)
    end
    fiber.sleep(1)
  end

end

-- Start fiber thread
fiber.create(cloud_work)
