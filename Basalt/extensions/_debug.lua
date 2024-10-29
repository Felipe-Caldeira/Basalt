---@class Basalt
local debug = {
    frames = {}
}

local function openDebugPanel()
    local mainFrame = debug.basalt.getMainFrame()
    local id = mainFrame:getId()
    if (debug.frames[id] == nil) then
        local df = {}
        df.window = mainFrame:addMovableFrame({size={45, 15}, background='cyan', z=100, visible=false})
        df.window:addLabel({text="Debug Log", x=1, y=1, size={45, 1}, colors={'black', 'cyan'}})
        df.debugLog = df.window:addList({x=2, y=3, size={43, 12}, colors={'white', 'black'}, selectable=false})
        df.closeButton = df.window:addButton({colors={'red', 'black'}, size={1, 1}, text='x', x='{parent.w}', y=1}):onClick(function()
            df.window:setVisible(false)
        end)
        df.label = mainFrame:addLabel({colors={'black', 'white'}, visible=false}):onClick(function()
            df.window:setVisible(not df.window:getVisible())
        end)
        df.clearButton = df.window:addButton({background='yellow', size={5, 1}, text="Clear", x='{parent.w - 4}', y='{parent.h}'}):onClick(function()
            df.debugLog:clear()
            df.label:setVisible(false)
        end)
        df.window.__debugElement = true
        df.label.__debugElement = true
        debug.frames[id] = df
    end
    return debug.frames[id]
end

--- Writes a message to the debug log window
---@param ... any
debug.debug = function(...)
    local msg = ""
    for _, v in pairs({...}) do
        msg = msg .. tostring(v) .. " "
    end
    local mainFrame = debug.basalt.getMainFrame()
    local debugPanel = openDebugPanel()
    local label = debugPanel.label
    label:setPosition(1, mainFrame:getHeight()):setText("[Debug]: " .. msg):setVisible(true)
    if (debugPanel.debugLog ~= nil) then
        debugPanel.debugLog:addItem(msg)
    end
end

--- Opens the debug panel
---@param bool? boolean
debug.openDebugPanel = function(bool)
    if (bool == nil) then
        bool = true
    end
    openDebugPanel():setVisible(bool == true and true or false)
end

return {
    Basalt = debug
}
