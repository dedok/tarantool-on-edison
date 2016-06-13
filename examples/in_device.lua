#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local mraa = require('mraa')
local yaml = require('yaml')
local log = require('log')

-- Device cfg
local cfg = {
  device_name = 'edison_1',
}

-- Init master - master [[
box.cfg {
  listen = '0.0.0.0:3301',
  log_level = 5,

  -- Pre-allocated memory, e.g. memory 1.0 = 1 GB
  slab_alloc_arena = 0.5,

  -- Master host
  -- FIXME Add here your host
  replication_source = { '192.168.1.37:3301' }
}
-- ]]

--
-- Abstract helpers [[
local function test_max_value(self, sensor_data)
  local name = self.name
  local tuple = settings:get{name}
  if not tuple then
    settings:insert{name, {max = self.default_max, alert = false}}
    tuple = settings:get{name}
  end
  local _, settings = settings[1]:unpack()
  if sensor_data[self.name] > settings.max then
    settings.alert = true
    settings:replace{name, settings}
  end
  return settings.alert
end

local function aio_read(self)
  return self.io:read()
end
-- ]]

--
-- Device object
device =  {

  -- Spaces references
  message_bus = box.space[cfg.device_name .. '_mbus'],
  settings = box.space[cfg.device_name .. '_settings'],
  sensors_timeline = box.space[cfg.device_name .. '_sensors_timeline'],

  -- Sensors e.g input sensors
  sensors = {

    light = {
      io = mraa.Aio(0),
      name = 'light',
      default_max = 100,

      get_data = aio_read,
      test_max = test_max_value
    },

    temperature = {
      io = mraa.Aio(1),
      name = 'temperature',
      default_max = 30,

      get_data = function(self)
        local B = 3975
        local a = self.io:read()
        local resistance = (1023-a)*10000.0/a
        return math.floor(1/(math.log(resistance/10000.0)/B+1/298.15)-273.15)
      end,

      test_max = test_max_value
    },

    sound = {
      io = mraa.Aio(2),
      name = 'sound',
      default_max = 100,

      get_data = aio_read,
      test_max = test_max_value
    }
  },

  -- Alerts e.g. output devices
  alert = {

    initialised = false,

    diod_light = mraa.Gpio(4),
    buzzer = mraa.Gpio(8),

    init_once = function(self)
      if not initialised then
        self.diod_light:dir(mraa.DIR_OUT)
        self.buzzer:dir(mraa.DIR_OUT)
        initialised = true
      end
    end,

    alert = function(self, state)
      self:init_once()
    end
  }
}
-- ]]

local function main_work()

  -- Shortcuts
  local settings = device.settings
  local sensors_timeline = device.sensors_timeline
  local st_ttl = sensors_timeline.index.ttl
  local sensors = device.sensors
  local alert = device.alert

  -- Work loop [[
  local ticks = 0

  while true do

    log.error('[+] cycle ...')

    -- Cleanup an old sensors data
    if ticks > 10 then
      ticks = 0
        -- drain olds
        for _, tuple in pairs(st_ttl:select{}) do
                print(yaml.encode(tuple))
                local id = tuple:unpack()
                sensors_timeline:delete{id}
        end
    end

    -- Collect data from IN sensors
    local sensors_data = {}
    for _, sensor in pairs(sensors) do
      local name = _
      local value = sensor:get_data()
      alert:alert(sensor:test_max(value))
      sensors_data[name] = value
    end

    sensors_timeline:auto_increment{ticks, sensors_data}

    ticks = ticks + 1
    fiber.sleep(1)
  end
  -- Work loop ]]
end

-- Start async
fiber.create(main_work)
