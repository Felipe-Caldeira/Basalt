local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local tHex = require("utils").tHex
local expect = require("expect").expect

local newPackage = dofile("rom/modules/main/cc/require.lua").make
local sub = string.sub

local function BasaltProgram(object)
    local width, height = 1, 1
    local visible = true
    local cursorBlink = true
    local xCursor, yCursor = 1, 1
    local fgColor, bgColor = colors.white, colors.black
    local tPalette = {}

    local data = {{}, {}, {}}

    local emptySpaceLine = ""
    local emptyColorLines = {}

    local function createEmptyLines()
        emptySpaceLine = (" "):rep(width)
        for n = 0, 15 do
            local nColor = 2 ^ n
            emptyColorLines[nColor] = tHex[nColor]:rep(width)
        end
    end

    local function resizeWindow(_width, _height)
        width, height = _width, _height
        createEmptyLines()
        local emptyText = emptySpaceLine
        local emptyFG = emptyColorLines[fgColor]
        local emptyBG = emptyColorLines[bgColor]
        for n = 1, height do
            data[1][n] = sub(
                data[1][n] == nil and emptyText or data[1][n] .. emptyText:sub(1, width - data[1][n]:len()), 1, width)
            data[2][n] = sub(data[2][n] == nil and emptyFG or data[2][n] .. emptyFG:sub(1, width - data[2][n]:len()), 1,
                width)
            data[3][n] = sub(data[3][n] == nil and emptyBG or data[3][n] .. emptyBG:sub(1, width - data[3][n]:len()), 1,
                width)
        end
    end

    local function updateCursor()
        if xCursor >= 1 and yCursor >= 1 and xCursor <= width and yCursor <= height then
            -- parentTerminal.setCursorPos(xCursor + x - 1, yCursor + y - 1)
        else
            -- parentTerminal.setCursorPos(0, 0)
        end
        -- parentTerminal.setTextColor(fgColor)
    end

    local function blit(sText, sTextColor, sBackgroundColor)
        if yCursor < 1 or yCursor > height or xCursor < 1 or xCursor + #sText - 1 > width then
            return
        end
        data[1][yCursor] = sub(data[1][yCursor], 1, xCursor - 1) .. sText ..
                               sub(data[1][yCursor], xCursor + #sText, width)
        data[2][yCursor] = sub(data[2][yCursor], 1, xCursor - 1) .. sTextColor ..
                               sub(data[2][yCursor], xCursor + #sText, width)
        data[3][yCursor] = sub(data[3][yCursor], 1, xCursor - 1) .. sBackgroundColor ..
                               sub(data[3][yCursor], xCursor + #sText, width)
        xCursor = xCursor + #sText
        if visible then
            updateCursor()
        end
        object:updateRender()
    end

    local setTextColor = function(color)
        if type(color) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(color) .. ")", 2)
        elseif tHex[color] == nil then
            error("Invalid color (got " .. color .. ")", 2)
        end
        fgColor = color
    end

    local setBackgroundColor = function(color)
        if type(color) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(color) .. ")", 2)
        elseif tHex[color] == nil then
            error("Invalid color (got " .. color .. ")", 2)
        end
        bgColor = color
    end

    local setPaletteColor = function(colour, r, g, b)
        -- have to work on
        if type(colour) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(colour) .. ")", 2)
        end

        if tHex[colour] == nil then
            error("Invalid color (got " .. colour .. ")", 2)
        end

        local tCol
        if type(r) == "number" and g == nil and b == nil then
            tCol = {colours.rgb8(r)}
            tPalette[colour] = tCol
        else
            if type(r) ~= "number" then
                error("bad argument #2 (expected number, got " .. type(r) .. ")", 2)
            end
            if type(g) ~= "number" then
                error("bad argument #3 (expected number, got " .. type(g) .. ")", 2)
            end
            if type(b) ~= "number" then
                error("bad argument #4 (expected number, got " .. type(b) .. ")", 2)
            end

            tCol = tPalette[colour]
            tCol[1] = r
            tCol[2] = g
            tCol[3] = b
        end
    end

    local getPaletteColor = function(colour)
        if type(colour) ~= "number" then
            error("bad argument #1 (expected number, got " .. type(colour) .. ")", 2)
        end
        if tHex[colour] == nil then
            error("Invalid color (got " .. colour .. ")", 2)
        end
        local tCol = tPalette[colour]
        return tCol[1], tCol[2], tCol[3]
    end

    local basaltWindow = {
        setCursorPos = function(_x, _y)
            if type(_x) ~= "number" then
                error("bad argument #1 (expected number, got " .. type(_x) .. ")", 2)
            end
            if type(_y) ~= "number" then
                error("bad argument #2 (expected number, got " .. type(_y) .. ")", 2)
            end
            xCursor = math.floor(_x)
            yCursor = math.floor(_y)
            if (visible) then
                updateCursor()
            end
        end,

        getCursorPos = function()
            return xCursor, yCursor
        end,

        setCursorBlink = function(blink)
            if type(blink) ~= "boolean" then
                error("bad argument #1 (expected boolean, got " .. type(blink) .. ")", 2)
            end
            cursorBlink = blink
        end,

        getCursorBlink = function()
            return cursorBlink
        end,

        getPaletteColor = getPaletteColor,
        getPaletteColour = getPaletteColor,

        setBackgroundColor = setBackgroundColor,
        setBackgroundColour = setBackgroundColor,

        setTextColor = setTextColor,
        setTextColour = setTextColor,

        setPaletteColor = setPaletteColor,
        setPaletteColour = setPaletteColor,

        getBackgroundColor = function()
            return bgColor
        end,

        getBackgroundColour = function()
            return bgColor
        end,

        getSize = function()
            return width, height
        end,

        getTextColor = function()
            return fgColor
        end,

        getTextColour = function()
            return fgColor
        end,

        getRenderData = function()
            return data
        end,

        scroll = function(offset)
            assert(type(offset) == "number", "bad argument #1 (expected number, got " .. type(offset) .. ")")
            if offset ~= 0 then
                for newY = 1, height do
                    local y = newY + offset
                    if y < 1 or y > height then
                        data[1][newY] = emptySpaceLine
                        data[2][newY] = emptyColorLines[fgColor]
                        data[3][newY] = emptyColorLines[bgColor]
                    else
                        data[1][newY] = data[1][y]
                        data[2][newY] = data[2][y]
                        data[3][newY] = data[3][y]
                    end
                end
            end
            if (visible) then
                updateCursor()
            end
        end,

        isColor = function()
            return object.basalt.getTerm().isColor()
        end,

        isColour = function()
            return object.basalt.getTerm().isColor()
        end,

        write = function(text)
            text = tostring(text)
            if (visible) then
                blit(text, tHex[fgColor]:rep(text:len()), tHex[bgColor]:rep(text:len()))
            end
        end,

        clearLine = function()
            if (visible) then
                xCursor = 1
                blit((" "):rep(width), tHex[fgColor]:rep(width), tHex[bgColor]:rep(width))
            end
        end,

        clear = function()
            for n = 1, height do
                data[1][n] = emptySpaceLine
                data[2][n] = emptyColorLines[fgColor]
                data[3][n] = emptyColorLines[bgColor]
            end
            if (visible) then
                updateCursor()
            end
        end,

        blit = function(text, fgcol, bgcol)
            if type(text) ~= "string" then
                error("bad argument #1 (expected string, got " .. type(text) .. ")", 2)
            end
            if type(fgcol) ~= "string" then
                error("bad argument #2 (expected string, got " .. type(fgcol) .. ")", 2)
            end
            if type(bgcol) ~= "string" then
                error("bad argument #3 (expected string, got " .. type(bgcol) .. ")", 2)
            end
            if #fgcol ~= #text or #bgcol ~= #text then
                error("Arguments must be the same length", 2)
            end
            if (visible) then
                blit(text, fgcol, bgcol)
            end
        end
    }

    local process = {}

    return {
        setSize = function(_width, _height)
            resizeWindow(_width, _height)
        end,

        setVisible = function(vis)
            visible = vis
        end,

        setCursorBlink = function(blink)
            cursorBlink = blink
        end,

        getCursorBlink = function()
            return cursorBlink
        end,

        start = function(path, customEnv, ...)
            local args = {...}
            customEnv = customEnv or {}
            process = {}
            process.window = basaltWindow
            basaltWindow.current = term.current
            basaltWindow.redirect = term.redirect
            if (type(path) == "string") then
                process.coroutine = coroutine.create(function()
                    local pPath = shell.resolveProgram(path)
                    local env = setmetatable(customEnv, {
                        __index = _ENV
                    })
                    env.shell = shell
                    if (pPath == nil) then
                        error("The path " .. path .. " does not exist!")
                    end
                    env.require, env.package = newPackage(env, fs.getDir(pPath))
                    if (fs.exists(pPath)) then
                        local file = fs.open(pPath, "r")
                        local content = file.readAll()
                        file.close()
                        local program = load(content, path, "bt", env)
                        if (program ~= nil) then
                            term.redirect(process.window)
                            local result = program(path, table.unpack(args))
                            term.redirect(object.basalt.getTerm())
                            return result
                        end
                    end
                end)
            elseif (type(path) == "function") then
                process.coroutine = coroutine.create(function()
                    path(table.unpack(args))
                end)
            else
                return
            end
            local ok, result = coroutine.resume(process.coroutine)
            if not ok then
                error(result)
            end
        end,

        resume = function(event, ...)
            term.redirect(process.window)
            if (process.coroutine == nil) then
                return
            end
            if (process.filter ~= nil) then
                if (event ~= process.filter) then
                    return
                end
                process.filter = nil
            end
            local ok, result = coroutine.resume(process.coroutine, event, ...)

            if ok then
                process.filter = result
            else
                -- error(result)
            end
            term.redirect(object.basalt.getTerm())
            return ok, result
        end,

        stop = function()
            process = {}
        end,

        getProcess = function()
            return process
        end,

        getRenderData = function()
            return basaltWindow.getRenderData()
        end,

        getStatus = function()
            return coroutine.status(process.coroutine)
        end,

        isDead = function()
            return coroutine.status(process.coroutine) == "dead"
        end
    }
end

---@class Program : VisualElement
local Program = setmetatable({}, VisualElement)
Program.__index = Program

Program:initialize("Program")
Program:addProperty("program", "table")

--- Creates a new Program.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Program
---@protected
function Program:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Program")
    newInstance:create("Program")
    newInstance:setSize(20, 8)
    newInstance:setProgram(BasaltProgram(newInstance))
    newInstance.program.setSize(20, 8)
    newInstance:setZ(5)
    return newInstance
end

---@protected
function Program:render()
    VisualElement.render(self)
    local renderData = self.program.getRenderData()
    for k, _ in ipairs(renderData[1]) do
        self:addBlit(1, k, renderData[1][k], renderData[2][k], renderData[3][k])
    end
end

--- Starts the program.
---@param self Program
---@param path string|function The path to the program or the function to run.
---@param customEnv? table The custom environment for the program.
function Program:start(path, customEnv, ...)
    expect(1, self, "table")
    expect(2, path, "string", "function")
    self.program.start(path, customEnv, ...)
end

--- Stops the program.
---@param self Program
---@return Program
function Program:stop()
    expect(1, self, "table")
    self.program.stop()
    return self
end

Program:extend("Load", function(self)
    self:listenEvent("mouse_click")
    self:listenEvent("mouse_up")
    self:listenEvent("mouse_scroll")
    self:listenEvent("mouse_drag")
end)

---@protected
function Program:event(...)
    self.program.resume(...)
end

---@protected
function Program:mouse_click(...)
    if (VisualElement.mouse_click(self, ...)) then
        self.program.resume("mouse_click", ...)
        return true
    end
end

---@protected
function Program:mouse_up(...)
    if (VisualElement.mouse_up(self, ...)) then
        self.program.resume("mouse_up", ...)
        return true
    end
end

---@protected
function Program:mouse_scroll(...)
    self.program.resume("mouse_scroll", ...)
end

---@protected
function Program:mouse_drag(...)
    if (VisualElement.mouse_drag(self, ...)) then
        self.program.resume("mouse_drag", ...)
        return true
    end
end

---@protected
function Program:key(...)
    if (VisualElement.key(self, ...)) then
        self.program.resume("key", ...)
        return true
    end
end

---@protected
function Program:key_up(...)
    if (VisualElement.key_up(self, ...)) then
        self.program.resume("key_up", ...)
        return true
    end
end

---@protected
function Program:char(...)
    if (VisualElement.char(self, ...)) then
        self.program.resume("char", ...)
        return true
    end
end

return Program
