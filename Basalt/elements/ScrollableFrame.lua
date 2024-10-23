local VisualElement = require("basaltLoader").load("VisualElement")
local Container = require("basaltLoader").load("Container")

local expect = require("expect").expect

---@class ScrollableFrame : Container
local ScrollableFrame = setmetatable({}, Container)
ScrollableFrame.__index = ScrollableFrame

ScrollableFrame:initialize("ScrollableFrame")
ScrollableFrame:addProperty("scrollDirection", "string", "vertical")
ScrollableFrame:addProperty("autoScroll", "boolean", true)
ScrollableFrame:addProperty("scrollAmount", "number", 10)

--- Creates a new ScrollableFrame.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return ScrollableFrame
---@protected
function ScrollableFrame:new(id, parent, basalt)
    local newInstance = Container:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("ScrollableFrame")
    newInstance:create("ScrollableFrame")
    newInstance:setZ(10)
    newInstance:setSize(30, 15)
    return newInstance
end

ScrollableFrame:extend("Load", function(self)
    self:listenEvent("mouse_scroll")
end)

local function getScrollableVerticalAmount(self)
    local amount = 0
    for _, v in pairs(self:getChildren()) do
        amount = math.max(amount, v:getY() + v:getHeight())
    end
    return amount - self:getHeight()
end

local function getScrollableHorizontalAmount(self)
    local amount = 0
    for k, v in pairs(self:getChildren()) do
        amount = math.max(amount, v:getX() + v:getWidth())
    end
    return amount - self:getWidth()
end

--- Scrolls the frame vertically.
---@param self ScrollableFrame The element itself
---@param amount number The amount to scroll
---@return ScrollableFrame
function ScrollableFrame:scrollVertical(amount)
    expect(1, self, "table")
    expect(2, amount, "number")
    local autoScroll = self:getAutoScroll()
    local maxScrollAmount = 0
    local currentScroll = self:getYOffset()
    local height = self:getHeight()
    if (autoScroll) then
        maxScrollAmount = getScrollableVerticalAmount(self)
    else
        maxScrollAmount = self:getScrollAmount() + height
    end

    if (amount > 0) then
        if (currentScroll < maxScrollAmount) then
            self:setYOffset(currentScroll + amount)
        end
    else
        if (currentScroll > 0) then
            self:setYOffset(currentScroll + amount)
        end
    end

    self:updateRender()
    return self
end

--- Returns the amount that can be scrolled.
---@param self ScrollableFrame The element itself
---@return number
function ScrollableFrame:getAllowedScrollAmount()
    expect(1, self, "table")
    local scrollDirection = self:getScrollDirection()
    if not (self:getAutoScroll()) then
        return self:getScrollAmount()
    end
    if (scrollDirection == "vertical") then
        return getScrollableVerticalAmount(self)
    else
        return getScrollableHorizontalAmount(self)
    end
end

--- Scrolls the frame horizontally.
---@param self ScrollableFrame The element itself
---@param amount number The amount to scroll
---@return ScrollableFrame
function ScrollableFrame:scrollHorizontal(amount)
    expect(1, self, "table")
    expect(2, amount, "number")
    local autoScroll = self:getAutoScroll()
    local maxScrollAmount = 0
    local currentScroll = self:getXOffset()
    local width = self:getWidth()
    if (autoScroll) then
        maxScrollAmount = getScrollableHorizontalAmount(self)
    else
        maxScrollAmount = self:getScrollAmount() + width
    end

    if (amount > 0) then
        if (currentScroll < maxScrollAmount) then
            self:setXOffset(currentScroll + amount)
        end
    else
        if (currentScroll > 0) then
            self:setXOffset(currentScroll + amount)
        end
    end

    self:updateRender()
    return self
end

---@protected
function ScrollableFrame:mouse_scroll(direction, x, y)
    if (VisualElement.mouse_scroll(self, direction, x, y)) then
        local visibleChildren = self:getVisibleChildrenEvents("mouse_scroll")
        for _, child in pairs(visibleChildren) do
            if (child and child.mouse_scroll ~= nil) then
                local relX, relY = self:getRelativePosition(x, y)
                if (child.mouse_scroll(child, direction, relX, relY)) then
                    self:setFocusedChild(child, true)
                    return true
                end
            end
        end
        local scrollDirection = self:getScrollDirection()
        if (scrollDirection == "vertical") then
            self:scrollVertical(direction)
        else
            self:scrollHorizontal(direction)
        end
        self:setFocusedChild(nil, true)
        return true
    end
end

return ScrollableFrame
