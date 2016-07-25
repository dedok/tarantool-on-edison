#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')

box.cfg{
  slab_alloc_arena = 0.1,
  listen = '*:3301'
}

box.once('give_rights', function()
  box.schema.user.grant('guest', 'read,write,execute', 'universe')
end)

-- create table
msgs = box.schema.space.create('msgs', {if_not_exists = true})
msgs:create_index('pk', {if_not_exists = true})

-- Setup replication
box.cfg{
  replication_source = '192.168.1.47:3301'
}

-- Work - get new messages
fiber.create(function()
  while true do
    print(require('yaml').encode(msgs:select{}))
    fiber.sleep(2)
  end
end)
