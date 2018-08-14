-- 二零一八年八月七日
-- 本程序实现了对 toml 的解析与对 lua 表的 toml 化

local _mod = {
	load;
	-- lua_table load(toml_string);

	dump;
	-- toml_string dump(lua_table)
}

local strip
-- strip 函数去除字符串 str 的首尾空白字符（space character）并返回去除后的结果

local replace_char
-- replace_char 函数替换字符串 str 中指定位置 pos 处的字符为字符 r

local split_line_2_group_array
-- split_line_2_group_array 函数将一行文本以点（.）为界切割为数个字符串
-- 返回为一个序列

local table_size
-- table_size 函数返回表 table 中成员的数量

local split_line
-- split_line 函数疑似分析一行文本的主函数，返回格式化的字符串

local split_assignment
-- split_assignment 函数拆分一个键值对并返回

local load_value
-- load_value 函数返回一个 TOML 中的值 v 与其类型名称的表

local load_array
-- load_array 函数返回一个 TOML 中的序列 a 在 Lua 中的序列表示

local dump_value
-- dump_value 函数将一个 Lua 的值序列化为一个 TOML 的值

local dump_section
-- dump_section 函数将一个 Lua 表序列化为一个 TOML 的部分

function strip(str)
	return string.format("%s", str:match("^%s*(.-)%s*$"))
end

function replace_char(pos, str, r)
	return ("%s%s%s"):format(str:sub(1, pos - 1), r, str:sub(pos + 1))
end

function split_line_2_group_array(line)
	local retVal = {}
	local i = 1
	for group in string.gmatch(line, "[^%.]+") do
		retVal[i] = group
		i = i + 1
	end
	return retVal
end

function table_size(table)
	local size = 0
	for _, _ in pairs(table) do
		size = size + 1
	end
	return size
end

function split_line(str)
	local openArr = 0
	local openString = false
	local beginLine = true
	local keyGroup = false

	for i = 1, #str do
		local char = string.sub(str, i, i)

		if char == '"' and string.sub(str, i - 1, i - 1) ~= "\\" then
			openString = not openString
		end

		if keyGroup and (char == " " or char == "\t") then
			keyGroup = false
		end

		if char == "#" and not openString and not keyGroup then
			local j = i
			while string.sub(str, j, j) ~= "\n" do
				str = replace_char(j, str, " ")
				j = j + 1
			end
		end

		if char == "[" and not openString and not keyGroup then
			if beginLine then
				keyGroup = true
			else
				openArr = openArr + 1
			end
		end

		if char == "]" and not openString and not keyGroup then
			if keyGroup then
				keyGroup = false
			else
				openArr = openArr - 1
			end
		end

		if char == "\n" then
			if openString then
				error("unbalanced quotes")
			end
			if openArr ~= 0 then
				str = replace_char(i, str, " ")
			else
				beginLine = true
			end
		elseif beginLine and char ~= " " and char ~= "\t" then
			beginLine = false
			keyGroup = true
		end
	end -- end of for loop
	return str
end

function split_assignment(str)
	local retVal = {}
	local i = 1
	for group in string.gmatch(str, "[^=]+") do
		retVal[i] = group
		i = i + 1
	end
	return retVal
end

function load_value(v)
	if v == "true" then
		-- boolean
		return {value = true, type = "boolean"}
	elseif v == "false" then
		-- boolean
		return {value = false, type = "boolean"}
	elseif string.sub(v, 1, 1) == '"' then
		-- string, handle simple string for now
		local lengthV = string.len(v)
		local str = string.sub(v, 2, lengthV - 1)
		return {value = str, type = "string"}
	elseif string.sub(v, 1, 1) == "[" then
		-- array
		return {value = load_array(v), type = "table"}
	elseif string.len(v) == 20 and string.sub(v, 20, 20) == "Z" then
		-- datetime, handle as string for now
		local lengthV = string.len(v)
		local str = string.sub(v, 1, lengthV - 1)
		return {value = str, type = "string"}
	else
		-- number
		local negative = false
		if string.sub(v, 1, 1) == "-" then
			negative = true
			local lengthV = string.len(v)
			v = string.sub(v, 2, lengthV)
		end
		v = tonumber(v)
		if negative then
			v = 0 - v
		end
		return {value = v, type = "number"}
	end
end

function load_array(a)
	local retVal = {}
	a = string.format("%s", a:match("^%s*(.-)%s*$"))
	a = string.sub(a, 2, #a - 1)
	local newArr = {}
	local openArr = 0
	local j = 1
	local index = 1
	for i = 1, #a do
		local char = string.sub(a, i, i)
		if char == "[" then
			openArr = openArr + 1
		elseif char == "]" then
			openArr = openArr - 1
		elseif char == "," and openArr == 0 then
			local subStr = string.sub(a, j, i - 1)
			subStr = string.format("%s", subStr:match("^%s*(.-)%s*$"))
			newArr[index] = subStr
			j = i + 1
			index = index + 1
		end
	end
	local subStr = string.sub(a, j, #a)
	subStr = string.format("%s", subStr:match("^%s*(.-)%s*$"))
	newArr[index] = subStr

	local aType = nil
	index = 1
	for _, v in ipairs(newArr) do
		if v ~= "" then
			local loadedVal = load_value(v)
			local nVal = loadedVal["value"]
			local nType = loadedVal["type"]
			if aType then
				if aType ~= nType then
					error("Not homogeneous array")
				end
			else
				aType = nType
			end
			retVal[index] = nVal
			index = index + 1
		end
	end
	return retVal
end

function dump_value(v)
	if type(v) == "string" then
		local retStr = '"' .. v .. '"'
		return retStr
	elseif type(v) == "boolean" then
		return tostring(v)
	else
		return v
	end
end

function dump_section(obj)
	local retStr = ""
	local retDict = {}
	for i, _ in pairs(obj) do
		if type(obj[i]) ~= "table" then
			retStr = retStr .. i .. " = "
			retStr = retStr .. dump_value(obj[i]) .. "\n"
		else
			retDict[i] = obj[i]
		end
	end
	return {retStr = retStr, retDict = retDict}
end

function _mod.load(str)
	local implicitGroups = {}
	local retVal = {}
	local currentLevel = retVal
	str = split_line(str)
	for line in string.gmatch(str, "[^\n]+") do
		line = strip(line)
		if string.sub(line, 1, 1) == "[" then
			if string.sub(line, 2, 2) ~= "[" then -- 支持表序列
				line = string.sub(line, 2, #line - 1) -- key group name 非表序列
				currentLevel = retVal
				local groups = split_line_2_group_array(line)
				for i, group in ipairs(groups) do
					if group == "" then
						error("Can't have keygroup with empty name")
					end

					if currentLevel[group] ~= nil then
						if i == table_size(groups) then
							if implicitGroups[group] ~= nil then
								implicitGroups[group] = nil
							else
								error("Group existed")
							end
						end
					else
						if i ~= table_size(groups) then
							implicitGroups[group] = true
						end
						currentLevel[group] = {}
					end

					if #currentLevel[group] == 0 then
						currentLevel = currentLevel[group]
					else
						currentLevel = currentLevel[group][#currentLevel[group]]
					end
				end -- end of for inner loop
			else -- 支持表序列
				line = string.sub(line, 3, #line - 2) -- 表序列
				currentLevel = retVal
				local groups = split_line_2_group_array(line)
				local new_table = {}
				for i, group in ipairs(groups) do
					if group == "" then
						error("Can't have keygroup with empty name")
					end

					if currentLevel[group] ~= nil then
						if i == table_size(groups) then
							-- 序列已存在
							table.insert(currentLevel[group], new_table)
						end
					else
						-- 序列不存在（第一个）
						currentLevel[group] = {}
						table.insert(currentLevel[group], new_table)
					end

					if i ~= table_size(groups) then
						if #currentLevel[group] == 0 then
							currentLevel = currentLevel[group]
						else
							currentLevel = currentLevel[group][#currentLevel[group]]
						end
					else
						currentLevel = new_table
					end
				end  -- end of for loop
			end
		elseif line:match("=") ~= nil then
			local assignment = split_assignment(line)
			local variable = strip(assignment[1])
			local value = strip(assignment[2])
			local loadedVal = load_value(value)
			value = loadedVal["value"]
			if currentLevel[variable] ~= nil then
				error("Duplicated key")
			else
				currentLevel[variable] = value
			end
		end
	end -- end of outer for loop
	return retVal
end

function _mod.dump(obj)
	local addToSections
	local retVal = ""
	local dumpedSection = dump_section(obj)
	local addToRetVal = dumpedSection["retStr"]
	local sections = dumpedSection["retDict"]
	retVal = retVal .. addToRetVal

	while table_size(sections) ~= 0 do
		local newSections = {}
		for section, _ in pairs(sections) do
			dumpedSection = dump_section(sections[section])
			addToRetVal = dumpedSection["retStr"]
			addToSections = dumpedSection["retDict"]
			if addToRetVal ~= nil then
				retVal = retVal .. "[" .. section .. "]\n"
				retVal = retVal .. addToRetVal
			end
			for s, _ in pairs(addToSections) do
				newSections[section .. "." .. s] = addToSections[s]
			end
		end
		sections = newSections
	end
	return retVal
end

_ENV[...] = _mod
package.loaded[...] = _mod
