-- TOML FILES
-- simple example
-- path = "./tests/simple.toml"
-- medium example
-- path = "./tests/medium.toml"
-- hard example
local path = "./tests/ecg.toml"

-- LOAD LIBRARY
local toml = require("luatoml")

-- READ FILE CONTENT
local file = io.open(path, "r")
local content = file:read("*all")

-- CONVERT TOML FORMAT TO LUA OBJECT
local luaObj = toml.load(content)

-- JSON PRINT TO CONSOLE TO SEE WHAT OUR LUA OBJECT LOOKS LIKE
local indent = -2
local function print_table(t)
  indent = indent + 2
  for k, v in pairs(t) do
    if type(v) == "table" then
      for i = 1, indent, 1 do
        io.write(" ")
      end
      io.write(string.format("table: %s\n", k))
      print_table(v)
      for i = 1, indent, 1 do
        io.write(" ")
      end
      io.write(string.format("end of table: %s\n", k))
    else
      for i = 1, indent, 1 do
        io.write(" ")
      end
      io.write(string.format("%s = %s\n", k, v))
    end
  end
  indent = indent - 2
end

print_table(luaObj)