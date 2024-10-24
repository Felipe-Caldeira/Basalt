local args = {...}
local basaltPath = args[1] or ".basalt"

local defaultPath = package.path
local format = "path;/path/?.lua;/path/?/init.lua;"
local main = format:gsub("path", basaltPath)
local eleFolder = format:gsub("path", basaltPath .. "/elements")
local extFolder = format:gsub("path", basaltPath .. "/extensions")
local libFolder = format:gsub("path", basaltPath .. "/libraries")
local expectLib = require("expect")
local expect = expectLib.expect
package.path = main .. eleFolder .. extFolder .. libFolder .. defaultPath

local loader = require("basaltLoader")
local utils = require("utils")
local log = require("log")

--- The Basalt Core API
--- @class Basalt
local basalt = {
    traceback = true,
    log = log,
    extensionExists = loader.extensionExists
}

local threads = {}
local updaterActive = false
local mainFrame, focusedFrame, frames, monFrames = nil, nil, {}, {}
local baseTerm = term.current()
local registeredEvents = {}
local keysDown, mouseDown = {}, {}
loader.setBasalt(basalt)
expectLib.basalt = basalt

---- Frame Rendering
local function drawFrames()
    if (updaterActive == false) then
        return
    end
    if (mainFrame ~= nil) then
        mainFrame:processRender()
    end
    for _, v in pairs(monFrames) do
        v:processRender()
    end
end

---- Event Handling
local throttle = {
    mouse_drag = 0.05,
    mouse_move = 0.05
}
local lastEventTimes = {}
local lastEventArgs = {}

local events = {
    mouse = {
        mouse_click = true,
        mouse_up = true,
        mouse_drag = true,
        mouse_scroll = true,
        mouse_move = true,
        monitor_touch = true
    },
    keyboard = {
        key = true,
        key_up = true,
        char = true
    }
}
local function updateEvent(event, ...)
    local p = {...}
    if (event == "terminate") then
        basalt.stop()
    end
    if (event == "mouse_move") then
        if (p[1] == nil) or (p[2] == nil) then
            return
        end
    end

    for _, v in pairs(registeredEvents) do
        if (v == event) then
            if not v(event, unpack(p)) then
                return
            end
        end
    end

    if event == "timer" then
        for k, v in pairs(lastEventTimes) do
            if v == p[1] then
                if mainFrame ~= nil and mainFrame[k] ~= nil then
                    mainFrame[k](mainFrame, unpack(lastEventArgs[k]))
                end
                for _, b in pairs(monFrames) do
                    if b[k] ~= nil then
                        b[k](b, unpack(lastEventArgs[k]))
                    end
                end
                lastEventTimes[k] = nil
                lastEventArgs[k] = nil
                drawFrames()
                return
            end
        end
    end

    if throttle[event] ~= nil and throttle[event] > 0 then
        if lastEventTimes[event] == nil then
            lastEventTimes[event] = os.startTimer(throttle[event])
        end
        lastEventArgs[event] = p
        return
    else
        if (event == "key") then
            keysDown[p[1]] = true
        end
        if (event == "key_up") then
            keysDown[p[1]] = false
        end
        if (event == "mouse_click") then
            mouseDown[p[1]] = true
        end
        if (event == "mouse_up") then
            mouseDown[p[1]] = false
            if mainFrame ~= nil and mainFrame.mouse_release ~= nil then
                mainFrame.mouse_release(mainFrame, unpack(p))
            end
        end
        if (events.mouse[event]) then
            if (event == "monitor_touch") then
                for _, v in pairs(monFrames) do
                    if v[event] ~= nil then
                        v[event](v, unpack(p))
                    end
                end
            else
                if mainFrame ~= nil and mainFrame.event ~= nil then
                    mainFrame[event](mainFrame, unpack(p))
                end
            end
        elseif (events.keyboard[event]) then
            if focusedFrame ~= nil and focusedFrame[event] ~= nil then
                focusedFrame[event](focusedFrame, unpack(p))
            end
        else
            for _, v in pairs(frames) do
                if (v.event ~= nil) then
                    v.event(v, event, unpack(p))
                end
            end
            for _, v in pairs(monFrames) do
                if v[event] ~= nil then
                    v[event](v, event, unpack(p))
                end
            end
        end
        if (#threads > 0) then
            for k, v in pairs(threads) do
                if (coroutine.status(v.thread) == "dead") then
                    table.remove(threads, k)
                else
                    if (v.filter ~= nil) then
                        if (event ~= v.filter) then
                            drawFrames()
                            return
                        end
                        v.filter = nil
                    end
                    local ok, filter = coroutine.resume(v.thread, event, ...)
                    if (ok) then
                        v.filter = filter
                    else
                        basalt.errorHandler(filter)
                    end
                end
            end
        end
        drawFrames()
    end
end

local function getFrame(id)
    for _, v in pairs(frames) do
        if (v:getId() == id) then
            return v
        end
    end
end

local function getMonitor(id)
    for _, v in pairs(monFrames) do
        if (v:getId() == id) then
            return v
        end
    end
end

--- Tells basalt to require a specific element, if not found it will download it from github
--- @param ... string -- The element name to require
function basalt.requiredElement(...)
    local elements = {...}
    expect(1, elements[1], "string")
    local parallelAcccess = {}
    local slTimer = 0
    for _, v in pairs(elements) do
        table.insert(parallelAcccess, function()
            local delay = slTimer
            sleep(delay)
            loader.require("element", v)
        end)
        slTimer = slTimer + 0.1
    end
    parallel.waitForAll(unpack(parallelAcccess))
end

--- Tells basalt to require a specific extension, if not found it will download it from github
--- @param ... string -- The extension name to require
function basalt.requiredExtension(...)
    local extensions = {...}
    expect(1, extensions[1], "string")
    local parallelAcccess = {}
    local slTimer = 0
    for _, v in pairs(extensions) do
        table.insert(parallelAcccess, function()
            local delay = slTimer
            sleep(delay)
            loader.require("extension", v)
        end)
        slTimer = slTimer + 0.1
    end
    parallel.waitForAll(unpack(parallelAcccess))
end

--- Returns a list of all frames
--- @return table
function basalt.getFrames()
    return frames
end

--- Checks if a key is currently pressed
--- @param key number -- Use the key codes from the `keys` table, example: `keys.enter`
--- @return boolean
function basalt.isKeyDown(key)
    expect(1, key, keys)
    return keysDown[key] or false
end

--- Checks if a mouse button is currently pressed
--- @param button number -- Use the button numbers: 1, 2, 3, 4 or 5
--- @return boolean
function basalt.isMouseDown(button)
    expect(1, button, {1, 2, 3, 4})
    return mouseDown[button] or false
end

--- Returns the current main active main frame, if it doesn't exist it will create one
--- @return BaseFrame
function basalt.getMainFrame()
    if (mainFrame == nil) then
        mainFrame = basalt.addFrame("mainFrame")
        basalt.setFocusedFrame(mainFrame)
    end
    return mainFrame
end

--- Creates a new frame, if main frame doesn't exist it will be set to the new frame.
--- @param id? string -- The id of the frame
--- @return BaseFrame
function basalt.addFrame(id)
    expect(1, id, "string", "nil")
    if (mainFrame == nil) then
        id = id or "mainFrame"
    end
    id = id or utils.uuid()
    local frame = loader.load("BaseFrame"):new(id, nil, basalt)
    frame:init()
    if (mainFrame == nil) then
        mainFrame = frame
        basalt.setFocusedFrame(mainFrame)
    end
    table.insert(frames, frame)
    return frame
end

--- Removes a frame from the frame list
--- @param frame string|BaseFrame -- The frame to remove
--- @return boolean
function basalt.removeFrame(frame)
    expect(1, frame, "string", "BaseFrame")
    if (type(frame) == "string") then
        frame = getFrame(id)
    end
    if (mainFrame == frame) then
        mainFrame = nil
        term.clear()
    end
    for k, v in pairs(frames) do
        if (v == frame) then
            table.remove(frames, k)
            return true
        end
    end
    return false
end

--- Switches the main frame to a new frame
--- @param frame BaseFrame -- The frame to switch to
function basalt.switchFrame(frame)
    expect(1, frame, "string", "BaseFrame")
    if (type(frame) == "string") then
        frame = getFrame(frame)
    end
    mainFrame = frame
    frame:forceRender()
    basalt.setFocusedFrame(frame)
end

--- Creates a new monitor frame
--- @param id? string -- The id of the monitor
--- @return Monitor
function basalt.addMonitor(id)
    expect(1, id, "string", "Monitor")
    id = id or utils.uuid()
    local frame = loader.load("Monitor"):new(id, nil, basalt)
    frame:init()
    table.insert(monFrames, frame)
    return frame
end

--- Removes a monitor/BigMonitor from the monitor list
--- @param frame string|Monitor|BigMonitor -- The monitor to remove
function basalt.removeMonitor(frame)
    expect(1, frame, "string", "Monitor", "BigMonitor")
    if (type(frame) == "string") then
        frame = getMonitor(frame)
    end
    for k, v in pairs(monFrames) do
        if (v == frame) then
            table.remove(monFrames, k)
            return
        end
    end
end

--- Creates a new big monitor frame
--- @param id? string -- The id of the big monitor
--- @return BigMonitor
function basalt.addBigMonitor(id)
    expect(1, id, "string", "BigMonitor")
    id = id or utils.uuid()
    local frame = loader.load("BigMonitor"):new(id, nil, basalt)
    frame:init()
    table.insert(monFrames, frame)
    return frame
end

--- Creates a new element
--- @param id string -- The id of the element
--- @param parent Container|nil -- The parent frame of the element
--- @param typ string -- The type of the element
--- @param defaultProperties? table -- The default properties of the element
--- @return BasicElement
function basalt.create(id, parent, typ, defaultProperties)
    expect(1, id, "string")
    expect(2, parent, "nil", "Container")
    expect(3, typ, "string")
    expect(4, defaultProperties, "table", "nil")
    local l = loader.load(typ)
    if (type(l) == "string") then
        l = load(l, nil, "t", _ENV)()
    end
    local element = l:new(id, parent, basalt)
    if (defaultProperties ~= nil) then
        for k, v in pairs(defaultProperties) do
            local fName = "set" .. k:sub(1, 1):upper() .. k:sub(2)
            if (element[fName] ~= nil) then
                element[fName](element, v)
            else
                element[k] = v
            end
        end
    end
    return element
end

local function coloredPrint(message, color)
    term.setTextColor(color)
    print(message)
    term.setTextColor(colors.white)
end

--- The error Handler which is used by basalt when errors happen. Can be overwritten
--- @param errMsg string -- The error message
function basalt.errorHandler(errMsg)
    basalt.stop()
    term.setBackgroundColor(colors.black)

    term.clear()
    term.setCursorPos(1, 1)

    coloredPrint("Basalt Runtime Error:", colors.red)
    print()

    local fileName, lineNumber, errorMessage = string.match(errMsg, "(.-):(%d+):%s(.*)")

    if (basalt.traceback) then
        local stackTrace = string.match(errMsg, "stack traceback:(.*)")
        if stackTrace then
            coloredPrint("Stack traceback:", colors.gray)
            for line in stackTrace:gmatch("[^\n]+") do
                local fileNameInTraceback, lineNumberInTraceback = line:match("([^:]+):(%d+):")
                if fileNameInTraceback and lineNumberInTraceback then
                    term.setTextColor(colors.lightGray)
                    term.write(fileNameInTraceback)
                    term.setTextColor(colors.gray)
                    term.write(":")
                    term.setTextColor(colors.lightBlue)
                    term.write(lineNumberInTraceback)
                    term.setTextColor(colors.gray)
                    line = line:gsub(fileNameInTraceback .. ":" .. lineNumberInTraceback, "")
                end
                coloredPrint(line, colors.gray)
            end
            print()
        end
    end

    if fileName and lineNumber then
        term.setTextColor(colors.red)
        term.write("Error in ")
        term.setTextColor(colors.white)
        term.write(fileName)
        term.setTextColor(colors.red)
        term.write(":")
        term.setTextColor(colors.lightBlue)
        term.write(lineNumber)
        term.setTextColor(colors.red)
        term.write(": ")

        if errorMessage then
            errorMessage = string.gsub(errorMessage, "stack traceback:.*", "")
            if errorMessage ~= "" then
                coloredPrint(errorMessage, colors.red)
            else
                coloredPrint("Error message not available", colors.gray)
            end
        else
            coloredPrint("Error message not available", colors.gray)
        end

        local file = fs.open(fileName, "r")
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
    end

    term.setBackgroundColor(colors.black)
end

--- Starts the update loop
--- @param isActive? boolean -- If the update loop should be active
function basalt.run(isActive)
    expect(1, isActive, "boolean", "nil")
    updaterActive = isActive
    if (isActive == nil) then
        updaterActive = true
    end
    local function f()
        drawFrames()
        while updaterActive do
            updateEvent(os.pullEventRaw())
        end
    end
    while updaterActive do
        local ok, err = xpcall(f, debug.traceback)
        if not (ok) then
            basalt.errorHandler(err)
        end
    end
end
basalt.autoUpdate = basalt.run

--- Returns a list of all available elements in the current basalt installation
--- @return table
function basalt.getElements()
    return loader.getElementList()
end

--- Registers a new event listener
--- @param event string -- The event to listen for
--- @param func function -- The function to call when the event is triggered
function basalt.onEvent(event, func)
    expect(1, event, "string")
    expect(2, func, "function")
    if (registeredEvents[event] == nil) then
        registeredEvents[event] = {}
    end
    table.insert(registeredEvents[event], func)
end

--- Removes an event listener
--- @param event string -- The event to remove the listener from
--- @param func function -- The function to remove
function basalt.removeEvent(event, func)
    expect(event, "string")
    expect(func, "function")
    if (registeredEvents[event] == nil) then
        return
    end
    for k, v in pairs(registeredEvents[event]) do
        if (v == func) then
            table.remove(registeredEvents[event], k)
        end
    end
end

--- Sets the focused frame
--- @param frame BaseFrame|Monitor|BigMonitor -- The frame to focus
function basalt.setFocusedFrame(frame)
    expect(1, frame, "BaseFrame", "Monitor", "BigMonitor")
    if (focusedFrame ~= nil) then
        focusedFrame:lose_focus()
    end
    if (frame ~= nil) then
        frame:get_focus()
    end
    focusedFrame = frame
end

--- Starts a new thread which runs the function parallel to the main thread
--- @param func function -- The function to run
--- @vararg any? -- The arguments to pass to the function
--- @return table
function basalt.thread(func, ...)
    expect(1, func, "function")
    local threadData = {}
    threadData.thread = coroutine.create(func)
    local ok, filter = coroutine.resume(threadData.thread, ...)
    if (ok) then
        threadData.stop = function()
            for k, v in pairs(threads) do
                if (v == threadData) then
                    table.remove(threads, k)
                end
            end
            threadData = nil
        end
        threadData.status = function()
            return coroutine.status(threadData.thread)
        end
        threadData.filter = filter
        table.insert(threads, threadData)
        return threadData
    end
    basalt.errorHandler(filter)
    return threadData
end

--- Stops the update loop
function basalt.stop()
    baseTerm.clear()
    baseTerm.setCursorPos(1, 1)
    baseTerm.setBackgroundColor(colors.black)
    baseTerm.setTextColor(colors.red)
    baseTerm.setTextColor(colors.white)
    updaterActive = false
end

--- Returns the current term
---@return term
function basalt.getTerm()
    return baseTerm
end

local extensions = loader.getExtension("Basalt")
if (extensions ~= nil) then
    for _, v in pairs(extensions) do
        v.basalt = basalt
        if (v.init ~= nil) then
            v.init(basalt)
        end
        for a, b in pairs(v) do
            if (a ~= "init") then
                basalt[a] = b
            end
        end
    end
end

package.path = defaultPath
return basalt
