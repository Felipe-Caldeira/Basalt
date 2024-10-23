---@class Basalt
local debug = {frames={}}

local function openDebugPanel()
    local mainFrame = debug.basalt.getMainFrame()
    local id = mainFrame:getName()
    if(debug.frames[id]==nil)then
        debug.frames[id] = {}
        debug.frames[id].window = mainFrame:addMovableFrame():setSize(45, 14):setBackground(colors.cyan):setZ(100):setVisible(false)
        debug.frames[id].window:addLabel():setText("Debug Log"):setPosition(1, 1):setSize(45, 1):setForeground(colors.cyan):setBackground(colors.black)
        debug.frames[id].debugLog  = debug.frames[id].window:addList():setPosition(2,3):setSize(42, 12):setBackground(colors.white):setForeground(colors.black):setSelectionColor(colors.white, colors.black)
        debug.frames[id].closeButton = debug.frames[id].window:addButton():setForeground(colors.black):setBackground(colors.red):setSize(1,1):setText("x"):setPosition("{parent.w}", 1):onClick(function()
            debug.frames[id].window:setVisible(false)
        end)
        debug.frames[id].label = mainFrame:addLabel()
        :setBackground(colors.black)
        :setForeground(colors.white)
        :setVisible(false)
        :onClick(function()
            debug.frames[id].window:setVisible(not debug.frames[id].window:getVisible())
        end)
        if(debug.basalt.extensionExists("borders"))then
            debug.frames[id].window:setBorder(true)
        end
    end
    return debug.frames[id]
end

--- Writes a message to the debug log window
---@param ... any
debug.debug = function(...)
    local msg = ""
    for _,v in pairs({...})do
        msg = msg..tostring(v).." "
    end
    local mainFrame = debug.basalt.getMainFrame()
    local debugPanel = openDebugPanel()
    local label = debugPanel.label
    label:setPosition(1, mainFrame:getHeight()):setText("[Debug]: "..msg):setVisible(true)
    if(debugPanel.debugLog~=nil)then
        debugPanel.debugLog:addItem(msg)
    end
end

--- Opens the debug panel
---@param bool? boolean
debug.openDebugPanel = function(bool)
    if(bool==nil)then bool = true end
    openDebugPanel():setVisible(bool==true and true or false)
end

return {
    Basalt = debug,
}