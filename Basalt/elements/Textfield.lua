local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local expect = require("expect").expect

---@class Textfield : VisualElement
local TextField = setmetatable({}, VisualElement)
TextField.__index = TextField

TextField:initialize("TextField")
TextField:addProperty("lines", "table", {""})
TextField:addProperty("lineIndex", "number", 1)
TextField:addProperty("scrollIndexX", "number", 1)
TextField:addProperty("scrollIndexY", "number", 1)
TextField:addProperty("cursorIndex", "number", 1)

--- Creates a new Textfield.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Textfield
---@protected
function TextField:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("TextField")
    newInstance:create("TextField")
    newInstance:setSize(10, 5)
    return newInstance
end

TextField:extend("Load", function(self)
    self:listenEvent("mouse_click")
    self:listenEvent("mouse_up")
    self:listenEvent("mouse_scroll")
end)

---@protected
function TextField:render()
    VisualElement.render(self)
    for i = 1, self.height do
        local visibleLine = ""
        if self.lines[i + self.scrollIndexY - 1] ~= nil then
            local line = self.lines[i + self.scrollIndexY - 1]
            visibleLine = line:sub(self.scrollIndexX, self.scrollIndexX + self.width - 1)
        end
        local space = (" "):rep(self.width - visibleLine:len())
        visibleLine = visibleLine .. space
        self:addTxt(1, i, visibleLine)
    end
end

---@protected
function TextField:lose_focus()
    VisualElement.lose_focus(self)
    self.parent:setCursor(false)
end

---@protected
function TextField:adjustScrollIndices(updateAccordingToCursor)
    if updateAccordingToCursor then
        if self.cursorIndex < self.scrollIndexX then
            self.scrollIndexX = self.cursorIndex
        elseif self.cursorIndex >= self.scrollIndexX + self.width then
            self.scrollIndexX = self.cursorIndex - self.width + 1
        end
        if self.lineIndex < self.scrollIndexY then
            self.scrollIndexY = self.lineIndex
        elseif self.lineIndex >= self.scrollIndexY + self.height then
            self.scrollIndexY = self.lineIndex - self.height + 1
        end
    end
    self.scrollIndexX = math.max(1, self.scrollIndexX)
    self.scrollIndexY = math.max(1, self.scrollIndexY)
end

--- Updates the cursor position.
function TextField:updateCursor()
    expect(1, self, "table")
    if self.cursorIndex >= self.scrollIndexX and self.cursorIndex < self.scrollIndexX + self.width and self.lineIndex >=
        self.scrollIndexY and self.lineIndex < self.scrollIndexY + self.height then
        self.parent:setCursor(true, self:getX() + self.cursorIndex - self.scrollIndexX,
            self:getY() + self.lineIndex - self.scrollIndexY, self:getForeground())
    else
        self.parent:setCursor(false)
    end
end

--- Adds a line to the textfield.
---@param self Textfield
---@param line string The line to add.
---@return Textfield
function TextField:addLine(line)
    expect(1, self, "table")
    expect(2, line, "string")
    table.insert(self.lines, line)
    return self
end

--- Removes a line from the textfield.
---@param self Textfield
---@param index number The index of the line to remove.
---@return Textfield
function TextField:removeLine(index)
    expect(1, self, "table")
    expect(2, index, "number")
    table.remove(self.lines, index)
    return self
end

--- Clears the textfield.
---@param self Textfield
---@return Textfield
function TextField:clear()
    expect(1, self, "table")
    self.lines = {}
    return self
end

--- Gets a line from the textfield.
---@param self Textfield
---@param index number The index of the line to get.
function TextField:getLine(index)
    expect(1, self, "table")
    expect(2, index, "number")
    return self.lines[index]
end

--- Sets a line in the textfield.
---@param self Textfield
---@param index number The index of the line to set.
function TextField:setLine(index, line)
    expect(1, self, "table")
    expect(2, index, "number")
    expect(3, line, "string")
    self.lines[index] = line
    return self
end

---@protected
function TextField:mouse_click(button, x, y)
    if (VisualElement.mouse_click(self, button, x, y)) then
        if (button == 1) then
            if (#self.lines > 0) then
                self.lineIndex = math.min(y - self:getY() + self.scrollIndexY, #self.lines)
                self.cursorIndex = math.min(x - self:getX() + self.scrollIndexX, self.lines[self.lineIndex]:len() + 1)
                self:adjustScrollIndices(true)
            else
                self.lineIndex = 1
                self.cursorIndex = 1
            end
        end
        return true
    end
end

---@protected
function TextField:mouse_up(button, x, y)
    if (VisualElement.mouse_up(self, button, x, y)) then
        if (button == 1) then
            self:updateCursor()
        end
        return true
    end
end

---@protected
function TextField:mouse_scroll(direction, x, y)
    if (VisualElement.mouse_scroll(self, direction, x, y)) then
        if direction == 1 then
            self.scrollIndexY = math.min(#self.lines - self.height + 1, self.scrollIndexY + 1)
        elseif direction == -1 then
            self.scrollIndexY = math.max(1, self.scrollIndexY - 1)
        end
        self:adjustScrollIndices(false)
        self:updateCursor()
        self:updateRender()
        return true
    end
end

---@protected
function TextField:key(key)
    if (VisualElement.key(self, key)) then
        local line = self.lines[self.lineIndex]
        if key == keys.enter then
            local before = line:sub(1, self.cursorIndex - 1)
            local after = line:sub(self.cursorIndex, -1)
            self.lines[self.lineIndex] = before
            table.insert(self.lines, self.lineIndex + 1, after)
            self.lineIndex = self.lineIndex + 1
            self.cursorIndex = 1
        elseif key == keys.backspace then
            if line ~= "" and self.cursorIndex > 1 then
                local before = line:sub(1, self.cursorIndex - 2)
                local after = line:sub(self.cursorIndex, -1)
                self.lines[self.lineIndex] = before .. after
                self.cursorIndex = self.cursorIndex - 1
            elseif line == "" and self.lineIndex > 1 then
                table.remove(self.lines, self.lineIndex)
                self.lineIndex = self.lineIndex - 1
                self.cursorIndex = self.lines[self.lineIndex]:len() + 1
            elseif self.cursorIndex == 1 and self.lineIndex > 1 then
                self.cursorIndex = self.lines[self.lineIndex - 1]:len() + 1
                self.lines[self.lineIndex - 1] = self.lines[self.lineIndex - 1] .. self.lines[self.lineIndex]
                table.remove(self.lines, self.lineIndex)
                self.lineIndex = self.lineIndex - 1
            end
        elseif key == keys.delete then
            if line ~= "" and self.cursorIndex <= line:len() then
                local before = line:sub(1, self.cursorIndex - 1)
                local after = line:sub(self.cursorIndex + 1, -1)
                self.lines[self.lineIndex] = before .. after
            elseif line == "" and self.lineIndex < #self.lines then
                table.remove(self.lines, self.lineIndex)
            elseif self.cursorIndex == line:len() + 1 and self.lineIndex < #self.lines then
                self.lines[self.lineIndex] = self.lines[self.lineIndex] .. self.lines[self.lineIndex + 1]
                table.remove(self.lines, self.lineIndex + 1)
            end
        elseif key == keys.up and self.lineIndex > 1 then
            self.lineIndex = self.lineIndex - 1
            self.cursorIndex = math.min(self.cursorIndex, self.lines[self.lineIndex]:len() + 1)
        elseif key == keys.down and self.lineIndex < #self.lines then
            self.lineIndex = self.lineIndex + 1
            self.cursorIndex = math.min(self.cursorIndex, self.lines[self.lineIndex]:len() + 1)
        elseif key == keys.left then
            self.cursorIndex = math.max(1, self.cursorIndex - 1)
        elseif key == keys.right then
            self.cursorIndex = math.min(line:len() + 1, self.cursorIndex + 1)
        end
        self:adjustScrollIndices(true)
        self:updateCursor()
        self:updateRender()
        return true
    end
end

---@protected
function TextField:char(char)
    if (VisualElement.char(self, char)) then
        local line = self.lines[self.lineIndex]
        local before = line:sub(1, self.cursorIndex - 1)
        local after = line:sub(self.cursorIndex, -1)
        self.lines[self.lineIndex] = before .. char .. after
        self.cursorIndex = self.cursorIndex + 1
        self:adjustScrollIndices(true)
        self:updateCursor()
        self:updateRender()
        return true
    end
end

return TextField
