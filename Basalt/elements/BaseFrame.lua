local loader = require("basaltLoader")
local Container = loader.load("Container")

--- @class BaseFrame : Container
local BaseFrame = setmetatable({}, Container)
BaseFrame.__index = BaseFrame

BaseFrame:initialize("BaseFrame")

--- Creates a new BaseFrame.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return BaseFrame
---@protected
function BaseFrame:new(id, parent, basalt)
    local newInstance = Container:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("BaseFrame")
    newInstance:create("BaseFrame")
    newInstance:setTerm(term.current())
    newInstance:setSize(term.getSize())
    return newInstance
end

function BaseFrame:getSize()
    local baseTerm = self:getProperty("term")
    if (baseTerm ~= nil) then
        return baseTerm.getSize()
    end
    return 1, 1
end

function BaseFrame:getWidth()
    return select(1, self:getSize())
end

function BaseFrame:getHeight()
    return select(2, self:getSize())
end

function BaseFrame:getPosition()
    return 1, 1
end

--- Forces the base frame to update all visible children
--- @param self BaseFrame
function BaseFrame:forceRender()
    self.updateRendering = true
    self:forceVisibleChildrenUpdate()
    self.renderSystem.forceRender()
end

---@protected
function BaseFrame:event(event, ...)
    Container.event(self, event, ...)
    if (event == "term_resize") then
        self:forceVisibleChildrenUpdate()
        self:setSize(term.getSize())
        self:setTerm(term.current())
    end
end

---@protected
function BaseFrame:mouse_click(...)
    Container.mouse_click(self, ...)
    self.basalt.setFocusedFrame(self)
end

---@protected
function BaseFrame:lose_focus()
    Container.lose_focus(self)
    self:setCursor(false)
end

return BaseFrame
