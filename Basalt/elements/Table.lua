local Container = require("basaltLoader").load("Container")

--- @class Table : Container
local Table = setmetatable({}, Container)
Table.__index = Table

Table:initialize("Table")

--- Creates a new table.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Table
---@protected
function Table:new(id, parent, basalt)
    local newInstance = Container:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Table")
    newInstance:create("Table")
    newInstance:setZ(10)
    newInstance:setSize(30, 12)
    return newInstance
end

return Table
