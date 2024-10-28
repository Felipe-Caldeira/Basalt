local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local getCenteredPosition = require("utils").getCenteredPosition

---@class Checkbox : VisualElement
local Checkbox = setmetatable({}, VisualElement)
Checkbox.__index = Checkbox

Checkbox:initialize("Checkbox")
Checkbox:addProperty("checked", "boolean", false, nil, function(self)
    self:updateRender()
end)
Checkbox:addProperty("checkedSymbol", "string", "\42")
Checkbox:addProperty("checkedColor", "color", colors.white)
Checkbox:addProperty("checkedBgColor", "color", colors.black)
Checkbox:combineProperty("Symbol", "checkedSymbol", "checkedColor", "checkedBgColor")

Checkbox:addListener("check", "checked_value")

--- Creates a new checkbox.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Checkbox
---@protected
function Checkbox:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Checkbox")
    newInstance:create("Checkbox")
    newInstance:setSize(1, 1)
    return newInstance
end

---@protected
function Checkbox:render()
    VisualElement.render(self)
    local xO, yO = getCenteredPosition(self.checkedSymbol, self:getWidth(), self:getHeight())
    if self.checked then
        self:addTxt(xO, yO, self.checkedSymbol)
    else
        self:addTxt(xO, yO, " ")
    end
end

---@protected
Checkbox:extend("Load", function(self)
    self:listenEvent("mouse_click")
end)

---@protected
function Checkbox:mouse_click(button, x, y)
    if (VisualElement.mouse_click(self, button, x, y)) then
        if (button == 1) then
            self:setChecked(not self:getChecked())
            self:fireEvent("check", self:getChecked())
            self:updateRender()
        end
        return true
    end
end

return Checkbox
