local Element = require("basaltLoader").load("BasicElement")
local split = require("utils").splitString
local subText = require("utils").subText
local expect = require("expect").expect

--- @class VisualElement: BasicElement
local VisualElement = setmetatable({}, Element)
VisualElement.__index = VisualElement

VisualElement:initialize("VisualElement")

VisualElement:addProperty("background", "color", colors.black)
VisualElement:addProperty("foreground", "color", colors.white)
VisualElement:addProperty("x", "number", 1, nil, function(self, value)
    self:reposition("x", value)
end)
VisualElement:addProperty("y", "number", 1, nil, function(self, value)
    self:reposition("y", value)
end)
VisualElement:combineProperty("Position", "X", "Y")
VisualElement:addProperty("visible", "boolean", true)
VisualElement:addProperty("width", "number", 1, nil, function(self, value)
    self:resize("width", value)
end)
VisualElement:addProperty("height", "number", 1, nil, function(self, value)
    self:resize("height", value)
end)

VisualElement:addProperty("preRenderData", "table", {})
VisualElement:addProperty("postRenderData", "table", {})

VisualElement:combineProperty("Size", "width", "height")
VisualElement:addProperty("transparent", "boolean", false)
VisualElement:addProperty("ignoreOffset", "boolean", false)
VisualElement:addProperty("focused", "boolean", false, nil, function(self, value)
    if (value) then
        self:get_focus()
    else
        self:lose_focus()
    end
end)

VisualElement:addListener("click", "mouse_click")
VisualElement:addListener("drag", "mouse_drag")
VisualElement:addListener("scroll", "mouse_scroll")
VisualElement:addListener("hover", "mouse_move")
VisualElement:addListener("leave", "mouse_move2")
VisualElement:addListener("clickUp", "mouse_up")
VisualElement:addListener("key", "key")
VisualElement:addListener("keyUp", "key_up")
VisualElement:addListener("char", "char")
VisualElement:addListener("getFocus", "get_focus")
VisualElement:addListener("loseFocus", "lose_focus")
VisualElement:addListener("release", "mouse_release")
VisualElement:addListener("resize", "resize")
VisualElement:addListener("reposition", "reposition")

--- Creates a new visual element.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return VisualElement
---@protected
function VisualElement:new(id, parent, basalt)
    local newInstance = Element:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:create("VisualElement")
    newInstance:setType("VisualElement")
    return newInstance
end

-- Calls the pre-render function of the element. Can be overwritten to alter element pre-rendering.
---@param self VisualElement
function VisualElement:preRender()
end

--- Calls the render function of the element. Can be overwritten to alter element rendering. (This function is used to render the element.)
---@param self VisualElement
function VisualElement:render()
    local w, h = self:getSize()
    self:addTextBox(1, 1, w, h, " ")
    self:addBackgroundBox(1, 1, w, h, self:getBackground())
    self:addForegroundBox(1, 1, w, h, self:getForeground())
end

--- Calls the post-render function of the element. Can be overwritten to alter element post-rendering.
---@param self VisualElement
function VisualElement:postRender()
end

-- Calls the pre-render, render and post-render functions of the element. Please do not overwrite this function.
---@protected
function VisualElement:processRender()
    self:preRender()
    for _, v in pairs(self:getPreRenderData()) do
        self["add" .. v.cmd](self, unpack(v.args))
    end
    self:render()
    for _, v in pairs(self:getPostRenderData()) do
        self["add" .. v.cmd](self, unpack(v.args))
    end
    self:postRender()
end

local preF = "pre"
for _ = 1, 2 do
    for _, v in pairs({"Txt", "Bg", "Fg"}) do
        VisualElement[preF .. v] = function(self, x, y, text)
            local curData = self:getPreRenderData()
            if (preF == "post") then
                curData = self:getPostRenderData()
            end
            table.insert(curData, {
                cmd = v,
                args = {x, y, text}
            })
            self:updateRender()
            return self
        end
    end
    for _, v in pairs({"BackgroundBox", "TextBox", "ForegroundBox"}) do
        VisualElement[preF .. v] = function(self, x, y, w, h, col)
            local curData = self:getPreRenderData()
            if (preF == "post") then
                curData = self:getPostRenderData()
            end
            table.insert(curData, {
                cmd = v,
                args = {x, y, w, h, col}
            })
            self:updateRender()
            return self
        end
    end
    VisualElement[preF .. "Blit"] = function(self, x, y, t, f, b)
        if (#t ~= #f) or (#t ~= #b) then
            error("Text, Foreground and Background must have the same length!")
        end
        local curData = self:getPreRenderData()
        if (preF == "post") then
            curData = self:getPostRenderData()
        end
        table.insert(curData, {
            cmd = "Blit",
            args = {x, y, t, f, b}
        })
        self:updateRender()
        return self
    end
    preF = "post"
end

--- Clears the pre-render data of the element.
---@return VisualElement
function VisualElement:clearPreRender()
    expect(1, self, "table")
    self:setPreRenderData({})
    self:updateRender()
    return self
end

--- Clears the post-render data of the element.
---@return VisualElement
function VisualElement:clearPostRender()
    expect(1, self, "table")
    self:setPostRenderData({})
    self:updateRender()
    return self
end

--- Calculates the position of the element (including parent's offset).
---@return number, number
function VisualElement:calculatePosition()
    local x, y = self:getPosition()
    local ignoreOffset = self:getIgnoreOffset()
    if not (ignoreOffset) then
        if self.parent ~= nil then
            local xO, yO = self.parent:getOffset()
            x = x - xO
            y = y - yO
        end
    end
    return x, y
end

for _, v in pairs({"BackgroundBox", "TextBox", "ForegroundBox"}) do
    VisualElement["add" .. v] = function(self, x, y, w, h, col)
        local obj = self.parent or self
        local xPos, yPos = self:calculatePosition()
        obj["draw" .. v](obj, x + xPos - 1, y + yPos - 1, w, h, col)
    end
end

for _, v in pairs({"Txt", "Bg", "Fg"}) do
    VisualElement["add" .. v] = function(self, x, y, str, ignoreElementSize)
        local obj = self.parent or self
        local xPos, yPos = self:calculatePosition()
        local w, h = self:getSize()
        local transparent = self:getTransparent()
        if not (ignoreElementSize) then
            str, x = subText(str, x, w)
        end
        if not (transparent) then
            obj["set" .. v](obj, x + xPos - 1, y + yPos - 1, str)
            return
        end
        local t = split(str)
        for _, v in pairs(t) do
            if (v == "Txt") then
                if (v.value ~= "") and (v.value ~= "\0") then
                    obj["set" .. v](obj, x + v.x + xPos - 2, y + yPos - 1, v.value)
                end
            else
                if (v.value ~= "") and (v.value ~= " ") then
                    obj["set" .. v](obj, x + v.x + xPos - 2, y + yPos - 1, v.value)
                end
            end
        end
    end
end

--- @protected
function VisualElement:addBlit(x, y, t, f, b)
    local obj = self.parent or self
    local xPos, yPos = self:calculatePosition()
    local transparent = self:getTransparent()
    if not (transparent) then
        obj:blit(x + xPos - 1, y + yPos - 1, t, f, b)
        return
    end
    local _text = split(t, "\0")
    local _fg = split(f)
    local _bg = split(b)
    for _, v in pairs(_text) do
        if (v.value ~= "") or (v.value ~= "\0") then
            obj:setTxt(x + v.x + xPos - 2, y + yPos - 1, v.value)
        end
    end
    for _, v in pairs(_bg) do
        if (v.value ~= "") or (v.value ~= " ") then
            obj:setBg(x + v.x + xPos - 2, y + yPos - 1, v.value)
        end
    end
    for _, v in pairs(_fg) do
        if (v.value ~= "") or (v.value ~= " ") then
            obj:setFg(x + v.x + xPos - 2, y + yPos - 1, v.value)
        end
    end
end

--- Returns the relative position of the element or the given coordinates.
---@param x? number -- The x position.
---@param y? number -- The y position.
---@return number, number
function VisualElement:getRelativePosition(x, y)
    expect(1, self, "table")
    expect(2, x, "number", "nil")
    expect(3, y, "number", "nil")
    if (x == nil) and (y == nil) then
        x, y = self:calculatePosition()
    end
    local xObj, yObj = self:calculatePosition()
    local newX = x - (xObj - 1)
    local newY = y - (yObj - 1)
    return newX, newY
end

--- Returns the absolute position of the element or the given coordinates.
---@param x? number -- The x position.
---@param y? number -- The y position.
function VisualElement:getAbsolutePosition(x, y)
    expect(1, self, "table")
    expect(2, x, "number", "nil")
    expect(3, y, "number", "nil")
    if (x == nil) and (y == nil) then
        x, y = self:calculatePosition()
    end
    local xObj, yObj = self:calculatePosition()
    local newX = x + (xObj - 1)
    local newY = y + (yObj - 1)
    if self:isType("Container") then
        local xO, yO = self:getOffset()
        newX = newX + xO
        newY = newY + yO
    end
    if self.parent ~= nil then
        newX, newY = self.parent:getAbsolutePosition(newX, newY)
    end
    return newX, newY
end

--- Returns whether the given coordinates are inside the element.
---@param x number -- The x position.
---@param y number -- The y position.
---@return boolean
function VisualElement:isInside(x, y)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    local pX, pY = self:calculatePosition()
    local pW, pH = self:getSize()
    local visible, enabled = self:getVisible(), self:getEnabled()
    return x >= pX and x <= pX + pW - 1 and y >= pY and y <= pY + pH - 1 and visible and enabled
end

---@protected
function VisualElement:mouse_click(btn, x, y)
    if self:isInside(x, y) then
        self:setProperty("clicked", true)
        self:setProperty("dragging", true)
        self:updateRender()
        self:fireEvent("click", btn, self:getRelativePosition(x, y))
        return true
    end
end

---@protected
function VisualElement:mouse_drag(btn, x, y)
    if self:getProperty("dragging") then
        self:fireEvent("drag", btn, self:getRelativePosition(x, y))
        return true
    end
end

---@protected
function VisualElement:mouse_up(btn, x, y)
    if self:isInside(x, y) then
        self:fireEvent("clickUp", btn, self:getRelativePosition(x, y))
        self:updateRender()
        return true
    end
end

---@protected
function VisualElement:mouse_release(btn, x, y)
    self:setProperty("dragging", false)
    self:setProperty("clicked", false)
    self:fireEvent("release", btn, self:getRelativePosition(x, y))
    return true
end

---@protected
function VisualElement:mouse_scroll(direction, x, y)
    if self:isInside(x, y) then
        self:fireEvent("scroll", direction, self:getRelativePosition(x, y))
        return true
    end
end

---@protected
function VisualElement:mouse_move(_, x, y)
    if self:isInside(x, y) then
        self:setProperty("hovered", true)
        self:updateRender()
        self:fireEvent("hover", self:getRelativePosition(x, y))
        return true
    end
    if (self:getProperty("hovered")) then
        self:setProperty("hovered", false)
        self:updateRender()
        self:fireEvent("leave", self:getRelativePosition(x, y))
        return true
    end
end

---@protected
function VisualElement:reposition(_, prop, value)
    self:fireEvent("reposition", prop, value)
end

---@protected
function VisualElement:resize(_, prop, value)
    self:fireEvent("resize", prop, value)
end

---@protected
function VisualElement.get_focus(self)
    self:fireEvent("getFocus")
end

---@protected
function VisualElement.lose_focus(self)
    self:fireEvent("loseFocus")
end

for _, v in pairs({"key", "key_up", "char"}) do
    VisualElement[v] = function(self, ...)
        if (self.enabled) and (self.visible) then
            if (self.parent == nil) or (self:getFocused()) then
                self:fireEvent(v, ...)
                return true
            end
        end
    end
end

return VisualElement
