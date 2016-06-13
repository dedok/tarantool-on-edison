#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')

box.cfg{listen = '*:3301'}

box.once('give_rights', function()
  box.schema.user.grant('guest', 'read,write,execute', 'universe')
end)


tester = box.schema.space.create('tester', {if_not_exists = true})
tester:create_index('pk', {if_not_exists = true})

-- Setup replication
box.cfg{replication_source = '127.0.0.1:3302'}

fiber.create(function()
  while true do
    tester:auto_increment{1, {'master 1', 'insert', {this='line'}}}
    fiber.sleep(0.5)
  end
end)

fiber.create(function()
  while true do
    for _, tuple in pairs(tester:select{}) do
      print(require('yaml').encode(tuple))
      local id = tuple:unpack()
      tester:delete{id}
    end
    fiber.sleep(2)
  end
end)
