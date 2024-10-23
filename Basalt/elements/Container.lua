local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local uuid = require("utils").uuid
local subText = require("utils").subText
local expect = require("expect").expect

--- @class Container : VisualElement
local Container = setmetatable({}, VisualElement)
Container.__index = Container

local renderSystem = require("renderSystem")

Container:initialize("Container")
Container:addProperty("term", "table", nil, false, function(self, value)
    if (value ~= nil) then
        value.__noCopy = true
    end
    self.renderSystem = renderSystem(value)
end, function(self)
    if (self:getParent() ~= nil) then
        return self:getParent():getTerm()
    end
    return self.term
end)
Container:addProperty("children", "table", {})
Container:addProperty("childrenEvents", "table", {})
Container:addProperty("visibleChildrenEvents", "table", {})
Container:addProperty("isVisibleChildrenEventsUpdated", "table", {})
Container:addProperty("cursorBlink", "boolean", false)
Container:addProperty("cursorColor", "color", colors.white)
Container:addProperty("cursorX", "number", 1)
Container:addProperty("cursorY", "number", 1)
Container:addProperty("focusedChild", "table", nil, false, function(self, value)
    local curFocus = self:getFocusedChild()
    if (curFocus ~= value) then
        if (curFocus ~= nil) then
            curFocus:setFocused(false, true)
        end
        if (value ~= nil) then
            value:setFocused(true, true)
        end
    end
    return value
end)
Container:addProperty("xOffset", "number", 0, nil, function(self, value)
    self:forceVisibleChildrenUpdate()
end)
Container:addProperty("yOffset", "number", 0, nil, function(self, value)
    self:forceVisibleChildrenUpdate()
end)
Container:combineProperty("Offset", "xOffset", "yOffset")

local sub, max = string.sub, math.max

local function addElement(self, key)
    if (key:sub(1, 3) == "add") and (Container[key] == nil) then
        local elementName = key:sub(4)
        if (loader.getElementList()[elementName]) then
            return function(self, id, x, y, w, h, bg, fg)
                local uid = id
                if (type(id) == "table") then
                    uid = id.name
                    id.name = nil
                end
                local element = self.basalt.create(uid or uuid(), self, elementName, type(id) == "table" and id or nil)
                self:addChild(element, element:getZ())
                if (x ~= nil) then
                    element:setX(x)
                end
                if (y ~= nil) then
                    element:setY(y)
                end
                if (w ~= nil) then
                    element:setWidth(w)
                end
                if (h ~= nil) then
                    element:setHeight(h)
                end
                if (bg ~= nil) then
                    element:setBackground(bg)
                end
                if (fg ~= nil) then
                    element:setForeground(fg)
                end
                return element
            end
        end
    end
    return Container[key]
end

--- Creates a new container.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Container
---@protected
function Container:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = addElement
    newInstance:create("Container")
    newInstance:setType("Container")
    return newInstance
end

function Container:postRender()
    if (self:getTerm() == nil) then
        -- return
    end
    local visibleChildren = self:getVisibleChildren()
    if self.parent == nil then
        if self.updateRendering then
            VisualElement.postRender(self)
            for _, element in pairs(visibleChildren) do
                element:processRender()
            end
        end
    else
        VisualElement.postRender(self)
        for _, element in pairs(visibleChildren) do
            element:processRender()
        end
    end
end

---@protected
function Container:processRender()
    VisualElement.processRender(self)
    if (self.updateRendering) then
        if (self.renderSystem ~= nil) then
            self.renderSystem.update()
            self.updateRendering = false
        end
    end
end

--- Gets all visible children of the container.
--- @param self Container
--- @return table
function Container:getVisibleChildren()
    expect(1, self, "table")
    if (self.isVisibleChildrenUpdated) then
        return self.visibleChildren
    end

    local visibleChildren = {}
    for _, child in ipairs(self.children) do
        if self:isChildVisible(child) then
            table.insert(visibleChildren, child)
        end
    end
    self.visibleChildren = visibleChildren
    self.isVisibleChildrenUpdated = true
    return visibleChildren
end

--- Checks if a child is visible inside the container.
--- @param self Container
--- @param child table The child to check.
--- @return boolean 
function Container:isChildVisible(child)
    expect(1, self, "table")
    expect(2, child, "table")
    local childX, childY = child:getPosition()
    local childWidth, childHeight = child:getSize()
    local containerWidth, containerHeight = self:getSize()
    local xOffset, yOffset = self:getOffset()

    childX = childX - xOffset
    childY = childY - yOffset

    return child:getVisible() and childX <= containerWidth and childY <= containerHeight and childX + childWidth > 0 and
               childY + childHeight > 0
end

--- Forces to render all visible childrens.
function Container:forceVisibleChildrenUpdate()
    expect(1, self, "table")
    self.isVisibleChildrenUpdated = false
    for k, v in pairs(self.isVisibleChildrenEventsUpdated) do
        self.isVisibleChildrenEventsUpdated[k] = false
    end
end

--- Gets a child by its id.
--- @param self Container
--- @param id string The id of the child.
function Container:getChild(id)
    expect(1, self, "table")
    expect(2, id, "string", "table")
    for _, childObj in ipairs(self.children) do
        if childObj:getId() == id then
            return childObj
        end
    end
end

--- Gets a nested element with the specified id 
--- @param self Container
--- @param id string The id of the element.
function Container:getElementById(id)
    expect(1, self, "table")
    expect(2, id, "string", "table")

    for _, childObj in ipairs(self.children) do
        if childObj:getId() == id then
            return childObj
        end

        if childObj.children then
            local foundObj = childObj:getElementById(id)
            if foundObj then
                return foundObj
            end
        end
    end
end

--- Gets all nested elements with the specified type 
--- @param self Container
--- @param type string The type of the elements.
function Container:getElementsByType(targetType)
    expect(1, self, "table")
    expect(2, targetType, "string")

    local matchingElements = {}

    local function collectMatchingElements(ele, depth)
        if ele.__debugElement then return end
        if ele:getType() == targetType then 
            table.insert(matchingElements, ele)
        end
        if ele.children then
            for _, childObj in ipairs(ele.children) do
                collectMatchingElements(childObj, depth + 1)
            end
        end
    end

    collectMatchingElements(self, 0)
    return matchingElements
end

--- Adds a child to the container.
--- @param self Container
--- @param child table The child to add.
--- @param childZ? number The z index of the child.
--- @return table
function Container:addChild(child, childZ)
    expect(1, self, "table")
    expect(2, child, "table")
    expect(3, childZ, "number", "nil")
    if (self:getChild(child) ~= nil) then
        return
    end

    local inserted = false
    childZ = childZ or child:getZ()

    for i, registeredChild in ipairs(self.children) do
        if childZ < registeredChild:getZ() then
            table.insert(self.children, i, child)
            inserted = true
            break
        end
    end
    if not inserted then
        table.insert(self.children, child)
    end

    child:setParent(self)
    child.basalt = self.basalt
    child:init()
    self.isVisibleChildrenUpdated = false
    return child
end

--- Removes a child from the container.
--- @param self Container
--- @param id string The id of the child.
function Container:removeChild(id)
    expect(1, self, "table")
    expect(2, id, "string", "table")
    if (type(id) == "table") then
        id = id:getId()
    end
    for i, childObj in ipairs(self.children) do
        if childObj:getId() == id then
            table.remove(self.children, i)
            break
        end
    end
    self.isVisibleChildrenUpdated = false
end

--- Checks if a certain event is registered for a child.
--- @param self Container
--- @param event string The event to check.
--- @param child table The child to check.
--- @return boolean
function Container:isEventRegistered(event, child)
    expect(1, self, "table")
    expect(2, event, "string")
    expect(3, child, "table")
    if (self.childrenEvents[event] == nil) then
        return false
    end
    for _, registeredChild in ipairs(self.childrenEvents[event]) do
        if registeredChild == child then
            return true
        end
    end
    return false
end

--- Adds an event to a child.
--- @param self Container
--- @param event string The event to add.
--- @param child table The child to add the event to.
function Container:addEvent(event, child)
    expect(1, self, "table")
    expect(2, event, "string")
    expect(3, child, "table")
    self.childrenEvents[event] = self.childrenEvents[event] or {}
    if (self:isEventRegistered(event, child)) then
        return
    end
    local inserted = false
    for i, registeredChild in ipairs(self.childrenEvents[event]) do
        if child:getZ() >= registeredChild:getZ() then
            table.insert(self.childrenEvents[event], i, child)
            inserted = true
            break
        end
    end

    if not inserted then
        table.insert(self.childrenEvents[event], child)
    end
    if (self.parent ~= nil) then
        self.parent:addEvent(event, self)
    end
    self.isVisibleChildrenEventsUpdated[event] = false
end

--- Removes an event from a child.
--- @param self Container
--- @param event string The event to remove.
--- @param child table The child to remove the event from.
function Container:removeEvent(event, child)
    expect(1, self, "table")
    expect(2, event, "string")
    expect(3, child, "table")
    if (self.childrenEvents[event] == nil) then
        return false
    end
    for i, registeredChild in ipairs(self.childrenEvents[event]) do
        if registeredChild == child then
            table.remove(self.childrenEvents[event], i)
            self.isVisibleChildrenEventsUpdated[event] = false
            if (self.parent ~= nil) then
                if (#self.childrenEvents[event] == 0) then
                    self.parent:removeEvent(event, self)
                end
            end
            return true
        end
    end
    return false
end

--- Gets all visible children of the container for a certain event.
--- @param self Container
--- @param event string The event to get the children for.
--- @return table
function Container:getVisibleChildrenEvents(event)
    expect(1, self, "table")
    expect(2, event, "string")
    if (self.isVisibleChildrenEventsUpdated[event]) then
        return self.visibleChildrenEvents[event]
    end
    local visibleChildrenEvents = {}

    if self.childrenEvents[event] then
        for _, child in ipairs(self.childrenEvents[event]) do
            if self:isChildVisible(child) then
                table.insert(visibleChildrenEvents, child)
            end
        end
    end

    self.visibleChildrenEvents[event] = visibleChildrenEvents
    self.isVisibleChildrenEventsUpdated[event] = true
    return visibleChildrenEvents
end

--- Forces to update the z position of the child.
--- @param self Container
--- @param child table The child to update.
function Container:updateChild(child)
    expect(1, self, "table")
    expect(2, child, "table")
    if not child or type(child) ~= "table" or not child.initialized then
        return
    end

    self:removeChild(child)
    self:addChild(child, child:getZ())

    for event, _ in pairs(self.childrenEvents) do
        if self:isEventRegistered(event, child) then
            self:removeEvent(event, child)
            self:addEvent(event, child)
        end
    end
end

--- Sets the cursor of the container.
--- @param self Container
--- @param blink boolean If the cursor should blink.
--- @param cursorX? number The x position of the cursor.
--- @param cursorY? number The y position of the cursor.
--- @param color? color The color of the cursor.
--- @return self
function Container:setCursor(blink, cursorX, cursorY, color)
    expect(1, self, "table")
    expect(2, blink, "boolean")
    expect(3, cursorX, "number", "nil")
    expect(4, cursorY, "number", "nil")
    expect(5, color, "color", "nil")
    if (self.parent ~= nil) then
        local obx, oby = self:getPosition()
        local xO, yO = self:getOffset()
        self.parent:setCursor(blink or false, (cursorX or 0) + obx - 1 - xO, (cursorY or 0) + oby - 1 - yO,
            color or self:getForeground())
    else
        local obx, oby = self:getAbsolutePosition()
        local xO, yO = self:getOffset()
        self.cursorBlink = blink or false
        if (cursorX ~= nil) then
            self.cursorX = obx + cursorX - 1 - xO
        end
        if (cursorY ~= nil) then
            self.cursorY = oby + cursorY - 1 - yO
        end
        self.cursorColor = color or self.cursorColor
        if (self.cursorBlink) then
            self.term.setTextColor(self.cursorColor)
            self.term.setCursorPos(self.cursorX, self.cursorY)
            self.term.setCursorBlink(true)
        else
            self.term.setCursorBlink(false)
        end
    end
    return self
end

for _, v in pairs({"setBg", "setFg", "setText"}) do
    ---@protected
    Container[v] = function(self, x, y, str)
        local obx, oby = self:calculatePosition()
        local w, h = self:getSize()
        if y >= 1 and y <= h then
            str, x = subText(str, x, w)
            if (x ~= nil) then
                if self.parent then
                    self.parent[v](self.parent, obx + x - 1, oby + y - 1, "" .. str)
                else
                    if (self.renderSystem ~= nil) then
                        self.renderSystem[v](x, y, "" .. str)
                    end
                end
            end
        end
    end
end

for _, v in pairs({"drawBackgroundBox", "drawForegroundBox", "drawTextBox"}) do
    ---@protected
    Container[v] = function(self, x, y, width, height, symbol)
        local obx, oby = self:calculatePosition()
        local w, h = self:getSize()
        height = (y < 1 and (height + y > h and h or height + y - 1) or (height + y > h and h - y + 1 or height))
        width = (x < 1 and (width + x > w and w or width + x - 1) or (width + x > w and w - x + 1 or width))
        local pos = max(x + (obx - 1), obx)
        if self.parent then
            self.parent[v](self.parent, pos, max(y + (oby - 1), oby), width, height, symbol)
        else
            if (self.renderSystem ~= nil) then
                self.renderSystem[v](pos, max(y + (oby - 1), oby), width, height, symbol)
            end
        end
    end
end

function Container:blit(x, y, t, f, b)
    ---@protected
    local obx, oby = self:calculatePosition()
    local w, h = self:getSize()
    if y >= 1 and y <= h then
        local pos = max(x + (obx - 1), obx)
        if self.parent then
            self.parent.blit(pos, oby + y - 1, t, f, b)
        else
            if (self.renderSystem ~= nil) then
                self.renderSystem.blit(pos, oby + y - 1, t, f, b, x, w)
            end
        end
    end
end

---@protected
function Container:event(event, ...)
    if (VisualElement.event ~= nil) then
        VisualElement.event(self, event, ...)
    end
    for _, child in ipairs(self.children) do
        if child.event then
            child:event(event, ...)
        end
    end
end

for k, v in pairs({
    mouse_click = true,
    mouse_up = false,
    mouse_drag = false,
    mouse_scroll = true,
    mouse_move = false
}) do
    Container[k] = function(self, btn, x, y, ...)
        if (VisualElement[k] ~= nil) then
            if (VisualElement[k](self, btn, x, y, ...)) then
                local visibleChildren = self:getVisibleChildrenEvents(k)
                for _, child in pairs(visibleChildren) do
                    if (child and child[k] ~= nil) then
                        local relX, relY = self:getRelativePosition(x, y)
                        if (child[k](child, btn, relX, relY, ...)) then
                            self:setFocusedChild(child, true)
                            return true
                        end
                    end
                end
                if (v) then
                    self:setFocusedChild(nil, true)
                end
                return true
            end
        end
    end
end

---@protected
function Container.mouse_release(self, btn, x, y, ...)
    if (VisualElement.mouse_release ~= nil) then
        if (VisualElement.mouse_release(self, btn, x, y, ...)) then
            local visibleChildren = self:getVisibleChildren()
            for _, child in pairs(visibleChildren) do
                if (child and child.mouse_release ~= nil) then
                    local relX, relY = self:getRelativePosition(x, y)
                    child.mouse_release(child, btn, relX, relY, ...)
                end
            end
            return true
        end
    end
end

for _, v in pairs({"key", "key_up", "char"}) do
    Container[v] = function(self, ...)
        if (VisualElement[v] ~= nil) then
            if (VisualElement[v](self, ...)) then
                local focused = self:getFocusedChild()
                if (focused) then
                    if (focused[v] ~= nil) then
                        if (focused[v](focused, ...)) then
                            return true
                        end
                    end
                end
                return true
            end
        end
    end
end

return Container
