local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local expect = require("expect").expect

local sub = string.sub

---@class Treeview : VisualElement
local Treeview = setmetatable({}, VisualElement)
Treeview.__index = Treeview

Treeview:initialize("Treeview")

--- Creates a new Treeview.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Treeview
---@protected
function Treeview:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Treeview")
    newInstance:create("Treeview")
    newInstance:setSize(10, 8)
    newInstance:setZ(5)
    return newInstance
end

---@protected
function Treeview:render()
    VisualElement.render(self)

end

return Treeview
