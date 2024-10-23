local split = require("utils").split
local deepcopy = require("utils").deepcopy
local uuid = require("utils").uuid
local expect = require("expect").expect

---@class BasicElement
local Element = {
    __tostring = function(self)
        return self.type[1]
    end,
    __type = function(self)
        return self.type[1]
    end
}
Element.__index = Element

local properties = {}
local propertyTypes = {}
local extensions = {}
local activeType = "BasicElement"

--- Creates a new basic element
---@param id string The id of the element
---@param parent? table The parent of the element
---@param basalt table The basalt instance
---@return BasicElement
---@protected
function Element:new(id, parent, basalt)
    expect(1, self, "table")
    expect(2, id, "string", "nil")
    expect(3, parent, "Container", "nil")
    expect(4, basalt, "table", "nil")
    local newInstance = {}
    setmetatable(newInstance, self)
    self.__index = self
    newInstance.__noCopy = true
    newInstance:create("BasicElement")
    newInstance.parent = parent
    newInstance.basalt = basalt
    newInstance.id = id or uuid()
    return newInstance
end

--- Adds a property listener to the element
---@param self BasicElement
---@param propertyName string
---@param observerFunction function
---@return self
function Element:addPropertyObserver(propertyName, observerFunction)
    expect(1, self, "table")
    expect(2, propertyName, "string")
    expect(3, observerFunction, "function")
    if not self.propertyObservers[propertyName] then
        self.propertyObservers[propertyName] = {}
    end
    table.insert(self.propertyObservers[propertyName], observerFunction)
    return self
end

--- Removes a property observer from the element
---@param self BasicElement
---@param propertyName string
---@param index number
---@return self
function Element:removePropertyObserver(propertyName, index)
    expect(1, self, "table")
    expect(2, propertyName, "string")
    expect(3, index, "number", "function")
    if not self.propertyObservers[propertyName] then
        return self
    end
    if (type(index) == "number") then
        table.remove(self.propertyObservers[propertyName], index)
    else
        for k, v in pairs(self.propertyObservers[propertyName]) do
            if (v == index) then
                table.remove(self.propertyObservers[propertyName], k)
            end
        end
    end
    return self
end

--- Forces an update of the property observer
---@param self BasicElement
---@param propertyName string
---@return self
function Element:forcePropertyObserverUpdate(propertyName)
    expect(1, self, "table")
    expect(2, propertyName, "string")
    if not self.propertyObservers[propertyName] then
        return self
    end
    for _, v in pairs(self.propertyObservers[propertyName]) do
        if (type(v) == "function") then
            v(self, propertyName)
        end
    end
    return self
end

--- Sets a property of the element
---@param self BasicElement
---@param name string
---@param value any
---@param rule? function
---@return self
function Element:setProperty(name, value, rule)
    expect(1, self, "table")
    expect(2, name, "string")
    expect(4, rule, "function", "nil")
    if (rule ~= nil) then
        value = rule(self, name, value)
    end
    if type(value) == 'table' then
        value = deepcopy(value)
    end

    if (self[name] ~= value) then
        self[name] = value
    end

    if (self.propertyObservers[name] ~= nil) then
        for _, v in pairs(self.propertyObservers[name]) do
            v(self, name, value)
        end
    end
    return self
end

--- Gets a property of the element
---@param self BasicElement
---@param name string
---@return any
function Element:getProperty(name)
    if (type(self) ~= "table") then
        error("getProperty called on non-table value")
    end
    if (type(name) ~= "string") then
        error("getProperty called with non-string value")
    end
    local prop = self[name]
    if (type(prop) == "function") then
        return prop()
    end
    return prop
end

--- Checks if the element has a property
---@param self BasicElement
---@param name string
function Element:hasProperty(name)
    expect(1, self, "table")
    expect(2, name, "string")
    return self[name] ~= nil
end

--- Sets multiple properties of the element
---@param self BasicElement
---@param properties table -- Table of properties (like: {x=1, y=2, width=10, background=colors.red})
---@return self
function Element:setProperties(properties)
    expect(1, self, "table")
    expect(2, properties, "table")
    for k, v in pairs(properties) do
        self[k] = v
    end
    return self
end

--- Gets all properties of the element
---@param self BasicElement
---@return table
function Element:getProperties()
    expect(1, self, "table")
    local p = {}
    for k, v in pairs(self) do
        if (type(v) == "function") then
            p[k] = v()
        else
            p[k] = v
        end
    end
    return p
end

--- Gets the type of the element
---@param self BasicElement
---@param name string -- The name of the property
---@return string | nil
function Element:getPropertyType(name)
    expect(1, self, "table")
    expect(2, name, "string")
    for _, v in pairs(self.type) do
        if (propertyTypes[v] ~= nil) then
            if (propertyTypes[v][name] ~= nil) then
                return propertyTypes[v][name]
            end
        end
    end
end

--- Updates the rendering of the element
---@param self BasicElement
---@protected
function Element:updateRender()
    if (self.parent ~= nil) then
        self.parent:forceVisibleChildrenUpdate()
        self.parent:updateRender()
    else
        self.updateRendering = true
    end
end

--- Adds a property behaviour to the element
---@param self BasicElement
---@param name string -- The name of the property
---@param typ string -- The type of the property (e.g. "string", "number", "boolean", "table>key1,key2")
---@param defaultValue any -- The default value of the property
---@param readonly? boolean -- If the property is readonly
---@param setLogic? function -- The logic to set the property (gets called when setting the property)
---@param getLogic? function -- The logic to get the property (gets called when getting the property)
---@param ignRenderUpdate? boolean -- If the render update should be ignored
---@protected
function Element:addProperty(name, typ, defaultValue, readonly, setLogic, getLogic, ignRenderUpdate)
    if (typ == nil) then
        typ = "any"
    end
    if (readonly == nil) then
        readonly = false
    end

    local fName = name:gsub("^%l", string.upper)
    if not properties[activeType] then
        properties[activeType] = {}
        propertyTypes[activeType] = {}
    end
    if (type(defaultValue) == "table") then
        defaultValue = deepcopy(defaultValue)
    end
    properties[activeType][name] = defaultValue
    propertyTypes[activeType][name] = typ

    if not (readonly) then
        self["set" .. fName] = function(self, value, ...)
            expect(1, self, "table")
            if (setLogic ~= nil) then
                local modifiedVal = setLogic(self, value, ...)
                if (modifiedVal ~= nil) then
                    value = modifiedVal
                end
            end
            if ignRenderUpdate ~= true then
                self:updateRender()
            end
            if (typ ~= nil) then
                expect(2, value, "function", "dynValue", unpack(split(typ, "|")))
            end
            self:setProperty(name, value)
            return self
        end
    end
    self["get" .. fName] = function(self, ...)
        local prop = self:getProperty(name)
        if (getLogic ~= nil) then
            return getLogic(self, prop, ...)
        end
        return prop
    end
end

--- Combines multiple properties into one function
---@param self BasicElement
---@param name string -- The name of the combined propertyName
---@vararg string -- The names of the properties to combine
---@return self
---@protected
function Element:combineProperty(name, ...)
    name = name:gsub("^%l", string.upper)
    local args = {...}
    self["get" .. name] = function(self)
        local result = {}
        for _, v in pairs(args) do
            result[#result + 1] = self["get" .. v:gsub("^%l", string.upper)](self)
        end
        return unpack(result)
    end
    self["set" .. name] = function(self, ...)
        expect(1, self, "table")
        local values = {...}
        for k, v in pairs(args) do
            local propertyType = self:getPropertyType(v)
            if (propertyType ~= nil) then
                expect(k + 1, values[k], self:getPropertyType(v), "function", "dynValue")
            end
            self["set" .. v:gsub("^%l", string.upper)](self, values[k])
        end
        return self
    end
    return self
end

---@protected
function Element:initialize(typ)
    activeType = typ
    return self
end

--- This method is meant for internal usage only, it copys the properties from the template
---@protected
function Element:create(typ)
    if (properties[typ] ~= nil) then
        for k, v in pairs(properties[typ]) do
            if (type(v) == "table") then
                self[k] = deepcopy(v)
            else
                self[k] = v
            end
        end
    end
end

--- Adds a event listener to the element like :create this method is meant for internal usage only
---@protected
function Element:addListener(name, event)
    self["on" .. name:gsub("^%l", string.upper)] = function(self, ...)
        expect(1, self, "table")
        for k, f in pairs({...}) do
            expect(k + 1, f, "function")
            if (self.listeners == nil) then
                self.listeners = {}
            end
            if (self.listeners[name] == nil) then
                self.listeners[name] = {}
            end
            table.insert(self.listeners[name], f)
        end
        self:listenEvent(event)
        return self
    end
    return self
end

--- Fires an event
---@param self BasicElement
---@param name string -- The name of the event
---@vararg any -- The arguments to pass to the event
---@protected
---@return self
function Element:fireEvent(name, ...)
    expect(1, self, "table")
    expect(2, name, "string")
    if (self.listeners ~= nil) then
        if (self.listeners[name] ~= nil) then
            for _, v in pairs(self.listeners[name]) do
                v(self, ...)
            end
        end
    end
    return self
end

--- Checks if the element is of a certain type
---@param self BasicElement
---@param typ string -- The type to check (e.g. "BasicElement")
---@return boolean
function Element:isType(typ)
    -- can't use expect here because it would cause a stack overflow
    if (self.type ~= nil) then
        for _, v in pairs(self.type) do
            if (v == typ) then
                return true
            end
        end
    end
    return false
end

--- listens to a event
---@param self BasicElement
---@param event string -- The event to listen to
---@param active? boolean -- If the event listener for should be active
---@return self
function Element:listenEvent(event, active)
    expect(1, self, "table")
    expect(2, event, "string")
    expect(3, active, "boolean", "nil")
    if (self.parent ~= nil) then
        if (active) or (active == nil) then
            self.parent:addEvent(event, self)
            self.events[event] = true
        elseif (active == false) then
            self.parent:removeEvent(event, self)
            self.events[event] = false
        end
    end
    return self
end

--- Updates the event list of the element
---@param self BasicElement
---@return self
function Element:updateEvents()
    expect(1, self, "table")
    if (self.parent ~= nil) then
        for k, v in pairs(self.events) do
            if (v) then
                self.parent:addEvent(k, self)
            else
                self.parent:removeEvent(k, self)
            end
        end
    end
    return self
end

--- This method is meant for internal usage only
---@protected
function Element:extend(name, f)
    if (extensions[activeType] == nil) then
        extensions[activeType] = {}
    end
    if (extensions[activeType][name] == nil) then
        extensions[activeType][name] = {}
    end
    table.insert(extensions[activeType][name], f)
    return self
end

--- Calls an extension - meant for internal/extension usage only
---@protected
function Element:callExtension(name)
    for _, t in pairs(self.type) do
        if (extensions[t] ~= nil) then
            if (extensions[t][name] ~= nil) then
                for _, v in pairs(extensions[t][name]) do
                    v(self)
                end
            end
        end
    end
    return self
end

Element:addProperty("id", "string", "BasicElement")

Element:addProperty("type", "string|table", {"BasicElement"}, false, function(self, value)
    if (type(value) == "string") then
        table.insert(self.type, 1, value)
        return self.type
    end
end, function(self, _, depth)
    return self.type[depth or 1]
end)
Element:addProperty("z", "number", 1, false, function(self, value)
    self.z = value
    if (self.parent ~= nil) then
        self.parent:updateChild(self)
    end
    return value
end)

Element:addProperty("enabled", "boolean", true)
Element:addProperty("parent", "table", nil)
Element:addProperty("events", "table", {})
Element:addProperty("propertyObservers", "table", {})

--- This method gets called when the element gets created, it is meant for internal usage only
---@protected
function Element:init()
    if not self.initialized then
        self:callExtension("Init")
    end
    self:setProperty("initialized", true)
    self:callExtension("Load")
end

return Element
