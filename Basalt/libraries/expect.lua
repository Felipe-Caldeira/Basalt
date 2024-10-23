local expect = {}

local function coloredPrint(message, color)
    term.setTextColor(color)
    print(message)
    term.setTextColor(colors.white)
end

local function _expect(argument, ...)
    local types = {...}
    local valid = false

    local function checkType(arg, expected)
        if type(arg) == expected then
            valid = true
            return true
        elseif expected == "color" then
            if type(arg) == "string" and colors[arg] then
                valid = true
                return true
            elseif type(arg) == "number" then
                for _, v in pairs(colors) do
                    if v == arg then
                        valid = true
                        return true
                    end
                end
            end
        elseif expected == "dynValue" then
            if type(arg) == "string" and arg:sub(1, 1) == "{" and arg:sub(-1) == "}" then
                valid = true
                return true
            end
        elseif type(arg) == "table" and arg.isType ~= nil then
            for _, expectedType in ipairs(types) do
                if arg:isType(expectedType) then
                    valid = true
                    return true
                end
            end
        end
        return false
    end

    for _, expectedType in ipairs(types) do
        if type(expectedType) == "table" then
            for _, v in ipairs(expectedType) do
                if checkType(argument, v) then
                    break
                end
            end
        elseif checkType(argument, expectedType) then
            break
        end
    end

    if not valid then
        local traceback = debug.traceback()
        local location, lineNumber, functionName
        local lines = {}
        for line in traceback:gmatch("[^\n]+") do
            lines[#lines + 1] = line
        end
        if #lines >= 2 then
            local lastFunctionLine = lines[#lines - 1]
            functionName = lastFunctionLine:match("^.-:.-: in function '([^']+)'$")
        end
        if not functionName then
            functionName = "Unknown function"
        end
        location, lineNumber = traceback:match("\n([^\n]+):(%d+): in main chunk$")
        if location and lineNumber then
            local file = fs.open(location, "r")
            if file then
                local lineContent = ""
                local currentLineNumber = 1
                repeat
                    lineContent = file.readLine()
                    if currentLineNumber == tonumber(lineNumber) then
                        coloredPrint("\149Line " .. lineNumber, colors.cyan)
                        coloredPrint(lineContent, colors.lightGray)
                        break
                    end
                    currentLineNumber = currentLineNumber + 1
                until not lineContent
                file.close()
            end
        else
            location = "Unknown location"
            lineNumber = "Unknown line"
        end
        return location, lineNumber, functionName, traceback
    end
    return true
end

function expect.expect(position, argument, ...)
    if (position == nil) then
        position = 1
    end
    if (argument == nil) then
        return
    end
    local types = {...}
    local location, lineNumber, functionName, traceback = _expect(argument, ...)
    if (location ~= true) then
        local fileName = location:gsub("^%s+", "")
        if (expect.basalt ~= nil) then
            expect.basalt.stop()
        end
        coloredPrint("Basalt Initialization Error:", colors.red)
        print(traceback)
        print()
        if (location:sub(1, 1) == "/") then
            fileName = location:sub(2)
        end

        term.setTextColor(colors.red)
        term.write("Error in ")
        term.setTextColor(colors.white)
        term.write(fileName:gsub("/", ""))
        term.setTextColor(colors.red)
        term.write(":")
        term.setTextColor(colors.lightBlue)
        term.write(lineNumber)
        term.setTextColor(colors.red)
        term.write(": ")
        coloredPrint("Invalid argument in function '" .. functionName .. ":" .. position .. "'. Expected " ..
                         table.concat(types, ", ") .. ", got " .. type(argument), colors.red)
        local file = fs.open(location:gsub("^%s+", ""), "r")
        if file then
            print()
            local lineContent = ""
            local currentLineNumber = 1
            repeat
                lineContent = file.readLine()
                if currentLineNumber == tonumber(lineNumber) then
                    coloredPrint("\149Line " .. lineNumber, colors.cyan)
                    coloredPrint("  " .. lineContent, colors.lightGray)
                    break
                end
                currentLineNumber = currentLineNumber + 1
            until not lineContent
            file.close()
        else
            error("Unable to open file " .. location:gsub("^%s+", "") .. ".")
        end
        -- error()
        return false
    end
    return true
end

function expect.getExpectData(...)
    return _expect(...)
end

return expect
