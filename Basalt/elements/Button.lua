local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local getCenteredPosition = require("utils").getCenteredPosition

--- @class Button : VisualElement
local Button = setmetatable({}, VisualElement)
Button.__index = Button

Button:initialize("Button")
Button:addProperty("text", "string", "Button")

--- Creates a new visual element.
---@param id string The id of the object.
---@param parent Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Button
function Button:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Button")
    newInstance:create("Button")
    newInstance:setSize(10, 3)
    newInstance:setZ(5)
    return newInstance
end

function Button:render()
    VisualElement.render(self)
    local text = self:getText()
    local xO, yO = getCenteredPosition(text, self:getWidth(), self:getHeight())
    self:addText(xO, yO, text)
end

return Button
