local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local tHex = require("utils").tHex
local expect = require("expect").expect
local log = require("log")

---@class List : VisualElement
local List = setmetatable({}, VisualElement)
List.__index = List

--[[ 
{
    label = "MyLabel",
    value = someVal,
    background = bg,
    foreground = fg,
}
]]

List:initialize("List")
List:addProperty("items", "table", {})
List:addProperty("connectedLists", "table", {})
List:addProperty("autoScroll", "boolean", false)
List:addProperty("align", "string", "left")
List:addProperty("spacing", "number", 0)
List:addProperty("selectable", "boolean", true)
List:addProperty("multiSelectable", "boolean", false)
List:addProperty("selectedIndex", "table", {}, nil, 
    function(self, value, sendToOthers)
        local newValue = self.selectedIndex
        if self:getMultiSelectable() then
            if type(value) == "table" then
                newValue = value
            else
                if self:isItemSelected(value) then
                    for i, v in ipairs(newValue) do
                        if v == value then
                            table.remove(newValue, i)
                            break
                        end
                    end
                else
                    table.insert(newValue, value)
                end
            end
        else
            newValue = {value}
        end
        if sendToOthers ~= false then
            for _, v in pairs(self:getConnectedLists()) do
                v:setSelectedIndex(newValue, false)
            end
        end
        return newValue
    end, 
    function(self, value)
        if (self:getMultiSelectable()) then
            return value
        else
            return value[1]
        end
    end)
List:addProperty("selectedBackground", "color", colors.black)
List:addProperty("selectedForeground", "color", colors.cyan)
List:combineProperty("selectedColor", "selectedBackground", "selectedForeground")
List:addProperty("scrollIndex", "number", 1, nil, function(self, value, sendToOthers)
    if (sendToOthers ~= false) then
        for _, v in pairs(self:getConnectedLists()) do
            v:setScrollIndex(value, false)
        end
    end
end)

List:addListener("change", "changed_value")

--- Creates a new List.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return List
---@protected
function List:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("List")
    newInstance:create("List")
    newInstance:setSize(15, 6)
    return newInstance
end

List:extend("Load", function(self)
    self:listenEvent("mouse_click")
    self:listenEvent("mouse_scroll")
end)

---@protected
function List:render()
    VisualElement.render(self)
    local w, h = self:getSize()
    local items = self:getItems()
    local scrollIndex = self:getScrollIndex()
    local selectedBg, selectedFg = self:getSelectedColor()
    local selectable = self:getSelectable()
    local spacing = self:getSpacing()
    local align = self:getAlign()

    for i = 1, h do
        local index = i + scrollIndex - 1
        local item = items[index]
        if item then
            if (align == "right") then
                self:addTxt(w - #item.label + 1 - spacing, i, item.label)
            elseif (align == "center") then
                self:addTxt(math.floor((w - #item.label) / 2) + 1, i, item.label)
            else
                self:addTxt(1 + spacing, i, item.label)
            end
            if (item.background) then
                self:addBg(1, i, tHex[item.background]:rep(w))
            end
            if (item.foreground) then
                self:addFg(1, i, tHex[item.foreground]:rep(w))
            end
            if (selectable) then
                if self:isItemSelected(index) then
                    self:addBg(1, i, tHex[selectedBg]:rep(w))
                    self:addFg(1, i, tHex[selectedFg]:rep(w))
                end
            end
        end
    end
end

--- Connects the list to another list.
---@param self List The element itself
---@param list List The list to connect.
---@param ignSettings? boolean Whether to ignore to synchronize the settings between the lists.
---@param sendToOthers? boolean Mainly used for internal purposes to prevent infinite loops.
function List:connect(list, ignSettings, sendToOthers)
    expect(1, self, "table")
    expect(2, list, "table")
    expect(3, ignSettings, "boolean", "nil")
    expect(4, sendToOthers, "boolean", "nil")

    table.insert(self.connectedLists, list)
    if (sendToOthers ~= false) then
        for _, v in ipairs(self.connectedLists) do
            if (v ~= list) then
                v:connect(list, true, false)
                list:connect(v, true, false)
            end
        end
        list:connect(self, true, false)
    end
    if not (ignSettings) then
        list:setSelectable(self:getSelectable())
        list:setMultiSelectable(self:getMultiSelectable())
        list:setAutoScroll(self:getAutoScroll())
        list:setSelectedIndex(self:getSelectedIndex(), false)
        list:setScrollIndex(self:getScrollIndex(), false)
    end
    return self
end

--- Disconnects the list from another list.
---@param self List The element itself
---@param list List The list to disconnect.
---@param sendToOthers? boolean Mainly used for internal purposes to prevent infinite loops.
function List:disconnect(list, sendToOthers)
    expect(1, self, "table")
    expect(2, list, "table")
    expect(3, sendToOthers, "boolean", "nil")
    for i, v in ipairs(self.connectedLists) do
        if v == list then
            table.remove(self.connectedLists, i)
            if (sendToOthers ~= false) then
                list:disconnect(self, false)
            end
            return self
        end
    end
    return self
end

--- Returns the selected state of the item at the given index.
---@param self List The element itself
---@param index number The index of the item.
---@return boolean
function List:isItemSelected(index)
    expect(1, self, "table")
    expect(2, index, "number")
    if (self:getMultiSelectable()) then
        local selectedIndex = self:getSelectedIndex()
        for i, v in ipairs(selectedIndex) do
            if v == index then
                return true
            end
        end
    else
        if (self:getSelectedIndex() == index) then
            return true
        end
    end
    return false
end

--- Adds an item to the list.
---@param self List The element itself
---@param label string label for the item to add
---@param value any value for the item to add
---@param bg? integer The background color of the item.
---@param fg? integer The foreground color of the item.
function List:addItem(label, value, bg, fg)
    expect(1, self, "table")
    expect(2, label, "string")
    expect(4, bg, "color", "nil")
    expect(5, fg, "color", "nil")
    table.insert(self.items, {
        label = label,
        value = value,
        background = colors[bg] and colors[bg] or bg or self:getBackground(),
        foreground = colors[fg] and colors[fg] or fg or self:getForeground()
    })
    if (self:getAutoScroll()) then
        if (#self:getItems() > self:getHeight()) then
            self:setScrollIndex(#self:getItems() - self:getHeight() + 1)
        end
    end
    self:updateRender()
    return self
end

--- Updates the color of the item at the given index.
---@param self List The element itself
---@param index number The index of the item.
---@param fg? integer The foreground color of the item.
---@param bg? integer The background color of the item.
function List:updateColor(index, fg, bg)
    expect(1, self, "table")
    expect(2, index, "number")
    expect(3, fg, "color", "nil")
    expect(4, bg, "color", "nil")
    self.items[index].background = colors[bg] and colors[bg] or bg or self:getBackground()
    self.items[index].foreground = colors[fg] and colors[fg] or fg or self:getForeground()
    self:updateRender()
    return self
end

--- Removes the item from the list.
---@param self List The element itself
---@param item string The item to remove.
---@return List
function List:removeItem(item)
    expect(1, self, "table")
    expect(2, item, "string")
    for i, v in ipairs(self.items) do
        if v == item then
            table.remove(self.items, i)
            if (self:getAutoScroll()) then
                if (#self:getItems() > self:getHeight()) then
                    self:setScrollIndex(#self:getItems() - self:getHeight() + 1)
                end
            end
            self:updateRender()
            return self
        end
    end
    return self
end

--- Removes the item from the list by its index.
---@param self List The element itself
---@param index number The index of the item.
---@return List
function List:removeItemByIndex(index)
    expect(1, self, "table")
    expect(2, index, "number")
    table.remove(self.items, index)
    self:updateRender()
    return self
end

--- Clears the list.
---@param self List The element itself
---@return List
function List:clear()
    expect(1, self, "table")
    self.items = {}
    self:updateRender()
    return self
end

--- Selects the item.
---@param self List The element itself
---@param item string The item to select.
---@return List
function List:selectItem(item)
    expect(1, self, "table")
    expect(2, item, "string")
    for i, v in ipairs(self:getItems()) do
        if v == item then
            self:setSelectedIndex(i)
            self:fireEvent("change", v)
            return self
        end
    end
    self:updateRender()
    return self
end

--- Selects the item by its index.
---@param self List The element itself
---@param index number The index of the item.
---@return List
function List:selectItemByIndex(index)
    expect(1, self, "table")
    expect(2, index, "number")
    self:setSelectedIndex(index)
    self:fireEvent("change", self:getItems()[index])
    return self
end

--- Returns all selected items.
---@param self List The element itself
---@return table
function List:getSelectedItems()
    expect(1, self, "table")
    if (self:getMultiSelectable()) then
        local items = self:getItems()
        local selectedItems = {}
        for i, v in ipairs(self:getSelectedIndex()) do
            table.insert(selectedItems, items[v])
        end
        return selectedItems
    else
        return self:getItems()[self:getSelectedIndex()]
    end
end

---@protected
function List:mouse_click(button, x, y)
    if (VisualElement.mouse_click(self, button, x, y)) then
        if (button == 1) then
            local xPos, yPos = self:getPosition()
            local scrollIndex = self:getScrollIndex()
            local items = self:getItems()
            local clickedIndex = y - yPos + scrollIndex
            if clickedIndex >= 1 and clickedIndex <= #items then
                self:setSelectedIndex(clickedIndex)
                self:fireEvent("change", self:getSelectedItems())
            end
        end
        return true
    end
end

---@protected
function List:mouse_scroll(direction, x, y)
    if (VisualElement.mouse_scroll(self, direction, x, y)) then
        local w, h = self:getSize()
        local scrollIndex = self:getScrollIndex()
        local items = self:getItems()
        if direction == 1 and scrollIndex < #items - h + 1 then
            scrollIndex = scrollIndex + 1
        elseif direction == -1 and scrollIndex > 1 then
            scrollIndex = scrollIndex - 1
        end
        self:setScrollIndex(scrollIndex)
        self:updateRender()
        return true
    end
end

return List
