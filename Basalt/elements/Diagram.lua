local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local utils = require("utils")
local wrapText = utils.wrapText

---@class Diagram : VisualElement
local Diagram = setmetatable({}, VisualElement)
Diagram.__index = Diagram
local sub, rep = string.sub, string.rep

Diagram:initialize("Diagram")
Diagram:addProperty("data", "table", {})
Diagram:addProperty("maxAmount", "number", 20)
Diagram:addProperty("zoom", "number", 0)
Diagram:addProperty("autoZoom", "boolean", true)

--- Creates a new Diagram.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Diagram
---@protected
function Diagram:new(id, parent, basalt)

    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Diagram")
    newInstance:create("Diagram")
    newInstance:setZ(10)
    newInstance:setSize(24, 8)
    return newInstance
end

---@protected
function Diagram:render()
    VisualElement.render(self)
    local data = self:getData()
    local maxAmount = self:getMaxAmount()
    local zoom = self:getZoom()
    local width, height = self:getSize()

    for k, v in ipairs(data) do
        if k > maxAmount or k > width then
            break
        end
        local x = k
        local y = height - v
        if zoom > 0 then
            x = x * zoom
            y = y * zoom
        end
        self:addTxt(x, y, "a")
    end
end

function Diagram:getMax()
    local maxAmount = self:getMaxAmount()
    local width = self:getWidth()
    local max = 0
    for k, v in ipairs(self:getData()) do
        if k > maxAmount or k > width then
            break
        end
        if v > max then
            max = v
        end
    end
    return max

end

function Diagram:addDataPoint(value)
    table.insert(self:getData(), 1, value)
    return self
end

return Diagram
