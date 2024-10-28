local loader = require("basaltLoader")
local Element = loader.load("BasicElement")
local VisualElement = loader.load("VisualElement")
local List = loader.load("List")
local tHex = require("utils").tHex

---@class Dropdown : List
local Dropdown = setmetatable({}, List)
Dropdown.__index = Dropdown

Dropdown:initialize("Dropdown")
Dropdown:addProperty("opened", "boolean", false)
Dropdown:addProperty("dropdownHeight", "number", 5)
Dropdown:addProperty("dropdownWidth", "number", 15)
Dropdown:combineProperty("dropdownSize", "dropdownWidth", "dropdownHeight")

--- Creates a new Dropdown.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Dropdown
---@protected
function Dropdown:new(id, parent, basalt)
    local newInstance = List:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Dropdown")
    newInstance:create("Dropdown")
    newInstance:setSize(10, 1)
    newInstance:setZ(10)
    return newInstance
end

---@protected
function Dropdown:render()
    VisualElement.render(self)
    local selectedIndex = self:getSelectedIndex()
    local scrollIndex = self:getScrollIndex()
    if self.items[selectedIndex] then
        self:addTxt(1, 1, self.items[selectedIndex].label)
        self:addTxt(self:getWidth(), 1, "\16")
    end
    if self.opened then
        self:addTxt(self:getWidth(), 1, "\31")
        for i = 1, self.dropdownHeight do
            local item = self.items[i + scrollIndex - 1]
            if item then
                self:addTxt(1, i + 1, item.label .. (" "):rep(self.dropdownWidth - item.label:len()))
                if (i + scrollIndex - 1 == selectedIndex) then
                    self:addBg(1, i + 1, tHex[self:getSelectedBackground()]:rep(self.dropdownWidth))
                    self:addFg(1, i + 1, tHex[self:getSelectedForeground()]:rep(self.dropdownWidth))
                else
                    self:addBg(1, i + 1, tHex[self:getBackground()]:rep(self.dropdownWidth))
                    self:addFg(1, i + 1, tHex[self:getForeground()]:rep(self.dropdownWidth))
                end
            end
        end
    end
end

---@protected
function Dropdown:mouse_click(button, x, y)
    if (VisualElement.mouse_click(self, button, x, y)) then
        self.opened = not self.opened
        return true
    end
    if self.opened then
        local currX, currY = self:getX(), self:getY()
        if (x >= currX and x <= currX + self.dropdownWidth and y >= currY + 1 and y <= currY + self.dropdownHeight) then
            local index = y - currY + self.scrollIndex - 1
            self:setSelectedIndex(index)
            self:fireEvent("change", self.items[index])
            self.basalt.thread(function()
                sleep(0.1)
                self.opened = false
                self:updateRender()
            end)
            return true
        end
    end
end

---@protected
function Dropdown:mouse_scroll(direction, x, y)
    if (VisualElement.mouse_scroll(self, direction, x, y)) then
        self:setSelectedIndex(math.max(math.min(self:getSelectedIndex() + direction, #self.items), 1))
        self:updateRender()
    end
    if self:getOpened() then
        local currX, currY = self:getX(), self:getY()
        if (x >= currX and x <= currX + self.dropdownWidth and y >= currY + 1 and y <= currY + self.dropdownHeight) then
            if direction == -1 then
                self.scrollIndex = math.max(self.scrollIndex - 1, 1)
            else
                self.scrollIndex = math.min(self.scrollIndex + 1, #self.items - self.dropdownHeight + 1)
            end
            self:updateRender()
        end
    end
end

return Dropdown
