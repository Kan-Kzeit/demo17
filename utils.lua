local M = {}
local json = require("json")
local _defaultLocation = system.DocumentsDirectory
local _realDefaultLocation = _defaultLocation
local _validLocations = {
    [system.DocumentsDirectory] = true,
    [system.CachesDirectory] = true,
    [system.TemporaryDirectory] = true,
    [system.ResourceDirectory] = true
}


function M.createEmitter(path, mode)
    -- Read the exported Particle Designer file (JSON) into a string
    local filePath = system.pathForFile( path, system.ResourceDirectory)
    local f = io.open( filePath, "r" )
    local emitterData = f:read( "*a" )
    f:close()
    
    -- Decode the string
    local emitterParams = json.decode( emitterData )

    return emitterParams
end

---Save file *.json from table
---@param t table
---@param filename string
---@param location any
---@return boolean
function M.saveTable(t, filename, location)
    if location and (not _validLocations[location]) then
        error("Attempted to save a table to an invalid location", 2)
    elseif not location then
        location = _defaultLocation
    end

    local path = system.pathForFile(filename, location)
    local file = io.open(path, "w")
    if file then
        local contents = json.prettify(json.encode(t))
        file:write(contents)
        io.close(file)
        return true
    else
        return false
    end
end
---Read file *.json
---@param filename string
---@param location any
---@return table
function M.loadTable(filename, location)
    if location and (not _validLocations[location]) then
        error("Attempted to load a table from an invalid location", 2)
    elseif not location then
        location = _defaultLocation
    end
    
    local path = system.pathForFile(filename, location)
    
    local contents = ""
    local myTable = {}
    local file = io.open(path, "r")
    
    if file then
        -- read all contents of file into a string
        local contents = file:read("*a")
        myTable = json.decode(contents)
        io.close(file)
        return myTable
    else
        print("error loading " .. filename)
        return nil
    end
    return nil
end

function M.changeDefault(location)
    if location and (not location) then
        error("Attempted to change the default location to an invalid location", 2)
    elseif not location then
        location = _realDefaultLocation
    end
    _defaultLocation = location
    return true
end
---Checking file is available or not.
---@param filename string
---@param location any
---@return boolean
function M.isExists(filename, location)
    if location == nil then location = system.DocumentsDirectory end
    local path = system.pathForFile( filename, location )

    local f = io.open( path, "r" )

    if f then
        return true
    else
        return false
    end
end

function M.tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end

---print table with true format
---@param t table
function M.print_r(t)
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. tostring(t) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                        print(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end
    if (type(t) == "table") then
        print(tostring(t) .. " {")
        sub_print_r(t, "  ")
        print("}")
    else
        sub_print_r(t, "  ")
    end
    print()
end

function M.cleanTable(t)
    for i = #t, 1, -1 do
        table.remove(t, i)
    end

    return t
end

function M.shuffle( t, newTable )
	local target
    
	if newTable then
		target = {}
		for i = 1, #t do
			target[i] = t[i]
		end
	else
		target = t
	end

	for i = #target, 2, -1 do
		local j = math.random(i)
		target[i], target[j] = target[j], target[i]
	end

	return target
end

function M.sec2Min(sec)
    if sec <= 0 then return 0, 0 end
    if sec < 60 then return sec, 0 end

    return 
            math.fmod(sec, 60),
            math.floor(sec / 60) 
end

function M.min2Hour(min)
    if min <= 0 then return 0, 0 end
    if min < 60 then return min, 0 end

    return 
            math.fmod(min, 60),
            math.floor(min / 60)
end

function M.hour2Day(hour)
    if hour <= 0 then return 0, 0 end
    if hour < 24 then return hour, 0 end

    return 
            math.fmod(hour, 24),
            math.floor(hour / 24)
end

function M.sec2Time(sec)
    local s, m, h, d
    s, m = M.sec2Min(sec)
    m, h = M.min2Hour(m)
    h, d = M.hour2Day(h)

    return {
                day = d,
                hour = h,
                min = m,
                sec = s
            }
end

function M.formatNumber(num)
    if num >= 1000 then
        num = num / 1000
        if num >= 1000 then
            num = num / 1000
            if num >= 1000 then
                num = num / 1000
                if num >= 1000 then
                    num = num / 1000
                    return string.format("%.2f", num) .. "t"
                end
                return string.format("%.2f", num) .. "b"
            end
            return string.format("%.2f", num) .. "m"
        end
        return string.format("%.2f", num) .. "k"
    end
    return num
end

function M.round(number)
    if (number - (number % 0.1)) - (number - (number % 1)) < 0.5 then
      number = number - (number % 1)
    else
      number = (number - (number % 1)) + 1
    end
    return number
end

function M.rndNumbers(len, min, max, margin)
    local limit = 1000
    local cnt = 0
    local list = {}
    while cnt < len do
        local number = math.random(min, max)
        local isDuplicate = false
        
        for i = 1, #list do
            if list[i] == number or math.abs((list[i] - number)) <= margin then
                isDuplicate = true
            end
        end

        if not isDuplicate then
            list[#list+1] = number
            cnt = cnt + 1
        end
        limit = limit - 1
        if limit <= 0 then
     
            break
        end
    end
    return list
end

M.printTable = M.print_r

return M

-- local function getDeltaTime()
--     if lastUpdate == 0 then
--         dt = 0
--     else
--         dt = (system.getTimer( ) - lastUpdate) / 1000
--     end
--     lastUpdate = system.getTimer( )
--     return dt
-- end