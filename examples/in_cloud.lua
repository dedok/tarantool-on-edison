#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local log = require('log')
local yaml = require('yaml')

-- Init Tarantool
box.cfg {
  listen = '*:3301',
  log_level = 3,
  wal_mode = 'write'
}

box.once('give_rights', function()
  box.schema.user.grant('guest', 'read,write,execute', 'universe')
end)

-- Devices object
local devices = { list = {} }

-- Add spaces. Each device have own space for brotcast messages to cloud
function devices.add_device(self, device_name)

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

  self.list[device_name] = {
    settings = settings,
    sensors_timeline = sensors_timeline
  }

  return self.add_device
end

function devices.init_once(self)
  -- Add devices
  self:add_device('edison_1')

  -- Setup replication
  box.cfg {
    -- FIXME Add here your hosts
    replication_source = { '192.168.1.45:3301' }--, '192.168.1.45:3301'}
  }
end

-- API
function devices.get_device_data(self, device)
  local settings = device.settings
  local sensors_timeline = device.sensors_timeline

  local series, result = {}, {}

  -- Series, note: sensors_timeline is ordered by ticks
  for _, tuple in pairs(sensors_timeline:select{}) do
    local id, ticks, sensors = tuple:unpack()
    for sensor_name, value in pairs(sensors) do
      if series[sensor_name] == nil then
        series[sensor_name] = {}
      end
      table.insert(series[sensor_name], value)
    end
  end

  -- Join sensors on settings on sensor_name
  for sensor_name, series in pairs(series) do
    local _, setting = settings:get{sensor_name}:unpack()
    table.insert(result, {
      sensor_name = sensor_name,
      name = settings.name,
      measure = settings.measure,
      max = settings.max,
      alarm = settings.alarm,
      series = series
    })
  end

  return result
end

function api_list()
  local result = {}
  for device_name, device in pairs(devices.list) do
    table.insert(result, {
      device_name = device_name,
      list = devices:get_device_data(device)
    })
  end
  return result
end

function api_get(device_name)
  local device = devices.list[device_name]
  if device then
    return get_device_data(device)
  end
  return {}
end

function api_set(device_name, sensor_name, new_setting)
  local device = devices.list[device_name]
  if device and
    -- validate new setting
    new_setting.max
  then
    local _, setting = device.setting:get{sensor_name}:unpack()
    if setting then
      -- merge & replace
      setting.max = new_setting.max
      device.settings:replace{sensor_name, setting}
      return {true}
    end
  end
  return {false}
end

-- Start
devices:init_once()

fiber.create(function()
  -- Cloud work helpers
  local function dump_space(space)
    for _, tuple in pairs(space:select()) do
      log.error(yaml.encode(tuple))
    end
  end

  -- Loop over devices
  while true do
    for _, device in pairs(devices.list) do
      -- Just for test [[
      dump_space(device.settings)
      dump_space(device.sensors_timeline)
      -- ]]
    end
    fiber.sleep(1)
  end
end)
