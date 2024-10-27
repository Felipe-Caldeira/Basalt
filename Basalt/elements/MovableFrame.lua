local Container = require("basaltLoader").load("Container")
local expect = require("expect").expect

---@class MovableFrame : Container
local MovableFrame = setmetatable({}, Container)
MovableFrame.__index = MovableFrame

MovableFrame:initialize("MovableFrame")
MovableFrame:addProperty("dragMap", "table", {{
    x = 1,
    y = 1,
    w = 0,
    h = 1
}})

--- Creates a new MovableFrame.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return MovableFrame
---@protected
function MovableFrame:new(id, parent, basalt)
    local newInstance = Container:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("MovableFrame")
    newInstance:create("MovableFrame")
    newInstance:setZ(10)
    newInstance:setSize(30, 15)
    return newInstance
end

MovableFrame:extend("Load", function(self)
    self:listenEvent("mouse_click")
    self:listenEvent("mouse_up")
    self:listenEvent("mouse_drag")
end)

--- Checks if the given position is in the drag map.
---@param self MovableFrame The element itself
---@param x number The x position.
---@param y number The y position.
---@return boolean
function MovableFrame:isInDragMap(x, y)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    local x, y = self:getRelativePosition(x, y)
    for _, v in pairs(self.dragMap) do
        local w, h = v.w - 1, v.h - 1
        if (v.w <= 0) then
            w = self:getWidth()
        end
        if (v.h <= 0) then
            h = self:getHeight()
        end
        if (x >= v.x and x <= v.x + w and y >= v.y and y <= v.y + h) then
            return true
        end
    end
    return false
end

--- Adds a new drag area to the drag map.
---@param self MovableFrame The element itself
---@param x number The x position.
---@param y number The y position.
---@param w number The width.
---@param h number The height.
function MovableFrame:addDragArea(x, y, w, h)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, w, "number")
    expect(5, h, "number")
    table.insert(self.dragMap, {
        x = x,
        y = y,
        w = w,
        h = h
    })
    return self
end

---@protected
function MovableFrame:mouse_click(button, x, y)
    if (Container.mouse_click(self, button, x, y)) then
        if (button == 1) then
            if (self:isInDragMap(x, y)) then
                self.isDragging = true
                self.dragX = x
                self.dragY = y
            end
            return true
        end
    end
end

---@protected
function MovableFrame:mouse_up(button, x, y)
    self.isDragging = false
    return Container.mouse_up(self, button, x, y)
end

---@protected
function MovableFrame:mouse_drag(button, x, y)
    Container.mouse_drag(self, button, x, y)
    if (self.isDragging) then
        local dx = x - self.dragX
        local dy = y - self.dragY
        self.dragX = x
        self.dragY = y
        self:setPosition(self:getX() + dx, self:getY() + dy)
        return true
    end
end

return MovableFrame
