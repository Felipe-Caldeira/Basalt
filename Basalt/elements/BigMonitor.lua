local type, len, rep, sub = type, string.len, string.rep, string.sub
local tHex = require("utils").tHex
local expect = require("expect").expect

local function MassiveMonitor(monitors)
    local globalX, globalY, monX, monY, w, h = 1, 1, 1, 1, 0, 0
    local blink, scale = false, 1
    local fg, bg = colors.white, colors.black

    for k, v in pairs(monitors) do
        for a, b in pairs(v) do
            if (type(b) == "string") then
                local mon = peripheral.wrap(b)
                if (mon == nil) then
                    error("Unable to find monitor " .. b)
                end
                monitors[k][a] = mon
                monitors[k][a].name = b
            end
        end
    end

    local function getCombinedSize()
        local totalWidth = 0
        local maxHeight = 0

        for _, monitorList in pairs(monitors) do
            local width = 0
            local height = 0

            for _, mon in pairs(monitorList) do
                local w, h = mon.getSize()
                width = width + w
                height = h
            end

            totalWidth = math.max(totalWidth, width)
            maxHeight = maxHeight + height
        end

        return totalWidth, maxHeight
    end

    local function call(f, ...)
        local t = {...}
        return function()
            for k, v in pairs(monitors) do
                for a, b in pairs(v) do
                    b[f](table.unpack(t))
                end
            end
        end
    end

    local function cursorBlink()
        call("setCursorBlink", false)()
        if not (blink) then
            return
        end
        if (monitors[monY] == nil) then
            return
        end
        local mon = monitors[monY][monX]
        if (mon == nil) then
            return
        end
        mon.setCursorBlink(blink)
    end

    local function getMaxHeightForRow(row)
        local maxHeight = 0
        for _, monitor in pairs(monitors[row]) do
            local _, height = monitor.getSize()
            maxHeight = math.max(maxHeight, height)
        end
        return maxHeight
    end

    local function blit(globalX, globalY, text, tCol, bCol)
        local remainingText = text
        local remainingTCol = tCol
        local remainingBCol = bCol

        local currentRow = 1
        local maxHeight = getMaxHeightForRow(currentRow)

        while globalY > maxHeight and currentRow <= #monitors do
            globalY = globalY - maxHeight
            currentRow = currentRow + 1
            if currentRow <= #monitors then
                maxHeight = getMaxHeightForRow(currentRow)
            end
        end
        if currentRow > #monitors then
            return
        end

        local currentMonitorList = monitors[currentRow]
        local monIndex = 1

        while len(remainingText) > 0 and monIndex <= #currentMonitorList do
            local currentMonitor = currentMonitorList[monIndex]
            local monW, _ = currentMonitor.getSize()

            local localX = globalX
            local lengthToWrite = math.min(monW - localX + 1, len(remainingText))

            currentMonitor.setCursorPos(localX, globalY)
            currentMonitor.blit(sub(remainingText, 1, lengthToWrite), sub(remainingTCol, 1, lengthToWrite),
                sub(remainingBCol, 1, lengthToWrite))

            remainingText = sub(remainingText, lengthToWrite + 1)
            remainingTCol = sub(remainingTCol, lengthToWrite + 1)
            remainingBCol = sub(remainingBCol, lengthToWrite + 1)
            globalX = 1

            monIndex = monIndex + 1
        end
    end

    return {
        clear = call("clear"),

        setCursorBlink = function(_blink)
            blink = _blink
            cursorBlink()
        end,

        getCursorBlink = function()
            return blink
        end,

        getCursorPos = function()
            return globalX, globalY
        end,

        setCursorPos = function(newX, newY)
            globalX, globalY = newX, newY
            cursorBlink()
        end,

        setTextScale = function(_scale)
            call("setTextScale", _scale)()
            scale = _scale
        end,

        getTextScale = function()
            return scale
        end,

        blit = function(text, fgCol, bgCol)
            blit(globalX, globalY, text, fgCol, bgCol)
        end,

        write = function(text)
            text = tostring(text)
            local l = len(text)
            blit(globalX, globalY, text, rep(tHex[fg], l), rep(tHex[bg], l))
        end,

        getSize = getCombinedSize,

        setBackgroundColor = function(col)
            call("setBackgroundColor", col)()
            bg = col
        end,

        setTextColor = function(col)
            call("setTextColor", col)()
            fg = col
        end,

        calculateClick = function(name, xClick, yClick)
            local relY = 0
            for k, v in pairs(monitors) do
                local relX = 0
                local maxY = 0
                for a, b in pairs(v) do
                    local wM, hM = b.getSize()
                    if (b.name == name) then
                        return xClick + relX, yClick + relY
                    end
                    relX = relX + wM
                    if (hM > maxY) then
                        maxY = hM
                    end
                end
                relY = relY + maxY
            end
            return xClick, yClick
        end

    }
end

local loader = require("basaltLoader")
local Container = loader.load("Container")

---@class BigMonitor : Container
local BigMonitor = setmetatable({}, Container)
BigMonitor.__index = BigMonitor

BigMonitor:initialize("BigMonitor")

--- Creates a new BigMonitor.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return BigMonitor
---@protected
function BigMonitor:new(id, parent, basalt)
    local newInstance = Container:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("BigMonitor")
    newInstance:create("BigMonitor")
    return newInstance
end

---@protected
function BigMonitor:event(event, ...)
    Container.event(self, event, ...)
    if (event == "monitor_resize") then
        self:forceVisibleChildrenUpdate()
        self:setSize(self.massiveMon.getSize())
    end
end

--- Sets the group of monitors to be used.
---@param self BigMonitor The element itself
---@param group table The group of monitors.
---@return BigMonitor
function BigMonitor:setGroup(group)
    expect(1, self, "table")
    expect(2, group, "table")
    if (type(group) ~= "table") then
        error("Expected table, got " .. type(group))
    end
    local monitors = {}
    for k, v in pairs(group) do
        monitors[k] = {}
        for a, b in pairs(v) do
            if (type(b == "string")) then
                local mon = peripheral.wrap(b)
                if (mon == nil) then
                    error("Unable to find monitor " .. b)
                end
                monitors[k][a] = mon
                monitors[k][a].name = b
            elseif (type(b) == "table") then
                monitors[k][a] = b
                monitors[k][a].name = peripheral.getName(b)
            end
        end
    end
    self.monitors = monitors
    self.massiveMon = MassiveMonitor(monitors)
    self:setTerm(self.massiveMon)
    self:setSize(self.massiveMon.getSize())
    return self
end

--- Gets the group of monitors.
---@param self BigMonitor The element itself
---@return table The group of monitors.
function BigMonitor:getGroup()
    expect(1, self, "table")
    return self.monitors
end

---@protected
function BigMonitor:lose_focus()
    Container.lose_focus(self)
    self:setCursor(false)
end

---@protected
function BigMonitor:monitor_touch(side, x, y)
    self:mouse_click(1, self.massiveMon.calculateClick(side, x, y))
end

return BigMonitor
