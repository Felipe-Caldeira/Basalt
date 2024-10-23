-- from https://github.com/jonathanpoelen/lua-xmlparser
local io, string, pairs = io, string, pairs

local slashchar = string.byte('/', 1)
local E = string.byte('E', 1)

local function defaultEntityTable()
    return {
        quot = '"',
        apos = '\'',
        lt = '<',
        gt = '>',
        amp = '&',
        tab = '\t',
        nbsp = ' '
    }
end

local function replaceEntities(s, entities)
    return s:gsub('&([^;]+);', entities)
end

local function createEntityTable(docEntities, resultEntities)
    local entities = resultEntities or defaultEntityTable()
    for _, e in pairs(docEntities) do
        e.value = replaceEntities(e.value, entities)
        entities[e.name] = e.value
    end
    return entities
end

local function parse(s, evalEntities)
    s = s:gsub('<!%-%-(.-)%-%->', '')

    local entities, tentities = {}

    if evalEntities then
        local pos = s:find('<[_%w]')
        if pos then
            s:sub(1, pos):gsub('<!ENTITY%s+([_%w]+)%s+(.)(.-)%2', function(name, _, entity)
                entities[#entities + 1] = {
                    name = name,
                    value = entity
                }
            end)
            tentities = createEntityTable(entities)
            s = replaceEntities(s:sub(pos), tentities)
        end
    end

    local t, l = {}, {}

    local addtext = function(txt)
        txt = txt:match '^%s*(.*%S)' or ''
        if #txt ~= 0 then
            t[#t + 1] = {
                text = txt
            }
        end
    end

    s:gsub('<([?!/]?)([-:_%w]+)%s*(/?>?)([^<]*)', function(type, name, closed, txt)
        if #type == 0 then
            local attrs, orderedattrs = {}, {}
            if #closed == 0 then
                local len = 0
                for all, aname, _, value, starttxt in string.gmatch(txt, "(.-([-_%w]+)%s*=%s*(.)(.-)%3%s*(/?>?))") do
                    len = len + #all
                    attrs[aname] = value
                    orderedattrs[#orderedattrs + 1] = {
                        name = aname,
                        value = value
                    }
                    if #starttxt ~= 0 then
                        txt = txt:sub(len + 1)
                        closed = starttxt
                        break
                    end
                end
            end
            t[#t + 1] = {
                tag = name,
                attrs = attrs,
                children = {},
                orderedattrs = orderedattrs
            }

            if closed:byte(1) ~= slashchar then
                l[#l + 1] = t
                t = t[#t].children
            end

            addtext(txt)
        elseif '/' == type then
            t = l[#l]
            l[#l] = nil

            addtext(txt)
        elseif '!' == type then
            if E == name:byte(1) then
                txt:gsub('([_%w]+)%s+(.)(.-)%2', function(name, _, entity)
                    entities[#entities + 1] = {
                        name = name,
                        value = entity
                    }
                end, 1)
            end
        end
    end)

    return {
        children = t,
        entities = entities,
        tentities = tentities
    }
end

local function parseFile(filename, evalEntities)
    local f, err = io.open(filename)
    if f then
        local content = f:read '*a'
        f:close()
        return parse(content, evalEntities), nil
    end
    return f, err
end

local XML = {
    parse = parse,
    parseFile = parseFile,
    defaultEntityTable = defaultEntityTable,
    replaceEntities = replaceEntities,
    createEntityTable = createEntityTable
}

-- Everything below is made for basalt only

local expect = require("expect").expect

local BasicXmlExtension = {}
local ContainerXmlExtension = {}

function BasicXmlExtension.extensionProperties(original)
    original:initialize("VisualElement")

end

function BasicXmlExtension.init(original)
    original:extend("Init", function(self)

    end)
end

local function getChildrenItems(children)
    local items = {}
    for k, v in pairs(children) do
        if (v.tag) then
            if (v.tag == "addItem") then
                if (v.children[1].children) then
                    table.insert(items, getChildrenItems(v.children[1].children))
                else
                    table.insert(items, v.children[1].text)
                end
            else
                if (v.children[1].children) then
                    items[v.tag] = getChildrenItems(v.children)
                else
                    items[v.tag] = v.children[1].text
                end
            end
        end
    end
    return items
end

function BasicXmlExtension.generateElementFromXML(self, properties, env)
    env = env or _ENV
    env.basalt = self.basalt
    if (properties.attrs ~= nil) then
        for k, v in pairs(properties.attrs) do
            if (self[k] ~= nil) then
                local fName = "set" .. k:gsub("^%l", string.upper)
                if (self[fName] ~= nil) then
                    if (tonumber(v) ~= nil) then
                        self[fName](self, tonumber(v))
                    else
                        self[fName](self, v)
                    end
                end
            end
        end
    end
    for k, v in pairs(properties.children) do
        if (v.tag) then
            if (self[v.tag] ~= nil) then
                local propName = "set" .. v.tag:gsub("^%l", string.upper)
                if (self[propName] ~= nil) then
                    if (self:getPropertyType(v.tag) == "table") then
                        local items = getChildrenItems(v.children)
                        self[propName](self, items)
                    else
                        if (tonumber(v.children[1].text) ~= nil) then
                            self[propName](self, tonumber(v.children[1].text))
                        else
                            self[propName](self, v.children[1].text)
                        end
                    end
                elseif (self[v.tag] ~= nil) then
                    self[v.tag](self, function(...)
                        env.event = ... or nil
                        env.self = self
                        load(v.children[1].text, nil, "t", env)()
                    end)
                else
                    error("No property or event found for " .. v.tag .. " in (" .. self:getType() .. ") " ..
                              self:getName())
                end
            end
        end
    end
    return self
end

function BasicXmlExtension.loadXML(self, xml, env)
    expect(1, self, "table")
    expect(2, xml, "string")
    expect(3, env, "table", "nil")
    local doc = XML.parse(xml)
    self:generateElementFromXML(doc, env)
    return self
end

function BasicXmlExtension.loadXMLFile(self, file, env)
    expect(1, self, "table")
    expect(2, file, "string")
    expect(3, env, "table", "nil")
    local doc, err = XML.parseFile(file)
    if doc then
        self:generateElementFromXML(doc, env)
        return self
    end
    error(err)
end

function ContainerXmlExtension.generateElementFromXML(self, doc, env)
    env = env or _ENV
    env.basalt = self.basalt
    local baseFunc = require("basaltLoader").load("BasicElement").generateElementFromXML
    for _, v in pairs(doc.children) do
        if (v.tag) then
            local fName = "add" .. v.tag:gsub("^%l", string.upper)
            if (self[fName]) then
                self[fName](self, v.attrs.name or nil):generateElementFromXML(v, env)
            end
        end
    end
    baseFunc(self, doc)
    return self
end

return {
    BasicElement = BasicXmlExtension,
    Container = ContainerXmlExtension
}
