local expect = require("expect").expect

local function copy(t)
    local new = {}
    for k, v in pairs(t) do
        new[k] = v
    end
    return new
end

local baseTemplate = {
    default = {
        background = colors.cyan,
        foreground = colors.black
    },
    BaseFrame = {
        background = colors.white,
        foreground = colors.black,
        Button = {
            background = "{self.clicked ? black : cyan}",
            foreground = "{self.clicked ? cyan : black}"
        },
        Container = {
            background = colors.black,
            Button = {
                background = "{self.clicked ? black : cyan}",
                foreground = "{self.clicked ? cyan : black}"
            }
        },
        Checkbox = {
            background = colors.black,
            foreground = colors.cyan
        },
        Input = {
            background = "{self.focused ? cyan : black}",
            foreground = "{self.focused ? black : cyan}",
            placeholderBackground = "{self.focused ? cyan : black}",
            placeholderColor = "{self.focused ? gray : gray}",
            placeholderText = "{self.focused ? '' : 'Type..'}",
            width = 14
        },
        Slider = {
            background = nil,
            knobBackground = "{self.focused ? cyan : black}"
        },
        Label = {
            background = nil
        }
    }
}

local TempExtension = {}

function TempExtension.init(original, basalt)
    local setProp = original.setProperty
    original.setProperty = function(self, name, value, rule)
        if (self._templateValues ~= nil) then
            if (self._templateValues[name]) then
                self._templateValues[name] = false
            end
        end
        setProp(self, name, value, rule)
    end

    original:extend("Init", function(self)
        local template = basalt.getTemplate(self)
        local elements = basalt.getElements()
        if (self._templateValues == nil) then
            self._templateValues = {}
        end
        if (template ~= nil) then
            for k, v in pairs(template) do
                if (elements[k] == nil) then
                    if (colors[v] ~= nil) then
                        self:setProperty(k, colors[v])
                    else
                        self:setProperty(k, v)
                    end
                    self._templateValues[k] = true
                end
            end
        end
    end)
end

function TempExtension.updateTemplate(self)
    local template = self.basalt.getTemplate(self)
    local elements = self.basalt.getElements()
    if (template ~= nil) then
        for k, v in pairs(template) do
            if (self._templateValues[k]) then
                if (elements[k] == nil) then
                    if (colors[v] ~= nil) then
                        self:setProperty(k, colors[v])
                    else
                        self:setProperty(k, v)
                    end
                    self._templateValues[k] = true
                end
            end
        end
    end
end

function TempExtension.__getElementPathTypes(self, types)
    if (types ~= nil) then
        table.insert(types, 1, self.type)
    else
        types = {self.type}
    end
    local parent = self:getParent()
    if (parent ~= nil) then
        return parent:__getElementPathTypes(types)
    else
        return types
    end
end

local function lookUpTemplate(allTypes)
    local elementData = copy(baseTemplate.default)
    local tLink = baseTemplate
    if (tLink ~= nil) then
        for _, v in pairs(allTypes) do
            for _, b in pairs(v) do
                if (tLink[b] ~= nil) then
                    tLink = tLink[b]
                    for k, v in pairs(tLink) do
                        elementData[k] = v
                    end
                    break
                else
                    for k, v in pairs(baseTemplate.default) do
                        elementData[k] = v
                    end
                end
            end
        end
    end
    return elementData
end

---@class Basalt
local Basalt = {}
local oldStop
local changedColors = {}
local basaltLink = basalt

---@private
function Basalt.init(basalt)
    oldStop = basalt.stop
    basaltLink = basalt
end

--- Returns the template of the element or the base template.
---@param element? table
---@return table The template of the element.
function Basalt.getTemplate(element)
    expect(1, element, "table", "nil")
    if (element == nil) then
        return baseTemplate
    end
    return lookUpTemplate(element:__getElementPathTypes())
end

--- Adds additional template configurations.
---@param newTemplate table The new template to add.
function Basalt.addTemplate(newTemplate)
    expect(1, newTemplate, "table")
    if (type(newTemplate) == "table") then
        for k, v in pairs(newTemplate) do
            baseTemplate[k] = v
        end
    end
    local frames = basaltLink.getFrames()
    for k, v in pairs(frames) do
        v:updateTemplateColors()
    end
end

--- Sets a new template.
---@param newTemplate table The new base template.
function Basalt.setTemplate(newTemplate)
    expect(1, newTemplate, "table")
    baseTemplate = newTemplate
    local frames = basaltLink.getFrames()
    for k, v in pairs(frames) do
        v:updateTemplateColors()
    end
end

--- Loads a template from a json formatted file.
---@param newTemplate string The path to the template file.
function Basalt.loadTemplate(newTemplate)
    expect(1, newTemplate, "string")
    local file = fs.open(newTemplate, "r")
    if (file ~= nil) then
        local data = file.readAll()
        file.close()
        baseTemplate = textutils.unserializeJSON(data)
    else
        error("Could not open template file " .. newTemplate)
    end
    local frames = basaltLink.getFrames()
    for k, v in pairs(frames) do
        v:updateTemplateColors()
    end
end

--- Sets the colors of the terminal.
---@param colorList table The new colors to set.
function Basalt.setColors(colorList)
    expect(1, colorList, "table")
    for k, v in pairs(colorList) do
        term.setPaletteColour(colors[k], v)
    end
end

function Basalt.stop()
    oldStop()
    for k, v in pairs(changedColors) do
        for a, b in pairs(v) do
            k.setPaletteColor(colors[a], b)
        end
    end
end

local Container = {}
function Container.init(original, basalt)
    original:extend("Init", function(self)
        if (original:getParent() == nil) then
            if (baseTemplate.colors ~= nil) then
                local FrameTerm = self:getTerm()
                if (FrameTerm ~= nil) then
                    for k, v in pairs(baseTemplate.colors) do
                        if (colors[k] ~= nil) then
                            if (v:sub(1, 1) == "#") then
                                v = "0x" .. v:sub(2)
                            end
                            local color = tonumber(v)
                            changedColors[FrameTerm] = changedColors[FrameTerm] or {}
                            changedColors[FrameTerm][k] = colors.packRGB(FrameTerm.getPaletteColor(colors[k]))
                            FrameTerm.setPaletteColor(colors[k], color)
                        end
                    end
                end
            end
        end
        return self
    end)
end

function Container:updateTemplateColors()
    local elements = self:getChildren()
    self:updateTemplate()
    for k, v in pairs(elements) do
        if (v.updateTemplate ~= nil) then
            v:updateTemplate()
            if (v:isType("Container")) then
                v:updateTemplateColors()
            end
        end
    end
end

return {
    BasicElement = TempExtension,
    Container = Container,
    Basalt = Basalt
}
