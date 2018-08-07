-- TOML FILES
-- simple example
-- path = "./tests/simple.toml"
-- medium example
-- path = "./tests/medium.toml"
-- hard example
local path = "./tests/hard.toml"

-- LOAD LIBRARY
local toml = require("luatoml")

-- READ FILE CONTENT
local file = io.open(path, "r")
local content = file:read("*all")

-- CONVERT TOML FORMAT TO LUA OBJECT
local luaObj = toml.load(content)

-- JSON PRINT TO CONSOLE TO SEE WHAT OUR LUA OBJECT LOOKS LIKE
print(luaObj.the.hard.bit.what)