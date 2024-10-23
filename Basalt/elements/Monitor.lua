local type, len, rep, sub = type, string.len, string.rep, string.sub

local loader = require("basaltLoader")
local Container = loader.load("Container")

---@class Monitor : Container
local Monitor = setmetatable({}, Container)
Monitor.__index = Monitor

Monitor:initialize("Monitor")

Monitor:addProperty("Monitor", "any", nil, nil, function(self, value, callSide)
    if (type(value == "string")) then
        value = peripheral.wrap(value)
    end
    if (callSide ~= false) then
        self:setSide(peripheral.getName(value), false)
    end
    self:setSize(value.getSize())
    self:setTerm(value)
    return value
end)
Monitor:addProperty("Side", "string", nil, nil, function(self, value, callMon)
    if (type(value) == "string") then
        if (peripheral.isPresent(value)) then
            if (peripheral.getType(value) == "monitor") then
                if (self:getMonitor() == nil) then
                    if (callMon ~= false) then
                        self:setMonitor(value, false)
                    end
                end
                return value
            end
        end
    end
end)

--- Creates a new Monitor.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Monitor
---@protected
function Monitor:new(id, parent, basalt)
    local newInstance = Container:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Monitor")
    newInstance:create("Monitor")
    return newInstance
end

---@protected
function Monitor:event(event, ...)
    Container.event(self, event, ...)
    if (event == "monitor_resize") then
        local mon = self:getMonitor()
        self:setSize(mon.getSize())
        self:setTerm(mon)
    end
end

---@protected
function Monitor:monitor_touch(side, ...)
    if (side == self:getSide()) then
        self.basalt.setFocusedFrame(self)
        self:mouse_click(1, ...)
    end
end

---@protected
function Monitor:lose_focus()
    Container.lose_focus(self)
    self:setCursor(false)
end

return Monitor
