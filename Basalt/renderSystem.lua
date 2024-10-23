local tHex = require("utils").tHex
local sub, rep, max, min, unpack = string.sub, string.rep, math.max, math.min, table.unpack

local subrenderData = {}
local subrenderDataCount = 0
local function cSub(s, i, j)
    local key = s .. i .. j
    if (subrenderDataCount > 100) then
        subrenderData = {}
        subrenderDataCount = 0
    end
    if not subrenderData[key] then
        subrenderData[key] = string.sub(s, i, j)
        subrenderDataCount = subrenderDataCount + 1
    end
    return subrenderData[key]
end

return function(drawTerm)
    local terminal = drawTerm or term.current()
    local width, height = terminal.getSize()
    local cache = {}
    local renderData = {}
    local modifiedLines = {}

    local emptySpaceLine
    local emptyColorLines = {}
    local forcedRender = false

    local function createEmptyLines()
        emptySpaceLine = rep(" ", width)
        for n = 0, 15 do
            local nColor = 2 ^ n
            local sHex = tHex[nColor]
            emptyColorLines[nColor] = rep(sHex, width)
        end
    end
    ----
    createEmptyLines()

    local function recreateWindowArray()
        createEmptyLines()
        local emptyText = emptySpaceLine
        local emptyFG = emptyColorLines[colors.white]
        local emptyBG = emptyColorLines[colors.black]
        for currentY = 1, height do
            renderData[currentY] = renderData[currentY] or {}
            cache[currentY] = cache[currentY] or {}
            renderData[currentY][1] = sub(renderData[currentY][1] == nil and emptyText or renderData[currentY][1] ..
                                              emptyText:sub(1, width - renderData[currentY][1]:len()), 1, width)
            renderData[currentY][2] = sub(renderData[currentY][2] == nil and emptyFG or renderData[currentY][2] ..
                                              emptyFG:sub(1, width - renderData[currentY][2]:len()), 1, width)
            renderData[currentY][3] = sub(renderData[currentY][3] == nil and emptyBG or renderData[currentY][3] ..
                                              emptyBG:sub(1, width - renderData[currentY][3]:len()), 1, width)
            modifiedLines[currentY] = true
        end
    end

    recreateWindowArray()

    local function blit(x, y, t, fg, bg, pos, w)
        t = cSub(t, max(1 - pos + 1, 1), max(w - pos + 1, 1))
        fg = cSub(fg, max(1 - pos + 1, 1), max(w - pos + 1, 1))
        bg = cSub(bg, max(1 - pos + 1, 1), max(w - pos + 1, 1))

        if #t == #fg and #t == #bg then
            if y >= 1 and y <= height then
                if x + #t > 0 and x <= width then
                    local startN = x < 1 and 1 - x + 1 or 1
                    local endN = x + #t > width and width - x + 1 or #t

                    local oldCache = renderData[y]

                    local newCacheT = cSub(oldCache[1], 1, x - 1) .. cSub(t, startN, endN)
                    local newCacheFG = cSub(oldCache[2], 1, x - 1) .. cSub(fg, startN, endN)
                    local newCacheBG = cSub(oldCache[3], 1, x - 1) .. cSub(bg, startN, endN)

                    if x + #t <= width then
                        newCacheT = newCacheT .. cSub(oldCache[1], x + #t, width)
                        newCacheFG = newCacheFG .. cSub(oldCache[2], x + #t, width)
                        newCacheBG = newCacheBG .. cSub(oldCache[3], x + #t, width)
                    end
                    if (renderData[y][1] ~= newCacheT or renderData[y][2] ~= newCacheFG or renderData[y][3] ~=
                        newCacheBG) then
                        renderData[y][1] = newCacheT
                        renderData[y][2] = newCacheFG
                        renderData[y][3] = newCacheBG
                        modifiedLines[y] = true
                    end
                end
            end
        end
    end

    local function setCache(renderDataType, x, y, str)
        if y >= 1 and y <= height and x + #str > 0 and x <= width then
            local startN = max(1, 1 - x + 1)
            local endN = min(#str, width - x + 1)
            local oldCache = renderData[y][renderDataType]
            local newCache = cSub(oldCache, 1, x - 1) .. cSub(str, startN, endN)
            if x + #str <= width then
                newCache = newCache .. cSub(oldCache, x + #str, width)
            end
            if (renderData[y][renderDataType] ~= newCache) then
                renderData[y][renderDataType] = newCache
                modifiedLines[y] = true
            end
        end
    end

    local drawHelper = {
        setSize = function(w, h)
            width, height = w, h
            recreateWindowArray()
        end,

        setBg = function(x, y, colorStr)
            setCache(3, x, y, colorStr)
        end,

        setText = function(x, y, text)
            setCache(1, x, y, text)
        end,

        setFg = function(x, y, colorStr)
            setCache(2, x, y, colorStr)
        end,

        blit = function(x, y, t, fg, bg, pos, w)
            blit(x, y, t, fg, bg, pos, w)
        end,

        drawBackgroundBox = function(x, y, width, height, bgCol)
            local colorStr = rep(type(bgCol) == "string" and bgCol or tHex[bgCol], width)
            if (type(bgCol) == "string") and (#bgCol > 1) then
                colorStr = sub(colorStr, 1, width)
            end
            for n = 1, height do
                setCache(3, x, y + (n - 1), colorStr)
            end
        end,
        drawForegroundBox = function(x, y, width, height, fgCol)
            local colorStr = rep(type(fgCol) == "string" and fgCol or tHex[fgCol], width)
            if (type(fgCol) == "string") and (#fgCol > 1) then
                colorStr = sub(colorStr, 1, width)
            end
            for n = 1, height do
                setCache(2, x, y + (n - 1), colorStr)
            end
        end,
        drawTextBox = function(x, y, width, height, symbol)
            local textStr = rep(symbol, width)
            if (#symbol > 1) then
                textStr = sub(textStr, 1, width)
            end
            for n = 1, height do
                setCache(1, x, y + (n - 1), textStr)
            end
        end,

        update = function()
            local xC, yC = terminal.getCursorPos()
            local isBlinking = false
            if (terminal.getCursorBlink ~= nil) then
                isBlinking = terminal.getCursorBlink()
            end
            terminal.setCursorBlink(false)
            for n = 1, height do
                if (forcedRender) then
                    cache[n][1] = renderData[n][1]
                    cache[n][2] = renderData[n][2]
                    cache[n][3] = renderData[n][3]
                    terminal.setCursorPos(1, n)
                    terminal.blit(unpack(renderData[n]))
                    modifiedLines[n] = false
                else
                    if (modifiedLines[n]) then
                        if ((cache[n][1] ~= renderData[n][1]) or (cache[n][2] ~= renderData[n][2]) or
                            (cache[n][3] ~= renderData[n][3])) or (forcedRender) then
                            cache[n][1] = renderData[n][1]
                            cache[n][2] = renderData[n][2]
                            cache[n][3] = renderData[n][3]
                            terminal.setCursorPos(1, n)
                            terminal.blit(unpack(renderData[n]))
                        end
                        modifiedLines[n] = false
                    end
                end
            end
            forcedRender = false
            terminal.setBackgroundColor(colors.black)
            terminal.setCursorBlink(isBlinking)
            terminal.setCursorPos(xC, yC)
        end,

        forceRender = function()
            forcedRender = true
        end,

        setTerm = function(newTerm)
            terminal = newTerm
        end
    }
    return drawHelper
end
