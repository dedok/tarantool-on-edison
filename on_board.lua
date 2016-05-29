#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local console = require('console')
local log = require('log')
local yaml = require('yaml')

-- Local config
local cfg = {
  uuid = '1', -- TODO dev uniq ID
  device_name_prefix = 'device_',
  space_name = nil
}
-- Generate uniq dev space name, see TODO
cfg.space_name = cfg.device_name_prefix .. cfg.uuid

-- Shortcuts
local device = nil

-- poll something via fiber
local function poll_dev()
  while 0 == 0 do
    device:auto_increment{

      -- device id
      cfg.uuid,

      -- Message [[
      {message = 'hello from device!',
      device = {
        space_name = cfg.space_name,
        uuid = cfg.uuid
      }}
      -- ]]
    }
    print("inserted = ", device:len())
    fiber.sleep(1)
  end
end

-- Entry point
(function()

  box.cfg {
    listen = '0.0.0.0:3301',
    log_level = 5,
    slab_alloc_arena = 0.5,
  }

  device = box.space[cfg.space_name]
  if not device then
    box.schema.user.grant('guest', 'read,write,execute', 'universe')
    device = box.schema.space.create(cfg.space_name)
    device:create_index('msgs', {})
    device:create_index('devices', {
      type = "tree",
      unique = false,
      parts = { 2, 'str' }
    })
  end

  -- Admin console
  console.listen('0.0.0.0:3302')

  -- Start poll
  fiber.create(poll_dev)
end)()
