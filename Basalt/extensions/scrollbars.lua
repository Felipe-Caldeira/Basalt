local expect = require("expect").expect

---@class Scrollbar
local Scrollbar = {}
Scrollbar.__index = Scrollbar

local max, min, floor = math.max, math.min, math.floor

---@param self Scrollbar
---@return Scrollbar
function Scrollbar.new(element)
    local new = setmetatable({}, Scrollbar)
    new.direction = "vertical"
    new.barColor = element:getForeground()
    new.barSymbolColor = element:getForeground()
    new.barSymbol = "\127"
    new.element = element
    new.baseRender = element.render
    new.baseMouseClick = element.mouse_click
    new.baseMouseDrag = element.mouse_drag
    new.baseMouseUp = element.mouse_up
    new.isDragging = false
    new.arrowUp = "\30"
    new.arrowDown = "\31"
    new.arrorLeft = "\17"
    new.arrowRight = "\16"
    new.arrowsEnabled = true
    return new
end

---@param self Scrollbar
---@return Scrollbar
function Scrollbar:enable()
    expect(1, self, "table")
    self.element.render = function()
        return self.render(self)
    end
    self.element.mouse_click = function(_, btn, x, y)
        return self.mouse_click(self, btn, x, y)
    end
    self.element.mouse_drag = function(_, btn, x, y)
        return self.mouse_drag(self, btn, x, y)
    end
    self.element.mouse_up = function(_, btn, x, y)
        return self.mouse_up(self, btn, x, y)
    end
    self.element:listenEvent("mouse_scroll")
    self.element:listenEvent("mouse_up")
    self.element:listenEvent("mouse_drag")
    self.element:listenEvent("mouse_click")
    self.element:updateRender()
    return self
end

function Scrollbar:disable()
    expect(1, self, "table")
    self.element.render = self.baseRender
    self.element.mouse_click = self.baseMouseClick
    self.element.mouse_drag = self.baseMouseDrag
    self.element.mouse_up = self.baseMouseUp
    self.element:updateRender()
    return self
end

function Scrollbar:getKnobSize()
    expect(1, self, "table")
    local element = self.element
    local scrollAmount = element:getYOffset()
    local allowedScrollAmount = element:getAllowedScrollAmount()
    local _, height = element:getSize()
    if self.arrowsEnabled then
        height = height - 1
    end

    local knobSize = height - (height - allowedScrollAmount)

    local knobY = floor((scrollAmount / allowedScrollAmount) * (height - knobSize))

    if self.arrowsEnabled then
        knobY = knobY + 1
        knobSize = knobSize - 1
    end

    return knobSize, knobY + 1
end

---@param self Scrollbar
function Scrollbar:render()
    self.baseRender(self.element)
    local element = self.element
    local x, y = element:getPosition()
    local width, height = element:getSize()
    local knobHeight, knobY = self:getKnobSize()
    local background, foreground = element:getBackground(), element:getForeground()

    element:addBackgroundBox(width, 1, 1, height, background)
    element:addForegroundBox(width, 1, 1, height, foreground)
    if (self.arrowsEnabled) then
        element:addTxt(width, height, self.arrowDown, true)
        element:addTxt(width, 1, self.arrowUp, true)
        element:addTextBox(width, 2, 1, height - 2, self.barSymbol)
    else
        element:addTextBox(width, 1, 1, height, self.barSymbol)
    end

    element:addBackgroundBox(width, knobY, 1, knobHeight, self.barColor)
    element:addTextBox(width, knobY, 1, knobHeight, self.barSymbol)
    element:addForegroundBox(width, knobY, 1, knobHeight, self.barSymbolColor)
    return self
end

---@param self Scrollbar
function Scrollbar:mouse_click(btn, x, y)
    if (self.baseMouseClick(self.element, btn, x, y)) then
        local element = self.element
        local width, height = element:getSize()
        local yOffset = element:getYOffset()
        local allowedScrollAmount = element:getAllowedScrollAmount()
        local knobSize, knobY = self:getKnobSize()
        local xPos, yPos = element:getPosition()
        x = x - xPos + 1
        y = y - yPos + 1
        if (self.direction == "vertical") then
            if (x == width) then
                self.isDragging = true
                if (yOffset <= allowedScrollAmount) then
                    if (y == height) then -- Arrow Up
                        element:setYOffset(min(yOffset + 1, allowedScrollAmount))
                    elseif (y == 1) then -- Arrow Down
                        element:setYOffset(max(yOffset - 1, 0))
                    end
                    if (y > 1 and y < height) then
                        if (y < knobY) or (y > knobY + knobSize - 1) then
                            local scrollAmount = (y - knobSize / 2) / (height - knobSize) * allowedScrollAmount
                            scrollAmount = min(max(scrollAmount, 0), allowedScrollAmount)
                            element:setYOffset(floor(scrollAmount + 0.5))
                        end
                    end
                end
            end
        end
        return true
    end
end

function Scrollbar:mouse_up(btn, x, y)
    self.isDragging = false
    return self.baseMouseUp(self.element, btn, x, y)
end

---@param self Scrollbar
function Scrollbar:mouse_drag(btn, x, y)
    if (self.isDragging) then
        local element = self.element
        local width, height = element:getSize()
        local yOffset = element:getYOffset()
        local allowedScrollAmount = element:getAllowedScrollAmount()
        local knobSize, knobY = self:getKnobSize()
        local xPos, yPos = element:getPosition()
        x = x - xPos + 1
        y = y - yPos + 1
        if (self.direction == "vertical") then
            if (yOffset <= allowedScrollAmount) then
                local scrollAmount = (y) / (height - knobSize) * allowedScrollAmount
                scrollAmount = min(max(scrollAmount, 0), allowedScrollAmount)
                element:setYOffset(floor(scrollAmount + 0.5))
            end
        end
        return true
    end
    return self.baseMouseDrag(self.element, btn, x, y)
end

---@class ScrollableFrame
local ScrollableFrame = {}
---@protected
function ScrollableFrame.extensionProperties(original)
    original:initialize("ScrollableFrame")
    original:addProperty("scrollbar", "table", nil)
end

--- Enable the scrollbar for the ScrollableFrame
---@param self ScrollableFrame
---@return ScrollableFrame
function ScrollableFrame.enableScrollbar(self)
    if (self:getScrollbar() == nil) then
        self:setScrollbar(Scrollbar.new(self))
    end
    self:getScrollbar():enable()
    return self
end

--- Disable the scrollbar for the ScrollableFrame
---@param self ScrollableFrame
---@return ScrollableFrame
function ScrollableFrame.disableScrollbar(self)
    if (self:getScrollbar() ~= nil) then
        self:getScrollbar():disable()
    end
    return self
end

function ScrollableFrame.init(original)
    original:extend("Load", function(self)
        if (self:getScrollbar() == nil) then
            self:setScrollbar(Scrollbar.new(self))
        end
        return self
    end)
end

return {
    ScrollableFrame = ScrollableFrame
}
