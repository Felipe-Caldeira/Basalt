local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")

---@class Progressbar : VisualElement
local Progressbar = setmetatable({}, VisualElement)
Progressbar.__index = Progressbar

Progressbar:initialize("Progressbar")
Progressbar:addProperty("progress", "number", 0)
Progressbar:addProperty("progressBackground", "color", colors.black)
Progressbar:addProperty("minValue", "number", 0)
Progressbar:addProperty("maxValue", "number", 100)

--- Creates a new Progressbar.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Progressbar
---@protected
function Progressbar:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Progressbar")
    newInstance:create("Progressbar")
    newInstance:setSize(20, 3)
    return newInstance
end

---@protected
function Progressbar:render()
    VisualElement.render(self)
    local width = self:getWidth()
    local height = self:getHeight()
    local progress = self:getProgress()
    local minValue = self:getMinValue()
    local maxValue = self:getMaxValue()
    local progressBackground = self:getProgressBackground()
    local barLength = math.floor((width - 2) * (progress - minValue) / (maxValue - minValue))
    self:addBackgroundBox(1, 1, barLength, height, progressBackground)
end

return Progressbar
