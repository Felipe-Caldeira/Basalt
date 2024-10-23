local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local List = loader.load("List")
local tHex = require("utils").tHex

---@class Menubar : List
local Menubar = setmetatable({}, List)
Menubar.__index = Menubar

Menubar:initialize("Menubar")
Menubar:addProperty("spacing", "number", 1)

--- Creates a new Menubar.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Menubar
---@protected
function Menubar:new(id, parent, basalt)
    local newInstance = List:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Menubar")
    newInstance:create("Menubar")
    newInstance:setSize(20, 1)
    return newInstance
end

---@protected
function Menubar:mouse_click(button, x, y)
    if (VisualElement.mouse_click(self, button, x, y)) then
        if (button == 1) then
            local cumulativeWidth = self.x
            for i = self.scrollIndex, #self.items do
                local itemWidth = #self.items[i] + self.spacing
                if x >= cumulativeWidth and x < cumulativeWidth + itemWidth then
                    self.selectedIndex = i
                    self:fireEvent("change", self.items[i])
                    break
                end
                cumulativeWidth = cumulativeWidth + itemWidth
            end
        end
        return true
    end
end

---@protected
function Menubar:render()
    VisualElement.render(self)
    local currentIndex = self.scrollIndex
    local currentX = 1
    self:addText(1, 1, (" "):rep(self.width))
    self:addBg(1, 1, tHex[self.background]:rep(self.width))
    self:addFg(1, 1, tHex[self.foreground]:rep(self.width))
    while currentX <= self.width and currentIndex <= #self.items do
        local item = self.items[currentIndex]
        if currentX + #item - 1 + self.spacing <= self.width then
            self:addText(currentX, 1, item)
            if currentIndex == self.selectedIndex then
                self:addBg(currentX, 1, tHex[self.selectionBackground]:rep(#item))
                self:addFg(currentX, 1, tHex[self.selectionForeground]:rep(#item))
            end
            currentX = currentX + #item + self.spacing
        else
            break
        end
        currentIndex = currentIndex + 1
    end
end

---@protected
function Menubar:mouse_scroll(direction, x, y)
    if (VisualElement.mouse_scroll(self, direction, x, y)) then
        if direction == 1 and self.scrollIndex < #self.items - self:getVisibleItems() + 1 then
            self.scrollIndex = self.scrollIndex + 1
        elseif direction == -1 and self.scrollIndex > 1 then
            self.scrollIndex = self.scrollIndex - 1
        end
        self:updateRender()
        return true
    end
end

--- Returns the amount of visible items
---@param self Menubar
---@return number
function Menubar:getVisibleItems()
    local visibleItems = 0
    local currentIndex = self.scrollIndex
    local currentWidth = 1
    while currentWidth <= self.width and currentIndex <= #self.items do
        local item = self.items[currentIndex]
        if currentWidth + #item - 1 + self.spacing <= self.width then
            visibleItems = visibleItems + 1
            currentWidth = currentWidth + #item + self.spacing
        else
            if currentWidth + #item - 1 <= self.width then
                visibleItems = visibleItems + 1
            end
            break
        end
        currentIndex = currentIndex + 1
    end
    return visibleItems
end

return Menubar
