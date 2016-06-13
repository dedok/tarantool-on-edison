#!/usr/bin/env tarantool

local fiber = require('fiber')

box.cfg{replication_source = __HOST__}

fiber.create(function()
  local tester = box.space.tester
  while true do
    tester:auto_increment{'also', {'master 2', 'insert', {this='line'}}}
    fiber.sleep(0.5)
  end
end)

