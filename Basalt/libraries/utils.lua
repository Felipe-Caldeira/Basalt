local sub, find, reverse, rep, insert, len, floor = string.sub, string.find, string.reverse, string.rep, table.insert, string.len, math.floor

local utils = {tHex = {}}

for i = 0, 15 do
    utils.tHex[2 ^ i] = ("%x"):format(i)
end

function utils.split(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        insert(result, match)
    end
    return result
end

function utils.removeTags(input)
    return input:gsub("{[^}]+}", "")
end

function utils.wrapText(str, width)
    str = utils.removeTags(str)
    local lines = {}
    local uniqueLines = utils.split(str, "\n")
    for _, v in pairs(uniqueLines) do
        if #v == 0 then
            table.insert(lines, "")
        else
            local words = utils.split(v, " ")
            local line = ""
            for _, word in ipairs(words) do
                if #line + #word > width then
                    table.insert(lines, line)
                    line = word
                else
                    if #line > 0 then
                        line = line .. " "
                    end
                    line = line .. word
                end
            end
            if #line > 0 then
                table.insert(lines, line)
            end
        end
    end
    return lines
end

function utils.deepcopy(orig, seen)
    seen = seen or {}
    if orig == nil then
        return nil
    end
    if type(orig) ~= 'table' then
        return orig
    end
    if seen[orig] then
        return seen[orig]
    end
    if orig.__noCopy then
        return orig
    end

    local copy = {}
    seen[orig] = copy
    for k, v in pairs(orig) do
        copy[utils.deepcopy(k, seen)] = utils.deepcopy(v, seen)
    end
    setmetatable(copy, utils.deepcopy(getmetatable(orig), seen))

    return copy
end

function utils.getCenteredPosition(text, totalWidth, totalHeight)
    local textLength = string.len(text)

    local x = floor((totalWidth - textLength + 1) / 2 + 0.5)
    local y = floor(totalHeight / 2 + 0.5)

    return x, y
end

function utils.subText(text, x, width)
    if (x + #text < 1) or (x > width) then
        return ""
    end
    if x < 1 then
        if (x == 0) then
            text = sub(text, 2)
        else
            text = sub(text, 1 - x)
        end
        x = 1
    end
    if x + #text - 1 > width then
        text = sub(text, 1, width - x + 1)
    end
    return text, x
end

function utils.orderedTable(t)
    local newTable = {}
    for _, v in pairs(t) do
        newTable[#newTable + 1] = v
    end
    return newTable
end

function utils.rpairs(t)
    return function(t, i)
        i = i - 1
        if i ~= 0 then
            return i, t[i]
        end
    end, t, #t + 1
end

function utils.tableCount(t)
    local n = 0
    if (t ~= nil) then
        for _, _ in pairs(t) do
            n = n + 1
        end
    end
    return n
end

--- Returns a random UUID.
--- @return string UUID.
function utils.uuid()
    return string.gsub(string.format('%x-%x-%x-%x-%x', math.random(0, 0xffff), math.random(0, 0xffff),
        math.random(0, 0xffff), math.random(0, 0x0fff) + 0x4000, math.random(0, 0x3fff) + 0x8000), ' ', '0')
end

return utils
