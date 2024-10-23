local args = table.pack(...)
local dir = fs.getDir(args[2] or ".basalt")
if (dir == nil) then
    error("Unable to find directory " .. args[2] .. " please report this bug to our discord.")
end

--- @class BasaltLoader
local basaltLoader = {}

local _ELEMENTS = {}
local availableElements = {}
local _EXTENSIONS = {}
local extensionNames = {}
local basalt
local config

if not (bundled) then
    if (fs.exists(fs.combine(dir, "elements"))) then
        for _, v in pairs(fs.list(fs.combine(dir, "elements"))) do
            if (fs.isDir(fs.combine(fs.combine(dir, "elements"), v))) then
                availableElements[v] = true
            else
                local obj = v:gsub(".lua", "")
                availableElements[obj] = true
            end
        end
    end

    local allExt = {}
    if (fs.exists(fs.combine(dir, "extensions"))) then
        for _, v in pairs(fs.list(fs.combine(dir, "extensions"))) do
            table.insert(allExt, v)
        end
    end

    for _, v in pairs(allExt) do
        local newExtension
        if (fs.isDir(fs.combine(fs.combine(dir, "extensions"), v))) then
            table.insert(extensionNames, fs.combine(fs.combine(dir, "extensions"), v))
            newExtension = require(v .. "/init")
        else
            table.insert(extensionNames, v)
            newExtension = require(v:gsub(".lua", ""))
        end
        if (type(newExtension) == "table") then
            for a, b in pairs(newExtension) do
                if (type(a) == "string") then
                    if (_EXTENSIONS[a] == nil) then
                        _EXTENSIONS[a] = {}
                    end
                    table.insert(_EXTENSIONS[a], b)
                end
            end
        end
    end
else
    for _, v in pairs(bundled_availableFiles["basalt/elements"]) do
        availableElements[v:gsub(".lua", "")] = true
    end

    for _, v in pairs(bundled_availableFiles["basalt/extensions"]) do
        table.insert(extensionNames, v)
        local newExtension = require(v:gsub(".lua", ""))
        if (type(newExtension) == "table") then
            for a, b in pairs(newExtension) do
                if (type(a) == "string") then
                    if (_EXTENSIONS[a] == nil) then
                        _EXTENSIONS[a] = {}
                    end
                    table.insert(_EXTENSIONS[a], b)
                end
            end
        end
    end
end

function basaltLoader.load(elementName)
    if _ELEMENTS[elementName] then
        return _ELEMENTS[elementName]
    end
    local defaultPath = package.path
    local format = "path;/path/?.lua;/path/?/init.lua;"
    local main = format:gsub("path", dir)
    local objFolder = format:gsub("path", dir .. "/elements")
    local extFolder = format:gsub("path", dir .. "/extensions")
    local libFolder = format:gsub("path", dir .. "/libraries")

    package.path = main .. objFolder .. extFolder .. libFolder .. defaultPath

    _ELEMENTS[elementName] = require(fs.combine("elements", elementName))

    if _EXTENSIONS[elementName] then
        for _, extension in ipairs(_EXTENSIONS[elementName]) do
            if (extension.extensionProperties ~= nil) then
                extension.extensionProperties(_ELEMENTS[elementName])
            end
            extension.extensionProperties = nil
            if (extension.init ~= nil) then
                extension.init(_ELEMENTS[elementName], basalt)
            end
            extension.init = nil

            for a, b in pairs(extension) do
                if (type(a) == "string") then
                    _ELEMENTS[elementName][a] = b
                end
            end
        end
    end

    package.path = defaultPath
    return _ELEMENTS[elementName]
end

function basaltLoader.getElementList()
    return availableElements
end

function basaltLoader.extensionExists(name)
    for k, v in pairs(extensionNames) do
        if (string.lower(v:gsub(".lua", "")) == string.lower(name)) then
            return true
        end
    end
    return false
end

function basaltLoader.getExtension(extensionName)
    if (_EXTENSIONS[extensionName] ~= nil) then
        return _EXTENSIONS[extensionName]
    end
    return extensionName == nil and _EXTENSIONS or nil
end

function basaltLoader.setBasalt(basaltInstance)
    basalt = basaltInstance
end

function basaltLoader.getConfig()
    if (config == nil) then
        local github = "https://raw.githubusercontent.com/Pyroxenium/basalt-docs/main/config.json"
        if (github ~= nil) then
            local response = http.get(github)
            if (response == nil) then
                error("Couldn't get the config file from github!")
            end
            if (config ~= nil) then
                pcall(function()
                    response.close()
                end)
                return config
            end
            config = textutils.unserializeJSON(response.readAll())
            response.close()
            return config
        else
            error("Couldn't find the github path in the settings basalt.github!")
        end
    end
    return config
end

local function downloadElement(name)
    local config = basaltLoader.getConfig()
    for k, v in pairs(config.versions.elements) do
        if (string.lower(k) == string.lower(name)) then
            local url = v[2]
            local response = http.get(url)
            if (response == nil) then
                error("Couldn't get the element " .. name .. " from github!")
            end
            local data = response.readAll()
            return data
        end
    end
end

local function requireElement(name)
    name = name:gsub("^%l", string.upper)
    if (availableElements[name] == nil) then
        print("Loading element " .. name .. " from github...")
        local data = downloadElement(name)
        if (data == nil) then
            error("Couldn't find the element " .. name .. " in the github config!")
        end
        if (settings.get("basalt.storeDownloadedFiles")) then
            local file = fs.open(fs.combine(dir, "elements/" .. name .. ".lua"), "w")
            file.write(data)
            file.close()
        end
        local element = load(data, nil, "t", _ENV)()
        _ELEMENTS[name] = element

        if (_EXTENSIONS[name] ~= nil) then
            for _, extension in ipairs(_EXTENSIONS[name]) do
                if (extension.extensionProperties ~= nil) then
                    extension.extensionProperties(_ELEMENTS[name])
                end
                extension.extensionProperties = nil
                if (extension.init ~= nil) then
                    extension.init(_ELEMENTS[name], basalt)
                end
                extension.init = nil

                for a, b in pairs(extension) do
                    if (type(a) == "string") then
                        _ELEMENTS[name][a] = b
                    end
                end
            end
        end
        availableElements[name] = true
        return element
    end
end

local function downloadExtension(name)
    local config = basaltLoader.getConfig()
    for k, v in pairs(config.versions.extensions) do
        if (string.lower(k) == string.lower(name)) then
            local url = v[2]
            local response = http.get(url)
            if (response == nil) then
                error("Couldn't get the extension " .. name .. " from github!")
            end
            local data = response.readAll()
            return data
        end
    end
end

local function requireExtension(name)
    if not (basaltLoader.extensionExists(name)) then
        print("Loading extension " .. name .. " from github...")
        local data = downloadExtension(name)
        if (data == nil) then
            error("Couldn't find the extension " .. name .. " in the github config!")
        end
        if (settings.get("basalt.storeDownloadedFiles")) then
            local file = fs.open(fs.combine(dir, "extensions/" .. name .. ".lua"), "w")
            file.write(data)
            file.close()
        end
        local func = load(data, nil, "t", _ENV)
        local extension = func()
        if (type(extension) == "table") then
            for elementName, fList in pairs(extension) do
                if (_EXTENSIONS[elementName] == nil) then
                    _EXTENSIONS[elementName] = {}
                end
                table.insert(_EXTENSIONS[elementName], fList)
                if (elementName == "Basalt") then
                    fList.basalt = basalt
                    for fName, f in pairs(fList) do
                        if (type(fName) == "string") then
                            if (fName == "init") then
                                f(basalt)
                            else
                                basalt[fName] = f
                            end
                        end
                    end
                else
                    if (_ELEMENTS[elementName] ~= nil) then
                        if (fList.extensionProperties ~= nil) then
                            fList.extensionProperties(_ELEMENTS[elementName])
                        end
                        fList.extensionProperties = nil
                        if (fList.init ~= nil) then
                            fList.init(_ELEMENTS[elementName], basalt)
                        end
                        fList.init = nil
                        for fName, f in pairs(fList) do
                            if (type(fName) == "string") then
                                _ELEMENTS[elementName][fName] = f
                            end
                        end
                    end
                end
            end
        end
        table.insert(extensionNames, name)
    end
end

function basaltLoader.require(typ, name)
    if (typ == "element") then
        return requireElement(name)
    elseif (typ == "extension") then
        return requireExtension(name)
    end
end

return basaltLoader
