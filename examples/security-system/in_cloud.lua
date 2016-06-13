#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local log = require('log')
local yaml = require('yaml')

-- Init Tarantool [[
box.cfg {
  listen = '*:3301',
  log_level = 5,
  wal_mode = 'write'
}

box.once('give_rights', function()
  box.schema.user.grant('guest', 'read,write,execute', 'universe')
end)
-- ]]

-- Devices object
local devices = { list = {} }

-- Add device.
-- Each device have own spaces:
--   device_name + '_settings' - store & exchange settings
--   device_name + '_sensors_timeline' - store & exchange sensors data
--
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

-- Init devices.
-- new_devices - {
--  name = STR               - uniq device name
--  replication_source = STR - device host, for master-master replication
-- }
--
function devices.init_once(self, new_devices)
  local replication_source = {}

  -- Add devices
  for _, device in pairs(new_devices) do
    self:add_device(device.name)
    table.insert(replication_source, device.replication_source)
  end

  -- Setup replication
  box.cfg{replication_source = replication_source}
end

--
-- Public API [[
--
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
      sensor_name = setting.sensor_name,
      name = setting.comment,
      measure = setting.measure,
      max = setting.max,
      alarm = setting.alarm,
      series = series
    })
  end

  return result
end

local Api = {}

function Api.list(self)
  local list = {}
  for device_name, device in pairs(devices.list) do
    table.insert(list, {
      device_name = device_name,
      data = devices:get_device_data(device)
    })
  end
  return {list=list}
end

function Api.set(self, device_name, sensor_name, new_setting)
  local device = devices.list[device_name]
  if device and
    -- validate new setting
    new_setting.max
  then
    local settings = device.settings
    local _, setting = settings:get{sensor_name}:unpack()
    if setting then
      -- merge & replace
      setting.max = new_setting.max
      settings:replace{sensor_name, setting}
      return {{result=true}}
    end
  end
  return {{result=false}}
end

function Api.get(self, device_name)
  if device_name then
    local device = devices.list[device_name]
    if device then
      return {
        device_name = device_name,
        data = devices:get_device_data(device)
      }
    end
  end
  return {{result=false}}
end

-- Http - Rest
function api(http_request, ...)
  local method = http_request.uri
  if string.find(method, '/api/get', 1) == 1 then
    return Api:get(http_request.args.name)
  elseif string.find(method, '/api/list', 1) == 1 then
    return Api:list()
  elseif string.find(method, '/api/set', 1) == 1 then
    return Api:set(...)
  end
  return {{result=false}}
end
--
-- ]]
--

-- Setup devices then start
devices:init_once({
  {
    name = 'edison_1',
    replication_source = '192.168.1.45:3301'
  }
})

fiber.create(function()
  -- Cloud work helpers
  local function dump_space(space)
    for _, tuple in pairs(space:select()) do
      log.error(yaml.encode(tuple))
    end
  end

  local debug = true
  -- Loop over devices
  while true do
    if debug then
      log.error('=============================')
      log.error('Debug:')
      for _, device in pairs(devices.list) do
        -- Just for test [[
        dump_space(device.settings)
        dump_space(device.sensors_timeline)
        -- ]]
      end
      log.error('~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
      log.error('')
    end
    fiber.sleep(1)
  end
end)
