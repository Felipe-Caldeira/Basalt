local loader = require("basaltLoader")
local VisualElement = loader.load("VisualElement")
local expect = require("expect").expect
local tHex = require("utils").tHex

local sub, rep = string.sub, string.sub

---@class Image : VisualElement
local Image = setmetatable({}, VisualElement)
Image.__index = Image

Image:initialize("Image")
Image:addProperty("paletteUsage", "boolean", false, nil, function(self, value)
    if (value) then
        self:updatePalette()
    end
    return value
end)
Image:addProperty("frame", "number", 1)
Image:addProperty("autoSize", "boolean", true, nil, function(self, value)
    if (value) then
        local img = self:getImage()
        self:setSize(#img[1][1][1], #img[1])
    end
    return value
end)
Image:addProperty("image", "table", {}, nil, function(self, value)
    if (self:getAutoSize()) then
        self:setSize(#value[1][1][1], #value[1])
    end
    if (self:getPaletteUsage()) then
        self:updatePalette()
    end
end)

--- Creates a new Image.
---@param id string The id of the object.
---@param parent? Container The parent of the object.
---@param basalt Basalt The basalt object.
--- @return Image
---@protected
function Image:new(id, parent, basalt)
    local newInstance = VisualElement:new(id, parent, basalt)
    setmetatable(newInstance, self)
    self.__index = self
    newInstance:setType("Image")
    newInstance:create("Image")
    newInstance:setSize(20, 8)
    newInstance:setZ(5)
    return newInstance
end

---@protected
function Image:render()
    VisualElement.render(self)
    local image = self:getImage()
    local frame = self:getFrame()
    local width, height = self:getSize()

    if (image ~= nil) then
        if image[frame] ~= nil then
            for y = 1, #image[frame] do
                local imgPart = image[frame][y]
                self:addBlit(1, y, sub(imgPart[1], 1, width), sub(imgPart[2], 1, width), sub(imgPart[3], 1, width))
                if (y >= height) then
                    break
                end
            end
        end
    end
end

--- Loads an image from a file
---@param path string
---@return Image
function Image:loadImage(path)
    expect(1, path, "string")
    local file = fs.open(path, "r")
    if (file == nil) then
        error("Image " .. path .. " not found!")
    end
    local data = textutils.unserialize(file.readAll())
    file.close()
    if (data == nil) then
        error("Image " .. path .. " is not a valid image!")
    end
    self:setImage(data)
    return self
end

--- Plays the image-animation
---@return Image
function Image:play()
    local image = self:getImage()
    local frame = self:getFrame()
    if (self:getPaletteUsage()) then
        self:updatePalette()
    end
    if (image.animation) or (image.animated) then
        local time = image[frame].duration or image.secondsPerFrame or 0.05
        self.animTimer = os.startTimer(time)
    end
    return self
end

--- Stops the image-animation
---@return Image
function Image:stop()
    if (self.animTimer) then
        os.cancelTimer(self.animTimer)
    end
    return self
end

---@protected
function Image:event(event, timerId, ...)
    VisualElement.event(self, event, timerId, ...)
    if (event == "timer") then
        if (timerId == self.animTimer) then
            local image = self:getImage()
            local frame = self:getFrame()
            if (image[frame + 1] == nil) then
                self:setFrame(1)
            else
                self:setFrame(frame + 1)
            end
            self:play()
        end
    end
end

--- Updates the palette of the image
---@return Image
function Image:updatePalette()
    local palette = {}
    local image = self:getImage()
    local frame = self:getFrame()
    if (image[frame] ~= nil) then
        if (image.palette) then
            for k, v in pairs(image.palette) do
                local c = type(k) == "string" and colors[k] or k ^ 2
                palette[c] = v
            end
        end
        if (image[frame].palette) then
            for k, v in pairs(image[frame].palette) do
                local c = type(k) == "string" and colors[k] or k ^ 2
                palette[c] = v
            end
        end
    end
    for color, tbl in pairs(palette) do
        self:getParent():getTerm().setPaletteColor(color, table.unpack(tbl))
    end
    return self
end

--- Returns the metadata of the image
---@param key? string
---@return any
function Image:getMetadata(key)
    if (key ~= nil) then
        if (self:getImage()[key] ~= nil) then
            return self:getImage()[key]
        end
        return
    end
    local metadata = {}
    for k, v in pairs(self:getImage()) do
        if (type(k) == "string") then
            metadata[k] = v
        end
    end
    return metadata
end

local function resizeCanvas(self, image, x, y)
    local bg, fg = tHex[self:getBackground()], tHex[self:getForeground()]
    local width, height = math.max(#image[1][1][1], x), math.max(#image, y)
    for _, v in ipairs(image) do
        for i = 1, height do
            if (v[i] == nil) then
                v[i] = {rep(" ", width), rep(fg, width), rep(bg, width)}
            end
            if (#v[i][1] < width) then
                v[i][1] = v[i][1] .. string.rep(" ", width - #v[i][1])
            end
            if (#v[i][2] < width) then
                v[i][2] = v[i][2] .. string.rep(fg, width - #v[i][2])
            end
            if (#v[i][3] < width) then
                v[i][3] = v[i][3] .. string.rep(bg, width - #v[i][3])
            end
        end
    end
end

local function drawOnImage(self, image, frame, x, y, t, typ)
    if (#image[1][1][1] < x + #t - 1) or (#image < y) then
        resizeCanvas(self, image, x + #t - 1, y)
        if (self:getAutoSize()) then
            self:setSize(#image[1][1][1], #image[1])
        end
    end
    image[frame][y][typ] = sub(image[frame][y][typ], 1, x - 1) .. t .. sub(image[frame][y][typ], x + #t)
    self:updateRender()
end

--- Draws text on the image
---@param x number
---@param y number
---@param text string
---@param frame? number
---@return Image
function Image:drawText(x, y, text, frame)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, text, "string")
    expect(4, frame, "string", "nil")
    local image = self:getImage()
    local _frame = self:getFrame()
    drawOnImage(self, image, frame or _frame, x, y, text, 1)
    return self
end

--- Draws foreground on the image
---@param x number
---@param y number
---@param fg string
---@param frame? number
function Image:drawForeground(x, y, fg, frame)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, fg, "string")
    expect(4, frame, "string", "nil")
    local image = self:getImage()
    local _frame = self:getFrame()
    drawOnImage(self, image, frame or _frame, x, y, fg, 2)
    return self
end

--- Draws background on the image
---@param x number
---@param y number
---@param bg string
---@param frame? number
function Image:drawBackground(x, y, bg, frame)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, bg, "string")
    expect(4, frame, "string", "nil")
    local image = self:getImage()
    local _frame = self:getFrame()
    drawOnImage(self, image, frame or _frame, x, y, bg, 3)
    return self
end

return Image
