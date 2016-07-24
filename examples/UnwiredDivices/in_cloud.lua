-- Includes
local fiber = require('fiber')

box.cfg{listen = '*:3301'}

box.once('give_rights', function()
  box.schema.user.grant('guest', 'read,write,execute', 'universe')
end)

-- create table
msgs = box.schema.space.create('msgs', {if_not_exists = true})
msgs:create_index('pk', {if_not_exists = true})

-- Setup replication
box.cfg{replication_source = '127.0.0.1:3302'}

-- Work - get new messages
fiber.create(function()
  while true do
    for _, tuple in pairs(msgs:select{}) do
      print(require('yaml').encode(tuple))
      local id = tuple:unpack()
      tester:delete{id}
    end
    fiber.sleep(2)
  end
end)
