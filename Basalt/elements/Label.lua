local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local utils = require("utils")
local wrapText = utils.wrapText

---@class Label : VisualElement
local Label = setmetatable({}, VisualElement)
Label.__index = Label
local sub, rep = string.sub, string.rep

Label:initialize("Label")
Label:addProperty("autoSize", "boolean", true)
Label:addProperty("wrapUpdate", "boolean", true)
Label:addProperty("wrap", "boolean", false)
Label:addProperty("wrappedText", "table", {}, nil, function(self, value)
    self:setWrap(true)
end, function(self)
    local wrap = self:getWrap()
    local autoSize = self:getAutoSize()
    if (self:getWrapUpdate()) then
        self:setWrapUpdate(false)
        self.wrappedText = wrapText(self:getText(), self:getWidth())
    end
    if (autoSize) and (wrap) then
        self:setHeight(#self.wrappedText)
        self:updateRender()
    end
    return self.wrappedText
end)
Label:addProperty("text", "string", "My Label", nil, function(self, value)
    local wrap = self:getWrap()
    local autoSize = self:getAutoSize()
    if (wrap) then
        self:setWrapUpdate(true)
    end
    if (autoSize) and not (wrap) then
        self:setSize(value:len(), 1)
    end
end)

--- Creates a new label.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Label
---@protected
function Label:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Label")
    newInstance:create("Label")
    newInstance:setSize(newInstance:getText():len(), 1)
    return newInstance
end

---@protected
Label:extend("Init", function(self)
    self:setBackground(self.parent:getBackground())
    self:setForeground(self.parent:getForeground())

    self:addPropertyObserver("width", function()
        if (self.autoSize) and (self.wrap) then
            self:setWrapUpdate(true)
            local lines = self:getWrappedText()
            self:setHeight(#lines)
        end
    end)
end)

---@protected
function Label:render()
    VisualElement.render(self)
    local text = self:getText()
    local wrap = self:getWrap()
    if (wrap) then
        local lines = self:getWrappedText()
        local height = self:getHeight()
        for i, line in ipairs(lines) do
            if (i <= height) then
                self:addText(1, i, line)
            end
        end
    else
        self:addText(1, 1, text)
    end
end

return Label
