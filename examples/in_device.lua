#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')

local cfg = {
  device_name = 'edison_1',
}

-- Shortcuts
local device = nil

local function work()
  while 0 == 0 do
    device:auto_increment{
      { message = 'hello from device!', device = cfg }
    }
    print("Messages in pool: ", device:len())
    fiber.sleep(1)
  end
end

-- Init
box.cfg {
  listen = '0.0.0.0:3301',
  log_level = 5,

  -- Pre-allocated memory, e.g. memory 1.0 = 1 GB
  slab_alloc_arena = 0.5,

  -- Master host
  -- FIXME Add here your host
  replication_source = { '192.168.1.37:3301' }
}

device = box.space[cfg.device_name]

-- Start
fiber.create(work)
