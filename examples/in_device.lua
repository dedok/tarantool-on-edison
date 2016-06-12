#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local mraa = require('mraa')

local cfg = {
  device_name = 'edison_1',
}

-- Shortcuts
local device = {
  sensors = {}
}

local function work()

  -- Work helpers
  local function get_temperature()
    local B = 3975
    local a = device.sensors.temperature:read()
    local resistance = (1023-a)*10000.0/a
    return 1/(math.log(resistance/10000.0)/B+1/298.15)-273.15
  end

  -- Shortcuts
  local sensors_timeline = device.sensors_timeline
  local st_ttl = sensors_timeline.index.ttl;

  while true do

    local current_time = fiber.time()

    -- drain olds
    local tuples = sensors_timeline
    for _, tuple in st_ttl:select{current_time, {iterator = 'LT'}} do
      local id = tuple:unpack()
      st_ttl:delete{id}
    end

    sensors_timeline:auto_increment{{
      temperature = get_temperature(),
      ttl = current_time + 60
    }}

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

device =  {
  message_bus = box.space[cfg.device .. '_mbus'],
  settings = box.space[cfg.device_name .. '_settings'],
  sensors_timeline = box.space[cfg.device_name .. '_sensors_timeline'],

  sensors = {
    light = mraa.Aio(0),
    temperature = mraa.Aio(1),
    sound = mraa.Aio(2),
    diod_light = mraa.Gpio(4),
    buzzer = mraa.Gpio(8)
  }
}

device.sensors.diod_light:dir(mraa.DIR_OUT)
device.sensors.buzzer:dir(mraa.DIR_OUT)

-- Start
fiber.create(work)
