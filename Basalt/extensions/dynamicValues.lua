local protectedNames = {clamp=true, round=true, math=true, colors=true}
local function replace(word)
    if (protectedNames[word]) then
        return word
    end
    if word:sub(1, 1):find('%a') and not word:find('.', 1, true) then
        return '"' .. word .. '"'
    end
    return word
end

local function parseString(str)
    str = str:gsub("{", "")
    str = str:gsub("}", "")
    for k, v in pairs(colors) do
        if (type(k) == "string") then
            str = str:gsub("%f[%w]" .. k .. "%f[%W]", "colors." .. k)
        end
    end
    str = str:gsub("(%s?)([%w.]+)", function(a, b) return a .. replace(b) end)
    str = str:gsub("%s?%?", " and ")
    str = str:gsub("%s?:", " or ")
    str = str:gsub("%.w%f[%W]", ".width")
    str = str:gsub("%.h%f[%W]", ".height")
    return str
end

local function processString(str, env)
    env.math = math
    env.colors = colors
    env.clamp = function(val, min, max)
        return math.min(math.max(val, min), max)
    end
    env.round = function(val)
        return math.floor(val + 0.5)
    end
    local f = load("return " .. str, "", nil, env)

    if (f == nil) then
        error(str .. " - is not a valid dynamic value string")
    end
    return math.floor(f() + 0.5)
end

local function dynamicValue(element, name, dynamicString)
    local elementGroup = {}
    local observers = {}
    dynamicString = parseString(dynamicString)
    local cachedValue = nil
    local needsUpdate = true

    local function updateFunc()
        needsUpdate = true
    end

    for v in dynamicString:gmatch("%a+%.%a+") do
        local name = v:gsub("%.%a+", "")
        local prop = v:gsub("%a+%.", "")
        if (elementGroup[name] == nil) then
            elementGroup[name] = {}
        end
        table.insert(elementGroup[name], prop)
    end

    for k, v in pairs(elementGroup) do
        if (k == "self") then
            for _, b in pairs(v) do
                if (name ~= b) then
                    element:addPropertyObserver(b, updateFunc)
                    if (b == "clicked") or (b == "dragging") then
                        element:listenEvent("mouse_click")
                        element:listenEvent("mouse_up")
                    end
                    if (b == "dragging") then
                        element:listenEvent("mouse_drag")
                    end
                    if (b == "hovered") then
                        element:listenEvent("mouse_move")
                    end
                    table.insert(observers, {
                        ele = element,
                        name = b
                    })
                else
                    error("Dynamic Values - self reference to self")
                end
            end
        end

        if (k == "parent") then
            for _, b in pairs(v) do
                element.parent:addPropertyObserver(b, updateFunc)
                table.insert(observers, {
                    ele = element.parent,
                    name = b
                })
            end
        end

        if (k ~= "self" and k ~= "parent") and (protectedNames[k] == nil) then
            local ele = element:getRoot():getElementById(k)
            if (ele == nil) then error("Dynamic Values - unable to find element: " .. k) end
            for _, b in pairs(v) do
                ele:addPropertyObserver(b, updateFunc)
                table.insert(observers, {ele = ele, name = b})
            end
        end
    end

    local function calculate()
        local env = {}
        local parent = element:getParent()
        for k, v in pairs(elementGroup) do
            local eleTable = {}

            if (k == "self") then
                for _, b in pairs(v) do
                    eleTable[b] = element:getProperty(b)
                end
            end

            if (k == "parent") then
                for _, b in pairs(v) do
                    eleTable[b] = parent:getProperty(b)
                end
            end

            if (k ~= "self") and (k ~= "parent") and (protectedNames[k] == nil) then
                local ele = parent:getRoot():getElementById(k)
                if (ele == nil) then
                    error("Dynamic Values - unable to find element: " .. k)
                end
                for _, b in pairs(v) do
                    eleTable[b] = ele:getProperty(b)
                end
            end
            env[k] = eleTable
        end
        return processString(dynamicString, env)
    end

    return {
        get = function(self)
            if (needsUpdate) then
                cachedValue = calculate()
                needsUpdate = false
                element:forcePropertyObserverUpdate(name)
                element:updateRender()
            end
            return cachedValue
        end,
        removeObservers = function(self)
            for _, v in pairs(observers) do
                v.ele:removePropertyObserver(v.name, updateFunc)
            end
        end
    }
end

local function filterDynValues(self, name, value)
    if (type(value) == "string") and (value:sub(1, 1) == "{") and (value:sub(-1) == "}") then
        self.dynValues[name] = dynamicValue(self, name, value)
        value = self.dynValues[name].get
    end
    return value
end

-- The Element Extension API
local DynExtension = {}

function DynExtension.extensionProperties(original)
    original:initialize("BasicElement")
    original:addProperty("dynValues", "table", {})
end

function DynExtension.init(original)
    local setProp = original.setProperty
    original.setProperty = function(self, name, value, rule)
        if (self.dynValues == nil) then
            self.dynValues = {}
        end
        if (self.dynValues[name] ~= nil) then
            self.dynValues[name].removeObservers()
        end
        self.dynValues[name] = nil
        value = filterDynValues(self, name, value)
        setProp(self, name, value, rule)
    end
end

return {
    BasicElement = DynExtension
}
