#!/usr/bin/env tarantool

-- Includes
local fiber = require('fiber')
local log = require('log')
local yaml = require('yaml')

box.cfg{}

--
-- Create space & index
--

-- SQL Analogue:
-- CREATE TABLE tester(first_col, second_col, ...)
tester = box.schema.space.create('tester', {if_not_exists = true})

tester = box.space.tester

-- SQL Analogue:
-- CREATE INDEX pk ON tester(first_col)
tester:create_index('pk', {if_not_exists = true})

-- SQL Analogue:
-- CREATE INDEX pk ON tester(second_col)
tester:create_index('name', {
  if_not_exists = true,
  unique = false,
  parts = {2, 'STR'}
})

-- Full SQL Analogue:
--
-- CREATE TABLE tester(
--  first_col BIGINT,
--  second_col TEXT,
--  ...
--
--  PRIMARY KEY first_col
-- )
--
-- CREATE INDEX name ON tester(second_col)
--

-- SQL Analogue:
-- REPLACE INTO tester(first_col, second_col) VALUES(1, 'Mr. Simons', ...)
tester:replace{1, 'Mr. Simons', {salary = 10000, currency = '$', age = 30}}
tester:auto_increment{'Mr. Simons', {salary = 20000, age = 40}}

-- SQL Analogue:
-- SELECT * FROM tester WHERE pk = 1
res = tester:select{1}
print(yaml.encode(res))

-- SQL Analogue:
-- SELECT * FROM tester WHERE name = 'Mr. Simons'
res = tester.index.name:select{'Mr. Simons'}
print(yaml.encode(res))

--
-- Tarantool fibers
--
fiber.create(function()
  while true do
    print('first fiber - this message each second until ^C')
    fiber.sleep(1)
  end
end)

fiber.create(function()
  local count = 0
  while count ~= 10 do
    -- XXX better use log, not print
    log.error('print this message 10 time')
    fiber.yield()
    count = count + 1
  end
end)
