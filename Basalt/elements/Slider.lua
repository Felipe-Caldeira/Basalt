local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local tHex = require("utils").tHex

---@class Slider : VisualElement
local Slider = setmetatable({}, VisualElement)
Slider.__index = Slider

Slider:initialize("Slider")
Slider:addProperty("knobSymbol", "string", " ")
Slider:addProperty("knobBackground", "color", colors.black)
Slider:addProperty("knobForeground", "color", colors.black)
Slider:addProperty("bgSymbol", "string", "\140")
Slider:addProperty("value", "number", 0)
Slider:addProperty("minValue", "number", 0)
Slider:addProperty("maxValue", "number", 100)
Slider:addProperty("step", "number", 1)

Slider:combineProperty("knob", "knobSymbol", "knobBackground", "knobForeground")

Slider:addListener("change", "value_change")

--- Creates a new Slider.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Slider
---@protected
function Slider:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Slider")
    newInstance:create("Slider")
    newInstance:setSize(20, 1)
    return newInstance
end

Slider:extend("Load", function(self)
    self:listenEvent("mouse_click")
    self:listenEvent("mouse_drag")
    self:listenEvent("mouse_up")
    self:listenEvent("mouse_scroll")
end)

local function calculateKnobPosition(self, x, y)
    local xPos, yPos = self:getPosition()
    local width, height = self:getSize()
    local value = self:getValue()
    local maxValue = self:getMaxValue()
    local minValue = self:getMinValue()
    local step = self:getStep()
    local relativeX = x - xPos
    value = relativeX / (width - 1) * (maxValue - minValue) + minValue
    value = math.floor((value + step / 2) / step) * step
    value = math.max(minValue, math.min(maxValue, value))
    self:setValue(value)
    self:fireEvent("change", value)
    self:updateRender()
end

---@protected
function Slider:mouse_click(button, x, y)
    if (VisualElement.mouse_click(self, button, x, y)) then
        if (button == 1) then
            calculateKnobPosition(self, x, y)
        end
        return true
    end
end

---@protected
function Slider:mouse_drag(button, x, y)
    if (VisualElement.mouse_drag(self, button, x, y)) then
        if (button == 1) then
            calculateKnobPosition(self, x, y)
        end
        return true
    end
end

---@protected
function Slider:mouse_scroll(direction, x, y)
    if VisualElement.mouse_scroll(self, direction, x, y) then
        local value = self:getValue()
        local minValue = self:getMinValue()
        local maxValue = self:getMaxValue()
        local width = self:getWidth()

        local step = (maxValue - minValue) / (width - 1)

        if direction == 1 then
            value = value + step
        else
            value = value - step
        end

        value = math.max(minValue, math.min(value, maxValue))

        self:setValue(value)
        self:fireEvent("change", value)
        self:updateRender()
        return true
    end
end

---@protected
function Slider:render()
    VisualElement.render(self)
    local value = self:getValue()
    local minValue = self:getMinValue()
    local maxValue = self:getMaxValue()
    local width = self:getWidth()
    local bar = (self.bgSymbol):rep(width)
    local knobPosition = math.floor((value - minValue) / (maxValue - minValue) * (width - 1) + 0.5)
    bar = bar:sub(1, knobPosition) .. self.knobSymbol .. bar:sub(knobPosition + 2, -1)
    self:addTxt(1, 1, bar)
    self:addBg(knobPosition + 1, 1, tHex[self:getKnobBackground()])
    self:addFg(knobPosition + 1, 1, tHex[self:getKnobForeground()])
end

return Slider
