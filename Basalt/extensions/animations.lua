local floor, sin, cos, pi, sqrt, pow = math.floor, math.sin, math.cos, math.pi, math.sqrt, math.pow

-- You can find the easings here https://easings.net

local function lerp(s, e, pct)
    return s + (e - s) * pct
end

local function linear(t)
    return t
end

local function flip(t)
    return 1 - t
end

local function easeIn(t)
    return t * t * t
end

local function easeOut(t)
    return flip(easeIn(flip(t)))
end

local function easeInOut(t)
    return lerp(easeIn(t), easeOut(t), t)
end

local function easeOutSine(t)
    return sin((t * pi) / 2);
end

local function easeInSine(t)
    return flip(cos((t * pi) / 2))
end

local function easeInOutSine(t)
    return -(cos(pi * t) - 1) / 2
end

local function easeInBack(t)
    local c1 = 1.70158;
    local c3 = c1 + 1
    return c3 * t ^ 3 - c1 * t ^ 2
end

local function easeInCubic(t)
    return t ^ 3
end

local function easeInElastic(t)
    local c4 = (2 * pi) / 3;
    return t == 0 and 0 or (t == 1 and 1 or (-2 ^ (10 * t - 10) * sin((t * 10 - 10.75) * c4)))
end

local function easeInExpo(t)
    return t == 0 and 0 or 2 ^ (10 * t - 10)
end

local function easeInOutBack(t)
    local c1 = 1.70158;
    local c2 = c1 * 1.525;
    return t < 0.5 and ((2 * t) ^ 2 * ((c2 + 1) * 2 * t - c2)) / 2 or ((2 * t - 2) ^ 2 * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
end

local function easeInOutCubic(t)
    return t < 0.5 and 4 * t ^ 3 or 1 - (-2 * t + 2) ^ 3 / 2
end

local function easeInOutElastic(t)
    local c5 = (2 * pi) / 4.5
    return t == 0 and 0 or (t == 1 and 1 or (t < 0.5 and -(2 ^ (20 * t - 10) * sin((20 * t - 11.125) * c5)) / 2 or (2 ^ (-20 * t + 10) * sin((20 * t - 11.125) * c5)) / 2 + 1))
end

local function easeInOutExpo(t)
    return t == 0 and 0 or (t == 1 and 1 or (t < 0.5 and 2 ^ (20 * t - 10) / 2 or (2 - 2 ^ (-20 * t + 10)) / 2))
end

local function easeInOutQuad(t)
    return t < 0.5 and 2 * t ^ 2 or 1 - (-2 * t + 2) ^ 2 / 2
end

local function easeInOutQuart(t)
    return t < 0.5 and 8 * t ^ 4 or 1 - (-2 * t + 2) ^ 4 / 2
end

local function easeInOutQuint(t)
    return t < 0.5 and 16 * t ^ 5 or 1 - (-2 * t + 2) ^ 5 / 2
end

local function easeInQuad(t)
    return t ^ 2
end

local function easeInQuart(t)
    return t ^ 4
end

local function easeInQuint(t)
    return t ^ 5
end

local function easeOutBack(t)
    local c1 = 1.70158;
    local c3 = c1 + 1
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

local function easeOutCubic(t)
    return 1 - (1 - t) ^ 3
end

local function easeOutElastic(t)
    local c4 = (2 * pi) / 3;

    return t == 0 and 0 or (t == 1 and 1 or (2 ^ (-10 * t) * sin((t * 10 - 0.75) * c4) + 1))
end

local function easeOutExpo(t)
    return t == 1 and 1 or 1 - 2 ^ (-10 * t)
end

local function easeOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

local function easeOutQuart(t)
    return 1 - (1 - t) ^ 4
end

local function easeOutQuint(t)
    return 1 - (1 - t) ^ 5
end

local function easeInCirc(t)
    return 1 - sqrt(1 - pow(t, 2))
end

local function easeOutCirc(t)
    return sqrt(1 - pow(t - 1, 2))
end

local function easeInOutCirc(t)
    return t < 0.5 and (1 - sqrt(1 - pow(2 * t, 2))) / 2 or (sqrt(1 - pow(-2 * t + 2, 2)) + 1) / 2;
end

local function easeOutBounce(t)
    local n1 = 7.5625;
    local d1 = 2.75;

    if (t < 1 / d1) then
        return n1 * t * t
    elseif (t < 2 / d1) then
        local a = t - 1.5 / d1
        return n1 * a * a + 0.75;
    elseif (t < 2.5 / d1) then
        local a = t - 2.25 / d1
        return n1 * a * a + 0.9375;
    else
        local a = t - 2.625 / d1
        return n1 * a * a + 0.984375;
    end
end

local function easeInBounce(t)
    return 1 - easeOutBounce(1 - t)
end

local function easeInOutBounce(t)
    return t < 0.5 and (1 - easeOutBounce(1 - 2 * t)) / 2 or (1 + easeOutBounce(2 * t - 1)) / 2;
end

local lerp = {
    linear = linear,
    lerp = lerp,
    flip = flip,
    easeIn = easeIn,
    easeInSine = easeInSine,
    easeInBack = easeInBack,
    easeInCubic = easeInCubic,
    easeInElastic = easeInElastic,
    easeInExpo = easeInExpo,
    easeInQuad = easeInQuad,
    easeInQuart = easeInQuart,
    easeInQuint = easeInQuint,
    easeInCirc = easeInCirc,
    easeInBounce = easeInBounce,
    easeOut = easeOut,
    easeOutSine = easeOutSine,
    easeOutBack = easeOutBack,
    easeOutCubic = easeOutCubic,
    easeOutElastic = easeOutElastic,
    easeOutExpo = easeOutExpo,
    easeOutQuad = easeOutQuad,
    easeOutQuart = easeOutQuart,
    easeOutQuint = easeOutQuint,
    easeOutCirc = easeOutCirc,
    easeOutBounce = easeOutBounce,
    easeInOut = easeInOut,
    easeInOutSine = easeInOutSine,
    easeInOutBack = easeInOutBack,
    easeInOutCubic = easeInOutCubic,
    easeInOutElastic = easeInOutElastic,
    easeInOutExpo = easeInOutExpo,
    easeInOutQuad = easeInOutQuad,
    easeInOutQuart = easeInOutQuart,
    easeInOutQuint = easeInOutQuint,
    easeInOutCirc = easeInOutCirc,
    easeInOutBounce = easeInOutBounce
}

local expect = require("expect").expect

--- @class Animation
local CustomAnimation = {}
CustomAnimation.__index = CustomAnimation

--- A new animation object
---@param self Animation The animation object.
---@return Animation
function CustomAnimation:new()
    local self = {}
    setmetatable(self, CustomAnimation)
    self.duration = 0
    self.curTime = 0
    self.timeIncrement = 0.05
    self.ease = "linear"
    self._animations = {}
    self._animationCache = {}
    self.onDoneHandler = {}
    return self
end

--- Sets the easing of the animation
---@param self Animation The animation object.
---@param ease string The easing of the animation.
---@return Animation
function CustomAnimation.setEase(self, ease)
    expect(1, self, "table")
    expect(2, ease, "string")
    if (lerp[ease] == nil) then
        error("Ease " .. ease .. " does not exist")
    end
    self.ease = ease
    return self
end

--- Sets the increment of the animation
---@param self Animation The animation object.
---@param increment number The increment of the animation.
---@return Animation
function CustomAnimation.setIncrement(self, increment)
    expect(1, self, "table")
    expect(2, increment, "number")
    self.timeIncrement = math.max(increment, 0.05)
    return self
end

--- Sets the duration to a specified time
---@param self Animation The animation object.
---@param time number The time to set the duration to.
---@return Animation
function CustomAnimation.on(self, time)
    expect(1, self, "table")
    expect(2, time, "number")
    time = floor(time * 20) / 20
    self.duration = time
    return self
end

--- Runs a function at the specified time (specified with :on)
---@param self Animation The animation object.
---@param func function The function to run.
---@return Animation
function CustomAnimation.run(self, func)
    expect(1, self, "table")
    expect(2, func, "function")
    local inserted = false
    for k, v in pairs(self._animations) do
        if (v.time == self.duration) then
            table.insert(v.anims, func)
            inserted = true
            break
        end
    end
    if (not inserted) then
        table.insert(self._animations, {
            time = self.duration,
            anims = {func}
        })
    end
    return self
end

--- Waits for a specified time
---@param self Animation The animation object.
---@param time number The time to wait.
---@return Animation
function CustomAnimation.wait(self, time)
    expect(1, self, "table")
    expect(2, time, "number")
    time = floor(time * 20) / 20
    self.duration = self.duration + time
    return self
end

---@private
function CustomAnimation.update(self, timerId)
    expect(1, self, "table")
    expect(2, timerId, "number")
    if (timerId == self.timerId) then
        self.curTime = self.curTime + self.timeIncrement
        if (self.curTime >= self.duration) then
            if (#self.onDoneHandler > 0) then
                for _, v in pairs(self.onDoneHandler) do
                    v()
                end
            end
            self._animationCache = {}
            os.cancelTimer(self.timerId)
            return
        end
        for k, v in pairs(self._animationCache) do
            if (v.time <= self.curTime) then
                for _, anim in pairs(v.anims) do
                    anim(self)
                end
                table.remove(self._animationCache, k)
            end
        end
        self.timerId = os.startTimer(self.timeIncrement)
    end
end

--- Plays the animation
---@param self Animation The animation object.
function CustomAnimation.play(self)
    expect(1, self, "table")
    self.curTime = 0
    self.timerId = os.startTimer(self.timeIncrement)
    for k, v in pairs(self._animations) do
        self._animationCache[k] = {
            time = v.time,
            anims = {}
        }
        for _, anim in pairs(v.anims) do
            table.insert(self._animationCache[k].anims, anim)
        end
    end
end

--- Stops the animation
---@param self Animation The animation object.
function CustomAnimation.stop(self)
    expect(1, self, "table")
    os.cancelTimer(self.timerId)
end

--- Adds a function to run when the animation is done
---@param self Animation The animation object.
function CustomAnimation.onDone(self, func)
    expect(1, self, "table")
    expect(2, func, "function")
    table.insert(self.onDoneHandler, func)
    return self
end

--- @class VisualElement
local Animation = {}

local function animationMoveHelper(element, v3, v4, duration, offset, ease, get, set)
    local animation = CustomAnimation:new()
    animation:setEase(ease or "linear")
    if (offset ~= nil) then
        animation:wait(offset)
    end
    local v1, v2 = get(element)
    for i = 0.05, duration, 0.05 do
        animation:run(function(self)
            local pct = lerp[self.ease](i / duration)
            local newV1 = math.floor(lerp.lerp(v1, v3, pct) + 0.5)
            local newV2 = math.floor(lerp.lerp(v2, v4, pct) + 0.5)
            set(element, newV1, newV2)
        end):wait(0.05)
    end
    animation:onDone(function()
        set(element, v3, v4)
        for k, v in pairs(element.animations) do
            if (v == posAnimation) then
                table.remove(element.animations, k)
                break
            end
        end
    end):play()
    table.insert(element.animations, animation)
    return animation
end

--- Moves the element to the specified position from its current position.
---@param self VisualElement The element to animate.
---@param x number The x position.
---@param y number The y position.
---@param duration? number The duration of the animation.
---@param offset? number The offset of the animation.
---@param ease? string The easing of the animation.
function Animation:animatePosition(x, y, duration, offset, ease)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, duration, "number", "nil")
    expect(5, offset, "number", "nil")
    expect(6, ease, "string", "nil")
    return animationMoveHelper(self, x, y, duration, offset, ease, self.getPosition, self.setPosition)
end

--- Animates to the specified size from the current size.
---@param self VisualElement The element to animate.
---@param width number The width.
---@param height number The height.
---@param duration? number The duration of the animation.
---@param offset? number The offset of the animation.
---@param ease? string The easing of the animation.
function Animation:animateSize(width, height, duration, offset, ease)
    expect(1, self, "table")
    expect(2, width, "number")
    expect(3, height, "number")
    expect(4, duration, "number", "nil")
    expect(5, offset, "number", "nil")
    expect(6, ease, "string", "nil")
    return animationMoveHelper(self, width, height, duration, offset, ease, self.getSize, self.setSize)
end

--- Animates the element to the specified offset from the current offset. Only available for elements with offset properties
---@param self VisualElement The element to animate.
---@param x number The x offset.
---@param y number The y offset.
function Animation:animateOffset(x, y, duration, offset, ease)
    expect(1, self, "table")
    expect(2, x, "number")
    expect(3, y, "number")
    expect(4, duration, "number", "nil")
    expect(5, offset, "number", "nil")
    expect(6, ease, "string", "nil")
    if (self.getOffset == nil or self.setOffset == nil) then
        error("Element " .. self:getType() .. " does not have offset!")
    end
    return animationMoveHelper(self, x, y, duration, offset, ease, self.getOffset, self.setOffset)
end

--- Creates a new animation object attached to the element.
function Animation:newAnimation(self)
    expect(1, self, "table")
    return CustomAnimation:new()
end

---@protected
function Animation.extensionProperties(original)
    local Element = require("basaltLoader").load("BasicElement")
    Element:initialize("VisualElement")
    Element:addProperty("animations", "table", {})
end

---@protected
function Animation.init(original)
    local baseEvent = original.event

    original.event = function(self, event, timerId, ...)
        if (event == "timer") then
            for _, v in pairs(self.animations) do
                v:update(timerId)
            end
        end

        if (baseEvent) then
            return baseEvent(self, event, timerId, ...)
        end
    end
end

return {
    VisualElement = Animation
}
