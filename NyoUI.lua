animation = {__type = "Animation", name = ""}
animation.__index = animation

local NyoUI = {debugger=true,updater=false}

local object = {} -- Base class for all UI elements

local activeFrame
local _frames = {}
local animations = {}
local keyModifier = {}
local parentTerminal = term.current()


--Utility Functions:
local function getTextHorizontalAlign(text, w, textAlign)
    local text = string.sub(text, 1, w)
    local n = w-string.len(text)
    if(textAlign=="right")then
        text = string.rep(" ", n)..text
    elseif(textAlign=="center")then
        text = string.rep(" ", math.floor(n/2))..text..string.rep(" ", math.floor(n/2))
        text = text..(string.len(text) < w and " " or "")
    else
        text = text..string.rep(" ", n)
    end
    return text
end

local function getTextVerticalAlign(h,textAlign)
local offset = 0
    if(textAlign=="center")then
        offset = h%2 == 0 and math.floor(h / 2)-1 or math.floor(h / 2)
    end
    if(textAlign=="bottom")then
        offset = h
    end
    return offset
end

local function rpairs(t)
	return function(t, i)
		i = i - 1
		if i ~= 0 then
			return i, t[i]
		end
	end, t, #t + 1
end

local function copyVar(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[copyVar(orig_key)] = copyVar(orig_value)
        end
        setmetatable(copy, copyVar(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function callAll(tab,...)
    if(tab~=nil)then
        if(#tab>0)then
            for k,v in pairs(tab)do
                v(...)
            end
        end
    end
end

--------------
--Animation System
animation.new = function(name)
    local newElement = {name=name,animations={},nextWaitTimer=0,index=1,infiniteloop=false}
    setmetatable(newElement, animation)
    table.insert(animations, newElement)
    return newElement
end

function animation:addAnimation(func)
    table.insert(self.animations, {f=func,t=self.nextWaitTimer})
    self.nextWaitTimer = 0
    return self
end

function animation:wait(timer)
    self.nextWaitTimer = timer
    return self
end

function animation:onPlay() -- internal function, don't use it unless you know what you do!
    if(self.playing)then
        self.animations[self.index].f(self)
        self.index = self.index+1

        if(self.animations[self.index]~=nil)then
            if(self.animations[self.index].t>0)then
                self.timeObj = os.startTimer(self.animations[self.index].t)
            else
                self:onPlay()
            end
        else
            if(self.infiniteloop)then
                self.index = 1
                if(self.animations[self.index].t>0)then
                    self.timeObj = os.startTimer(self.animations[self.index].t)
                else
                    self:onPlay()
                end
            end
        end
    end
end

function animation:play(infiniteloop)
    if(infiniteloop~=nil)then self.infiniteloop=infiniteloop end
    self.playing = true
    if(self.animations[self.index]~=nil)then
        if(self.animations[self.index].t>0)then
            self.timeObj = os.startTimer(self.animations[self.index].t)
        else
            self:onPlay()
        end
    end
    return self
end

function animation:cancel()
    os.cancelTimer(self.timeObj)
    self.playing = false
    self.infiniteloop = false
    self.index = 0
    return self
end
-----------





--Object Constructors:
--(base class for every element/object even frames)
function object:new()
    local newElement = {__type = "Object",name="",links={},zIndex=1,drawCalls=0,x=1,y=1,w=1,h=1,draw=false,changed=true,bgcolor=colors.black,fgcolor=colors.white,hanchor="left",vanchor="top"}
    setmetatable(newElement, {__index = self})
    return newElement
end

function object:copy(obj)
local newElement = {}
    for k,v in pairs(obj)do
        newElement[k] = v
    end
    setmetatable(newElement, {__index = self})
    return newElement
end

timer = object:new()
function timer:new()
    local newElement = {__type = "Timer"}
    setmetatable(newElement, {__index = self})
    return newElement
end

checkbox = object:new()
function checkbox:new()
    local newElement = {__type = "Checkbox",symbol="\42",zIndex=5,bgcolor=colors.lightBlue,fgcolor=colors.black, value = false}
    setmetatable(newElement, {__index = self})
    return newElement
end

radio = object:new()
function radio:new()
    local newElement = {__type = "Radio",symbol="\7",zIndex=5,bgcolor=colors.lightBlue,fgcolor=colors.black, value = "", items={}}
    setmetatable(newElement, {__index = self})
    return newElement
end

label = object:new()
function label:new()
    local newElement = {__type = "Label", value=""}
    setmetatable(newElement, {__index = self})
    return newElement
end

input = object:new()
function input:new()
    local newElement = {__type = "Input",zIndex=5,bgcolor=colors.lightBlue,fgcolor=colors.black,w=5, value = "", iType = "text"}
    setmetatable(newElement, {__index = self})
    return newElement
end

button = object:new()
function button:new()
    local newElement = {__type = "Button",zIndex=5,bgcolor=colors.lightBlue,fgcolor=colors.black,w=5,horizontalTextAlign="center",verticalTextAlign="center",value=""}
    setmetatable(newElement, {__index = self})
    return newElement
end

dropdown = object:new()
function dropdown:new()
    local newElement = {__type = "Dropdown",zIndex=10,bgcolor=colors.lightBlue,fgcolor=colors.black,w=5,horizontalTextAlign="center",items={},value={text="",fgcolor=colors.black,bgcolor=colors.lightBlue}}
    setmetatable(newElement, {__index = self})
    return newElement
end

list = object:new()
function list:new()
    local newElement = {__type = "List",index=1,colorIndex=1,textColorIndex=1,zIndex=5,itemColors={colors.lightGray},itemTextColors={colors.black},symbol=">",bgcolor=colors.lightGray,fgcolor=colors.black,w=8,h=5,horizontalTextAlign="center",items={},value={text=""}}
    setmetatable(newElement, {__index = self})
    return newElement
end

textfield = object:new()
function textfield:new()
    local newElement = {__type = "Textfield",hIndex=1,wIndex=1,textX=1,textY=1,zIndex=5,bgcolor=colors.gray,fgcolor=colors.black,w=10,h=4,value="",lines={""}}
    setmetatable(newElement, {__index = self})
    return newElement
end

scrollbar = object:new()
function scrollbar:new()
    local newElement = {__type = "Scrollbar",value=1,zIndex=5,bgcolor=colors.gray,fgcolor=colors.black,w=5,h=1,barType="vertical", symbolColor=colors.lightGray, symbol = " "}
    setmetatable(newElement, {__index = self})
    return newElement
end

program = object:new()
function program:new()
    local newElement = {__type = "Program",value="",zIndex=5,bgcolor=colors.black,fgcolor=colors.white,w=12,h=6}
    setmetatable(newElement, {__index = self})
    return newElement
end

frame = object:new()
function frame:new(name,scrn,frameObj)
    local parent = scrn~=nil and scrn or term.current()
    local w, h = parent.getSize()
    local newElement = {}
    if(frameObj~=nil)then
        newElement = object:copy(frameObj)
        newElement.fWindow = window.create(parent,1,1,frameObj.w,frameObj.h)
    else
        newElement = {__type = "Frame",name=name, parent = parent,zIndex=1, fWindow = window.create(parent,1,1,w,h),x=1,y=1,w=w,h=h, objects={},objZKeys={},bgcolor = colors.black, fgcolor=colors.white,barActive = false, title="New Frame", titlebgcolor = colors.lightBlue, titlefgcolor = colors.black, horizontalTextAlign="left",focusedObject={}, isMoveable = false,cursorBlink=false}
    end
    setmetatable(newElement, {__index = self})
    return newElement
end
--------
 
--object methods
function object:show()
    self.draw = true
    self.changed = true
    return self
end

function object:hide()
    self.draw = false
    self.changed = true
    return self
end

function object:changeVisibility()
    if(self.draw)then
        self:hide()
    else
        self:show()
    end
    return self
end

function object:isVisible()
    return self.draw
end

function object:getName()
    return self.name
end

function object:setPosition(x,y)
    self.x = tonumber(x)
    self.y = tonumber(y)
    self.changed = true
    return self
end

function object:setBackground(color)
    self.bgcolor = color
    self.changed = true
    return self
end

function object:setForeground(color)
    self.fgcolor = color
    self.changed = true
    return self
end

--Object Events:-----
function object:onClick(func)
    if(self.clickFunc==nil)then self.clickFunc = {} end
    table.insert(self.clickFunc,func)
    return self
end

function object:onClickUp(func)
    if(self.upFunc==nil)then self.upFunc = {} end
    table.insert(self.upFunc,func)
    return self
end

function object:onMouseDrag(func)
    if(self.dragFunc==nil)then self.dragFunc = {} end
    table.insert(self.dragFunc,func)
    return self
end

function object:onChange(func)
    if(self.changeFunc==nil)then self.changeFunc = {} end
    table.insert(self.changeFunc,func)
    return self
end

function object:onKey(func)
    if(self.keyEventFunc==nil)then self.keyEventFunc = {} end
    table.insert(self.keyEventFunc,func)
    return self
end

function object:onLoseFocus(func)
    if(self.loseFocusEventFunc==nil)then self.loseFocusEventFunc = {} end
    table.insert(self.loseFocusEventFunc,func)
    return self
end

function object:onGetFocus(func)
    if(self.getFocusEventFunc==nil)then self.getFocusEventFunc = {} end
    table.insert(self.getFocusEventFunc,func)
    return self
end
--------------------

function object:setSize(w,h)
    self.w = tonumber(w)
    self.h = tonumber(h)
    self.changed = true
    return self
end

function object:getHeight()
    return self.h
end

function object:getWidth()
    return self.w
end

function object:linkTo(obj)
    obj:link(self)
    return self
end
local a = 0
function object:link(obj) -- does not work correctly needs a fix dsfgsdfgfsdg
    if(obj.__type==self.__type)then
        self.links[obj.name] = obj
    end
    a = a+1
    return self
end

function object:isLinkedTo(obj)
    return (obj[self.name] ~= nil)
end

function object:isLinked(obj)
    return (self[obj.name] ~= nil)
end

function object:setValue(val)
    self.value = val
    self.changed = true
    for _,v in pairs(self.links)do
        v.value = val
        v.changed = true
    end

    callAll(self.changeFunc,self,self.args)
    return self
end

function object:getValue()
    return self.value;
end

function object:setCustomArgs(args)
    self.args = args
    return self;
end

function object:setTextAlign(halign,valign)
    self.horizontalTextAlign = halign
    if(valign~=nil)then self.verticalTextAlign = valign end
    self.changed = true
    return self
end

function object:drawObject()
    if(self.draw)then
        self.drawCalls = self.drawCalls + 1
    end
end

function object:setAnchor(...)
    if(type(...)=="string")then
            if(...=="right")or(...=="left")then
                self.hanchor = ...
            end
            if(...=="top")or(...=="bottom")then
                self.vanchor = ...
            end
    end
    if(type(...)=="table")then
        for _,v in pairs(...)do
        if(v=="right")or(v=="left")then
            self.hanchor = v
        end
        if(v=="top")or(v=="bottom")then
            self.vanchor = v
        end
    end
end
    return self
end

function object:relativeToAbsolutePosition(x,y) -- relative position
    if(x==nil)then x = self.x end
    if(y==nil)then y = self.y end

    if(self.frame~=nil)then
        local fx,fy = self.frame:relativeToAbsolutePosition()
        x=fx+x-1
        y=fy+y-1
    end
    return x, y
end

function object:getAnchorPosition(x,y)
    if(x==nil)then x = self.x end
    if(y==nil)then y = self.y end
    if(self.hanchor=="right")then
        x = self.frame.w-x-self.w+2
    end
    if(self.vanchor=="bottom")then
        y = self.frame.h-y-self.h+2
    end
    return x, y
end

function object:isFocusedObject()
    if(self.frame~=nil)then
        return self == self.frame.focusedObject
    end
    return false
end

function object:mouseEvent(event,typ,x,y) -- internal class, dont use unless you know what you do
local vx,vy = self:relativeToAbsolutePosition(self:getAnchorPosition())
    if(vx<=x)and(vx+self.w>x)and(vy<=y)and(vy+self.h>y)then
        if(self.frame~=nil)then self.frame:setFocusedElement(self) end
        if(event=="mouse_click")then
            if(self.clickFunc~=nil)then
                callAll(self.clickFunc,self,typ,x,y)
            end
        elseif(event=="mouse_up")then
            if(self.upFunc~=nil)then
                callAll(self.upFunc,self,typ,x,y)
            end
        elseif(event=="mouse_drag")then
            if(self.dragFunc~=nil)then
                callAll(self.dragFunc,self,typ,x,y)
            end
        end
        return true
    end
    return false
end

function object:eventListener(event,p1,p2,p3,p4)
    
end

function object:keyEvent(event,typ) -- internal class, dont use unless you know what you do
    if(self.keyEventFunc~=nil)then
        callAll(self.keyEventFunc,self,typ)
    end
end

function object:setFocus()    
    if(self.frame~=nil)then
        self.frame:setFocusedElement(self)
    end
    return self
end

function object:loseFocusEvent()   
    if(self.loseFocusEventFunc~=nil)then
        callAll(self.loseFocusEventFunc,self)
    end
end

function object:getFocusEvent()    
    if(self.getFocusEventFunc~=nil)then
        callAll(self.getFocusEventFunc,self)
    end
end

function object:setZIndex(index)
    self.frame:changeZIndexOfObj(self,index)
    return self
end


function object:setParent(frame)
    if(frame.__type=="Frame")then
        if(self.frame~=nil)then
            self.frame:removeObject(self)
        end
        self.frame = frame
        self.frame:addObject(self)
        if(self.draw)then 
            self:show() 
        end
    end
    return self
end
--object end

--Frame object
NyoUI.createFrame = function(name, scrn) -- this is also just a frame, but its a level 0 frame
local obj = frame:new(name,scrn or parentTerminal)
    if(_frames[name] == nil)then
        _frames[name] = obj
        obj.fWindow.setVisible(false)
        return obj;
    else
        return _frames[name];
    end
end

NyoUI.removeFrame = function(name)
    _frames[name].fWindow.setVisible(false)
    _frames[name] = nil
end

function frame:addFrame(frameObj) -- with this you also create frames, but it needs to have a parent frame (level 1 or more frame)
    if(self:getObject(frameObj) == nil)then
        local obj
        if(type(frameObj)=="string")then
            obj = frame:new(frameObj,self.fWindow)
        elseif(type(frameObj)=="table")and(frameObj.__type=="Frame")then
            obj = frame:new(frameObj.name,self.fWindow,frameObj)
        end
        obj.frame=self;
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..frameObj.." already exists";
    end
end

function frame:setParentFrame(parent) -- if you want to change the parent of a frame. even level 0 frames can have a parent (they will be 'converted' *habschi*)
    if(parent.__type=="Frame")and(parent~=self.frame)then
        if(self.frame~=nil)then
            self.frame:removeObject(self)
        end
        self.parent = parent.fWindow
        self.frame = parent
        self.fWindow.setVisible(false)
        self.fWindow = window.create(parent.fWindow,self.x,self.y,self.w,self.h)
        self.frame:addObject(self)
        if(self.draw)then 
            self:show() 
        end
    end
    return self
end

function frame:showBar(active) -- shows the top bar
    self.barActive = active ~= nil and active or true
    self.changed = true
    return self
end

function frame:isModifierActive(key)
    if(key==340)or(key=="shift")then
        return keyModifier[340]
    end
    if(key==341)or(key=="ctrl")then
        return keyModifier[341]
    end
    if(key==342)or(key=="alt")then
        return keyModifier[342]
    end
    return keyModifier[key]
end

function frame:setTitle(title,fgcolor,bgcolor) -- changed the title in your top bar
    self.title=title
    if(fgcolor~=nil)then self.titlefgcolor = fgcolor end
    if(bgcolor~=nil)then  self.titlebgcolor = bgcolor end
    self.changed = true
    return self
end

function frame:setTitleAlign(align) -- changes title align
    self.horizontalTextAlign = align
    self.changed = true
    return self
end

function frame:setSize(width, height) -- frame size
    object.setSize(self,width,height)
    self.fWindow.reposition(self.x,self.y,width,height)
    return self
end

function frame:setPosition(x,y) -- pos
    object.setPosition(self,x,y)
    self.fWindow.reposition(x,y)
    return self
end

function frame:show() -- you need to call to be able to see the frame
    object.show(self)
    self.fWindow.setBackgroundColor(self.bgcolor)
    self.fWindow.setTextColor(self.fgcolor)
    self.fWindow.setVisible(true)
    self.fWindow.redraw()
    if(self.frame == nil)then
        activeFrame = self
    end
    return self
end

function frame:hide() -- hides the frame (does not remove setted values)
    object.hide(self)
    self.fWindow.setVisible(false)
    self.fWindow.redraw()
    self.parent.clear()
    return self
end

function frame:remove() -- removes the frame completly
    if(self.frame~=nil)then
        object.hide(self)
    end
    self.changed = true
    self.draw = false
    self.fWindow.setVisible(false)
    _frames[self.name] = nil
    self.parent.clear()
end

function frame:getObject(name) -- you can find objects by their name
    if(self.objects~=nil)then
        for _,b in pairs(self.objects)do
            for _,v in pairs(b)do
                if(v.name==name)then
                    return v
                end
            end
        end
    end
end

function frame:removeObject(obj) -- you can remove objects by their name
    if(self.objects~=nil)then
        for a,b in pairs(self.objects)do
            for k,v in pairs(b)do
                if(v==obj)then
                    table.remove(self.objects[a],k)
                    return;
                end
            end
        end
    end
end

function frame:addObject(obj) -- you can add a object manually, normaly you shouldn't use this function, it get called internally
    if(self.objects[obj.zIndex]==nil)then
        for x=0,#self.objZKeys do
            if(self.objZKeys[x]~=nil)then
                if(obj.zIndex >self.objZKeys[x])then
                    table.insert(self.objZKeys,x,obj.zIndex)
                end       
            else
                table.insert(self.objZKeys,x,obj.zIndex)
            end     
        end
        if(#self.objZKeys<=0)then
            table.insert(self.objZKeys,obj.zIndex)
        end
        local cache = {}
        for k,v in pairs(self.objZKeys)do
            if(self.objects[v]~=nil)then
                cache[v] = self.objects[v]
            else
                cache[v] = {}
            end
        end
        self.objects = cache
    end
    table.insert(self.objects[obj.zIndex],obj)
end

function frame:drawObject()  -- this draws the frame, you dont need that function, it gets called internally
    object.drawObject(self)
    if(self.draw)then
        if(self.drag)and(self.frame==nil)then
            self.parent.clear()
        end
        self.fWindow.clear()
        if(self.barActive)then
            self.fWindow.setBackgroundColor(self.titlebgcolor)
            self.fWindow.setTextColor(self.titlefgcolor)
            self.fWindow.setCursorPos(1,1)
            self.fWindow.write(getTextHorizontalAlign(self.title,self.w,self.horizontalTextAlign))
        end

        local keys = {}
        for k in pairs(self.objects)do
            table.insert(keys,k)
        end
        for _,b in rpairs(keys)do
            for k,v in pairs(self.objects[b])do  
                if(v.draw~=nil)then  
                    v:drawObject()
                end
            end
        end

        if(self.focusedObject.cursorX~=nil)and(self.focusedObject.cursorY~=nil)then        
            self.fWindow.setCursorPos(self.focusedObject.cursorX, self.focusedObject.cursorY)
        end

        if(self.focusedObject.__type=="Program")then
            if not(self.focusedObject.process:isDead())then
                term.redirect(self.focusedObject.pWindow)
                self.focusedObject.pWindow.restoreCursor()
            end
        else
            self.fWindow.setTextColor(self.cursorColor or self.fgcolor)
            self.fWindow.setCursorBlink(self.cursorBlink)
        end
        if(self.focusedObject.__type=="Frame")then
            term.redirect(self.focusedObject.fWindow)
            self.focusedObject.fWindow.restoreCursor()
        end

        self.fWindow.setBackgroundColor(self.bgcolor)
        self.fWindow.setTextColor(self.fgcolor)
        self.fWindow.setVisible(true)
        self.fWindow.redraw()
    end
end

function frame:setCursorBlink(bool,color)
    if(self.frame~=nil)then
        --self.frame:setCursorBlink(bool)
    end
    self.cursorBlink = bool
    self.cursorColor = color
end

function frame:mouseEvent(event,typ,x,y) -- internal mouse event, should make it local but as lazy as i am..
    local fx,fy = self:relativeToAbsolutePosition(self:getAnchorPosition())
    if(self.drag)and(self.draw)then        
        if(event=="mouse_drag")then
            local parentX=1;local parentY=1
            if(self.frame~=nil)then
                parentX,parentY = self.frame:relativeToAbsolutePosition(self.frame:getAnchorPosition())
            end
            self:setPosition(x+self.xToRem-(parentX-1),y-(parentY-1))
        end
        if(event=="mouse_up")then
            self.drag = false
        end
        return true
    end

    if(object.mouseEvent(self,event,typ,x,y))then

        if(x>fx+self.w-1)or(y>fy+self.h-1)then return end

            local keys = {}
            for k in pairs(self.objects)do
                table.insert(keys,k)
            end

            for _,b in pairs(keys)do
                for _,v in rpairs(self.objects[b])do
                    if(v.draw~=false)then                
                        if(v.__type=="Frame")then
                            v:removeFocusedElement()
                        end
                    end
                end
            end


            for _,b in pairs(keys)do
                for _,v in rpairs(self.objects[b])do
                    if(v.draw~=false)then                
                        if(v:mouseEvent(event,typ,x,y))then
                            return true
                        end
                    end
                end
            end
        if(self.isMoveable)then
            if(x>=fx)and(x<=fx+self.w)and(y==fy)and(event=="mouse_click")then
                self.drag = true
                self.xToRem = fx-x
            end
        end
    end
    if(fx<=x)and(fx+self.w>x)and(fy<=y)and(fy+self.h>y)then
        self:removeFocusedElement()
        return true
    end
    return false
end

function frame:eventListener(event,p1,p2,p3,p4)
    local keys = {}
    local terminatingprogram = false
    for k in pairs(self.objects)do
        table.insert(keys,k)
    end
    for _,b in pairs(keys)do
        for _,v in rpairs(self.objects[b])do
            if(v.draw~=false)then       
                v:eventListener(event,p1,p2,p3,p4)

                if(v:isFocusedObject()and(v.__type=="Program"))then
                    terminatingprogram = true
                end
            end
        end
    end
    --if(event=="terminate")then NyoUI.debug(terminatingprogram) end -- kack buggy
    if(event=="terminate")and(terminatingprogram == false)then 
        if(self.terminatedTime==nil)then self.terminatedTime = 0 end
        if(self.terminatedTime+5<=os.clock())then
            --if("asd"=="b")then
                NyoUI.stopUpdate()
                for k,v in pairs(_frames)do
                    v:hide()
                end
                term.redirect(parentTerminal)
                term.setCursorPos(1,1)
                term.clear()
            --end
        end
    end
end

function frame:keyEvent(event,key)-- internal key event, should make it local but as lazy i am..
    for _,b in pairs(self.objects)do
        for _,v in pairs(b)do
            if(v.draw~=false)then
                if(v:keyEvent(event,key))then
                    return true
                end
            end
        end
    end
    return false
end

function frame:changeZIndexOfObj(obj, zindex)-- this function is not working right now
    self.objects[obj.zIndex][obj.name] =  nil
    obj.zIndex = zindex
    self:addObject(obj)
end

function frame:setFocusedElement(obj)-- you can set the focus of an element in a frame
    if(self:getObject(obj.name)~=nil)then
        if(self.focusedObject~=obj)then
            if(self.focusedObject.name~=nil)then
                self.focusedObject:loseFocusEvent()
            end
            obj:getFocusEvent()
            self.focusedObject = obj
        end
    end
    return self
end

function frame:removeFocusedElement()-- and here you can remove the focus
    if(self.focusedObject.name~=nil)then
        self.focusedObject:loseFocusEvent()
    end
    self.focusedObject = {}
end

function frame:getFocusedElement()--gets the current focused element
    return self.focusedObject
end

function frame:loseFocusEvent()--event which gets fired when the frame lost the focus in this case i remove the cursor blink from the active input object
    object.loseFocusEvent(self)
    self.cursorBlink = false
    self.fWindow.setCursorBlink(false)
end

function frame:getFocusEvent()--event which gets fired when the frame gets the focus
local frameList = {}
    for k,v in pairs(self.frame.objects[self.zIndex])do
        if(self~=v)then
            table.insert(frameList,v)
        end
    end
    table.insert(frameList,self)
    self.frame.objects[self.zIndex] = frameList
    self.changed = true
end


function frame:setMoveable(mv)--you can make the frame moveable (Todo: i want to make all objects moveable, so i can create a ingame gui editor MUHUHHUH)
    self.isMoveable = mv
    return self;
end
--Frames end


--Timer object
function frame:addTimer(name)--adds the timer object
    if(self:getObject(name) == nil)then
        local obj = timer:new()
        obj.name = name;obj.frame=self;
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function timer:setTime(timer, repeats)--tobecontinued
    self.timer = timer
    if(repeats==nil)then repeats = -1 end
    if(repeats>0)then
        self.repeats = repeats
    else
        self.repeats = -1
    end
    return self
end

function timer:start(timer, repeats)
    self.active = true
    if(timer~=nil)then self.timer = timer end
    if(repeats~=nil)then self.repeats = repeats end
    self.timeObj = os.startTimer(self.timer)
    return self
end

function timer:cancel()
    self.active = false
    os.cancelTimer(self.timeObj)
    return self
end

function timer:onCall(func)
    self.call = func
    return self
end
--Timer end


--Checkbox object
function frame:addCheckbox(name)
    if(self:getObject(name) == nil)then
        local obj = checkbox:new()
        obj.name = name;obj.frame=self;
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function checkbox:setSymbol(symbol)
    self.symbol = string.sub(symbol,1,1)
    self.changed = true
    return self
end

function checkbox:drawObject()
    object.drawObject(self) -- Base class
    if(self.draw)then
        self.frame.fWindow.setCursorPos(self:getAnchorPosition())
        self.frame.fWindow.setBackgroundColor(self.bgcolor)
        self.frame.fWindow.setTextColor(self.fgcolor)
        if(self.value)then
            self.frame.fWindow.write(self.symbol)
        else
            self.frame.fWindow.write(" ")
        end
        self.changed = false
    end
end

function checkbox:mouseEvent(event,typ,x,y) -- we have to switch the order of object.mouseEvent with checkbox:mouseEvent, because the value should be changed before we call user click events
    local vx,vy = self:relativeToAbsolutePosition(self:getAnchorPosition())
    if(vx<=x)and(vx+self.w>x)and(vy<=y)and(vy+self.h>y)then
        if(event=="mouse_click")then
            self:setValue(not self.value)
            self.changed = true
        end
    end
    if(object.mouseEvent(self,event,typ,x,y))then return true end
    return false
end
--Checkbox end

--Radio object
function frame:addRadio(name)
    if(self:getObject(name) == nil)then
        local obj = radio:new()
        obj.name = name;obj.frame=self;
        obj.bgcolor = self.bgcolor
        obj.fgcolor = self.fgcolor
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function radio:setSymbol(symbol)
    self.symbol = string.sub(symbol,1,1)
    self.changed = true
    return self
end

function radio:addItem(text,x,y,bgcolor,fgcolor,...)
    if(x==nil)or(y==nil)then
        table.insert(self.items,{text=text,bgcolor=(bgcolor ~= nil and bgcolor or self.bgcolor),fgcolor=(fgcolor ~= nil and fgcolor or self.fgcolor),x=0,y=#self.items,vars=table.pack(...)})
    else
        table.insert(self.items,{text=text,bgcolor=(bgcolor ~= nil and bgcolor or self.bgcolor),fgcolor=(fgcolor ~= nil and fgcolor or self.fgcolor),x=x,y=y,vars=table.pack(...)})
    end
    if(#self.items==1)then
        self:setValue(self.items[1])
    end
    return self
end

function radio:removeItem(item)
    if(type(item)=="table")then
        for k,v in pairs(self.items)do
            if(v==item)then
                table.remove(self.items,k)
                break;
            end
        end
    elseif(type(item)=="number")then
        if(self.items[item]~=nil)then
            table.remove(self.items,item)
        end
    end
    return self
end

function radio:mouseEvent(event,typ,x,y)
    if(object.mouseEvent(self,event,typ,x,y))then
        if(#self.items>0)then
            local dx,dy = self:relativeToAbsolutePosition(self:getAnchorPosition())
            for _,v in pairs(self.items)do
                if(dx<=x)and(dx+v.x+string.len(v.text)+1>x)and(dy+v.y==y)then
                    self:setValue(v)
                    self.changed = true
                    if(self.changeFunc~=nil)then
                        self.changeFunc(self)
                    end
                    return true
                end
            end
        end
    end
    return false
end

function radio:drawObject()
    object.drawObject(self) -- Base class
    if(self.draw)then
        if(#self.items>0)then
            for _,v in ipairs(self.items)do
                local objx, objy = self:getAnchorPosition()
                self.frame.fWindow.setBackgroundColor(v.bgcolor)
                self.frame.fWindow.setTextColor(v.fgcolor)
                self.frame.fWindow.setCursorPos(objx+v.x,objy+v.y)
                if(v==self.value)then
                    self.frame.fWindow.write(self.symbol..v.text)
                else
                    self.frame.fWindow.write(" "..v.text)
                end
            end
        end
        self.changed = false
    end
end
--Radio end

--Label object
function frame:addLabel(name)
    if(self:getObject(name) == nil)then
        local obj = label:new()
        obj.bgcolor = self.bgcolor
        obj.fgcolor = self.fgcolor
        obj.name=name;obj.frame=self;
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function label:setText(text)
    self:setValue(text)
    self.w = string.len(text)
    return self
end

function label:drawObject()
    object.drawObject(self) -- Base class
    if(self.draw)then
        self.frame.fWindow.setCursorPos(self:getAnchorPosition())
        self.frame.fWindow.setBackgroundColor(self.bgcolor)
        self.frame.fWindow.setTextColor(self.fgcolor)
        self.frame.fWindow.write(self.value:sub(1,self.w))
        self.changed = false
    end
end
--Label end

function frame:addInput(name)
    if(self:getObject(name) == nil)then
        local obj = input:new()
        obj.name = name;obj.frame=self;
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function input:setInputType(typ)
    self.iType = typ
    self.changed = true
    return self
end

function input:mouseEvent(event,typ,x,y)
        if(object.mouseEvent(self,event,typ,x,y))then
            local anchX,anchY = self:getAnchorPosition()
            self.frame.fWindow.setCursorPos(anchX+(string.len(self.value) < self.w-1 and string.len(self.value) or self.w-1),anchY)
            self.cursorX = anchX+(string.len(self.value) < self.w-1 and string.len(self.value) or self.w-1)
            self.cursorY = anchY
            self.frame.fWindow.setCursorBlink(true)
            return true
        end
    return false
end

function input:getValue()
    if(self.iType=="number")then
        if(tonumber(self.value)~=nil)then
            return tonumber(self.value)
        else
            self:setValue(0)
            return 0
        end
    end
    return self.value
end

function input:keyEvent(event,key)
    if(self:isFocusedObject())then
        if(self.draw)then
            if(event=="key")then
                if(key==259)then
                    self:setValue(string.sub(self.value,1,string.len(self.value)-1))
                end
                if(key==257)then -- on enter
                    if(self.inputActive)then
                        self.inputActive = false
                        self.fWindow.setCursorBlink(false)
                    end
                end
            end
            if(event=="char")then
                if(self.iType=="number")then 
                    local cache = self.value
                    if (key==".")or(tonumber(key)~=nil)then
                        self:setValue(self.value..key)
                    end
                    if(tonumber(self.value)==nil)then
                        self:setValue(cache)
                    end
                else
                    self:setValue(self.value..key)
                end
            end
            local anchX,anchY = self:getAnchorPosition()
            self.cursorX = anchX+(string.len(self.value) < self.w and string.len(self.value) or self.w-1)
            self.cursorY = anchY
            if(self.changeFunc~=nil)then
                self.changeFunc(self.acveInput)
            end
        end
    end
end

function input:drawObject()
    object.drawObject(self) -- Base class
    local text = ""
    if(self.draw)then
        if(string.len(self.value)>=self.w)then
            text = string.sub(self.value, string.len(self.value)-self.w+2, string.len(self.value))
            if(self.iType=="password")then
                text = string.sub(string.rep("*",self.value:len()), string.len(self.value)-self.w+2, string.len(self.value))
            else
                text = string.sub(self.value, string.len(self.value)-self.w+2, string.len(self.value))
            end
        else
            if(self.iType=="password")then
                text = string.rep("*",self.value:len())
            else
                text = self.value
            end

        end
        local n = self.w-string.len(text)
        text = text..string.rep(" ", n)
        self.frame.fWindow.setCursorPos(self:getAnchorPosition())
        self.frame.fWindow.setBackgroundColor(self.bgcolor)
        self.frame.fWindow.setTextColor(self.fgcolor)
        self.frame.fWindow.write(text)

        self.changed = false
    end
end

function input:getFocusEvent()
    object.getFocusEvent(self)
    self.frame:setCursorBlink(true,self.fgcolor)
end

function input:loseFocusEvent()
    object.loseFocusEvent(self)
    if(self.iType=="number")then
        if(tonumber(self.value)==nil)then
            self:setValue(0)
        end
    end
    self.frame:setCursorBlink(false)
end

function frame:addButton(name)
    if(self:getObject(name) == nil)then
        local obj = button:new()
        obj.name = name;obj.frame=self;
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function button:drawObject()
    object.drawObject(self) -- Base class
    if(self.draw)then
        local x,y = self:getAnchorPosition()
        local yOffset = getTextVerticalAlign(self.h,self.verticalTextAlign)
            self.frame.fWindow.setBackgroundColor(self.bgcolor)
            self.frame.fWindow.setTextColor(self.fgcolor)
        for line=0,self.h-1 do
            self.frame.fWindow.setCursorPos(x,y+line)
            if(line==yOffset)then
                self.frame.fWindow.write(getTextHorizontalAlign(self.value, self.w, self.horizontalTextAlign))
            else
                self.frame.fWindow.write(string.rep(" ", self.w))
            end
        end
        self.changed = false
    end
end

function button:setText(text)
    return self:setValue(text)
end
function frame:addDropdown(name)
    if(self:getObject(name) == nil)then
        local obj = dropdown:new()
        obj.name = name;obj.frame=self;
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function dropdown:addItem(text,bgcolor,fgcolor,...)
    table.insert(self.items,{text=text,bgcolor=(bgcolor ~= nil and bgcolor or self.bgcolor),fgcolor=(fgcolor ~= nil and fgcolor or self.fgcolor),vars=...})
    if(#self.items==1)then
        self:setValue(self.items[1])
    end
    return self
end

function dropdown:removeItem(item)
    if(type(item)=="table")then
        for k,v in pairs(self.items)do
            if(v==item)then
                table.remove(self.items,k)
                break;
            end
        end
    elseif(type(item)=="number")then
        if(self.items[item]~=nil)then
            table.remove(self.items,item)
        end
    end
    return self
end

function dropdown:setActiveItemBackground(color)
    self.activeItemBackground = color
    self.changed = true
    return self
end

function dropdown:setActiveItemForeground(color)
    self.activeItemForeground = color
    self.changed = true
    return self
end

function dropdown:setItemColors(...)
    self.itemColors = table.pack(...)
    self.itemColorIndex = 1
    self.changed = true
    return self
end

function dropdown:setItemTextColors(...)
    self.itemTextColors = table.pack(...)
    self.itemTextColorIndex = 1
    self.changed = true
    return self
end

function dropdown:drawObject()
    object.drawObject(self) -- Base class
    if(self.draw)then
        self.frame.fWindow.setCursorPos(self:getAnchorPosition())
        self.frame.fWindow.setBackgroundColor(self.value.bgcolor)
        self.frame.fWindow.setTextColor(self.value.fgcolor)
        self.frame.fWindow.write(getTextHorizontalAlign(self.value.text, self.w, self.horizontalTextAlign))

        if(self:isFocusedObject())then
            if(#self.items>0)then
                self.itemColorIndex = 1
                self.itemTextColorIndex = 1
                local index = 1
                for _,v in ipairs(self.items)do
                    local objx, objy = self:getAnchorPosition()
                    self.frame.fWindow.setBackgroundColor(v.bgcolor)
                    if(self.itemColors~=nil)then
                        if(#self.itemColors>0)then
                            self.frame.fWindow.setBackgroundColor(self.itemColors[self.itemColorIndex])
                            self.itemColorIndex = self.itemColorIndex + 1
                            if(self.itemColorIndex>#self.itemColors)then
                                self.itemColorIndex = 1
                            end
                        end
                    end
                    if(self.itemTextColors~=nil)then
                        if(#self.itemTextColors>0)then
                            self.frame.fWindow.setTextColor(self.itemTextColors[self.itemTextColorIndex])
                            self.itemTextColorIndex = self.itemTextColorIndex + 1
                            if(self.itemTextColorIndex>#self.itemTextColors)then
                                self.itemTextColorIndex = 1
                            end
                        end
                    end
                    if(v==self.value)then
                        if(self.activeItemBackground~=nil)then
                            self.frame.fWindow.setBackgroundColor(self.activeItemBackground)
                        end
                        if(self.activeItemForeground~=nil)then
                            self.frame.fWindow.setTextColor(self.activeItemForeground)
                        end
                    end
                    self.frame.fWindow.setTextColor(v.fgcolor)
                    self.frame.fWindow.setCursorPos(objx,objy+index)
                    self.frame.fWindow.write(getTextHorizontalAlign(v.text, self.w, self.horizontalTextAlign))
                    index = index+1
                end
            end
        end
        self.changed = false
    end
end

function dropdown:mouseEvent(event,typ,x,y)
    object.mouseEvent(self,event,typ,x,y)
    if(self:isFocusedObject())then
        if(#self.items>0)then
            local dx,dy = self:relativeToAbsolutePosition(self:getAnchorPosition())
            local index = 1
            for _,b in pairs(self.items)do
                if(dx<=x)and(dx+self.w>x)and(dy+index==y)then
                    self:setValue(b)
                    if(self.changeFunc~=nil)then
                        self.changeFunc(self)
                    end
                    self.frame:removeFocusedElement()
                    return true
                end
                index = index+1
            end
            if not((dx<=x)and(dx+self.w>x)and(dy<=y)and(dy+self.h>y))then
                self.frame:removeFocusedElement()
            end
            return true
        end
    end
    return false
end


function frame:addList(name)
    if(self:getObject(name) == nil)then
        local obj = list:new()
        obj.name = name;obj.frame=self;
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function list:drawObject()
    object.drawObject(self) -- Base class
    if(self.draw)then
        self.colorIndex = 1
        self.textColorIndex = 1
        for index=0,self.h-1 do
            self.frame.fWindow.setCursorPos(self:getAnchorPosition(self.x,self.y+index))
            self.frame.fWindow.setBackgroundColor(self.bgcolor)

            if(self.items[index+self.index]~=nil)then
                local bgCol = self.items[index+self.index].bgcolor or self.itemColors[self.colorIndex]
                local fgCol = self.items[index+self.index].fgcolor or self.itemTextColors[self.textColorIndex]
                if(self.items[index+self.index].bgcolor == nil)then self.colorIndex = self.colorIndex+1 end
                if(self.items[index+self.index].fgcolor == nil)then self.textColorIndex = self.textColorIndex+1 end
                if(self.colorIndex>#self.itemColors)then self.colorIndex = 1 end
                if(self.textColorIndex>#self.itemTextColors)then self.textColorIndex = 1 end
                self.frame.fWindow.setBackgroundColor(bgCol)
                self.frame.fWindow.setTextColor(fgCol)
                if(self.items[index+self.index]==self.value)then
                    if(self.activeItemBackground~=nil)then self.frame.fWindow.setBackgroundColor(self.activeItemBackground) end
                    if(self.activeItemForeground~=nil)then self.frame.fWindow.setTextColor(self.activeItemForeground) end
                    self.frame.fWindow.write(self.symbol..getTextHorizontalAlign(self.items[index+self.index].text, self.w-string.len(self.symbol), self.horizontalTextAlign))
                else
                    self.frame.fWindow.write(string.rep(" ", string.len(self.symbol))..getTextHorizontalAlign(self.items[index+self.index].text, self.w-string.len(self.symbol), self.horizontalTextAlign))
                end
            else
                self.frame.fWindow.write(getTextHorizontalAlign(" ", self.w, self.horizontalTextAlign))
            end
        end
        self.changed = false
    end
end

function list:mouseEvent(event,typ,x,y)
    if(object.mouseEvent(self,event,typ,x,y))then
        if(event=="mouse_click")or(event=="mouse_drag")then -- remove mouse_drag if i want to make objects moveable uwuwuwuw
            if(#self.items>0)then
                local dx,dy = self:relativeToAbsolutePosition(self:getAnchorPosition())
                for index=0,self.h do
                    if(self.items[index+self.index]~=nil)then
                        if(dx<=x)and(dx+self.w>x)and(dy+index==y)then
                            self:setValue(self.items[index+self.index])
                            self.changed = true
                            return true
                        end
                    end
                end
            end
        end
        if(event=="mouse_scroll")then
            self.index = self.index+typ
            if(self.index<1)then self.index = 1 end
            if(typ==1)then 
                if(#self.items>self.h)then 
                    if(self.index>#self.items+1-self.h)then 
                        self.index = #self.items+1-self.h 
                    end 
                else 
                    self.index = self.index-1 
                end 
            end
            self.changed = true
            return true
        end
    end
    return false
end

function list:onScrollbarChangeEvent(scrollbar)
        --self.index = (scrollbar.value/(scrollbar.maxValue/(scrollbar.barType=="vertical" and scrollbar.h or scrollbar.w)))
        self.index = math.floor(scrollbar.value)
        if(self.index<1)then self.index = 1 end
        if(self.index>#self.items+1-self.h)then self.index = #self.items+1-self.h end
end

function list:addScrollbar(obj)
    if(obj.__type=="Scrollbar")then
        self.scrollbar = obj
        self.scrollbar:setMaxValue(#self.items+1-self.h)
        self.scrollbar.args = self
        self.scrollbar:onChange(function(scrlb,lst) lst:onScrollbarChangeEvent(scrlb) end)
    end
    return self
end

function list:addItem(text,bgcolor,fgcolor,...)
    table.insert(self.items,{text=text,bgcolor=bgcolor,fgcolor=fgcolor,vars=...})
    if(#self.items==1)then
        self:setValue(self.items[1])
    end
    if(self.scrollbar~=nil)then
        self.scrollbar:setMaxValue(#self.items-self.h)
    end
    return self
end

function list:setItemColors(...)
    self.itemColors = table.pack(...)
    self.changed = true
    return self
end

function list:setItemTextColors(...)
    self.itemTextColors = table.pack(...)
    self.changed = true
    return self
end

function list:setIndex(index)
    self.index = index
    self.changed = true
    return self
end

function list:removeItem(item)
    if(type(item)=="table")then
        for k,v in pairs(self.items)do
            if(v==item)then
                table.remove(self.items,k)
                break;
            end
        end
    elseif(type(item)=="number")then
        if(self.items[item]~=nil)then
            table.remove(self.items,item)
        end
    end

    if(self.scrollbar~=nil)then
        self.scrollbar:setMaxValue(#self.items-self.h)
    end
    return self
end

function list:setSymbol(symbol)
    self.symbol = string.sub(symbol,1,1)
    self.changed = true
    return self
end

function list:setActiveItemBackground(color)
    self.activeItemBackground = color
    self.changed = true
    return self
end

function list:setActiveItemForeground(color)
    self.activeItemForeground = color
    self.changed = true
    return self
end

function frame:addTextfield(name)
    if(self:getObject(name) == nil)then
        local obj = textfield:new()
        obj.name = name;obj.frame=self;
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function textfield:keyEvent(event,key)
    if(self:isFocusedObject())then
        if(self.draw)then
            local anchX,anchY = self:getAnchorPosition()
            if(event=="key")then
                if(key==259)then -- on backspace
                    if(self.lines[self.textY]=="")then
                        if(self.textY>1)then
                            table.remove(self.lines,self.textY)
                            self.textX = self.lines[self.textY-1]:len()+1
                            self.wIndex = self.textX-self.w+1
                            if(self.wIndex<1)then self.wIndex = 1 end
                            self.textY = self.textY-1
                        end
                    elseif(self.textX<=1)then
                        if(self.textY>1)then
                            self.textX = self.lines[self.textY-1]:len()+1
                            self.wIndex = self.textX-self.w+1
                            if(self.wIndex<1)then self.wIndex = 1 end
                            self.lines[self.textY-1] = self.lines[self.textY-1]..self.lines[self.textY]
                            table.remove(self.lines,self.textY)
                            self.textY = self.textY-1
                        end
                    else
                        self.lines[self.textY] = self.lines[self.textY]:sub(1,self.textX-2)..self.lines[self.textY]:sub(self.textX,self.lines[self.textY]:len())
                        if(self.textX>1)then self.textX = self.textX-1 end
                        if(self.wIndex>1)then
                            if(self.textX<self.wIndex)then
                                self.wIndex = self.wIndex-1
                            end
                        end
                    end
                    if(self.textY<self.hIndex)then
                        self.hIndex = self.hIndex-1
                    end
                end
                if(key==257)then -- on enter
                    table.insert(self.lines,self.textY+1,self.lines[self.textY]:sub(self.textX,self.lines[self.textY]:len()))
                    self.lines[self.textY] = self.lines[self.textY]:sub(1,self.textX-1)

                    self.textY = self.textY+1
                    self.textX = 1
                    self.wIndex = 1
                    if(self.textY-self.hIndex>=self.h)then
                        self.hIndex = self.hIndex+1
                    end
                end
                if(key==258)then -- on tab

                    --self.lines[self.textY] = self.lines[self.textY]..string.rep(" ",self.w-(self.w-self.lines[self.textY]:len()))
                end
                if(key==265)then -- arrow up
                    if(self.textY>1)then
                        self.textY = self.textY-1
                        if(self.textX>self.lines[self.textY]:len()+1)then self.textX = self.lines[self.textY]:len()+1 end
                        if(self.wIndex>1)then
                            if(self.textX<self.wIndex)then
                                self.wIndex = self.textX-self.w+1                                
                                if(self.wIndex<1)then self.wIndex = 1 end
                            end
                        end
                        if(self.hIndex>1)then
                            if(self.textY<self.hIndex)then
                                self.hIndex = self.hIndex-1
                            end
                        end
                    end
                end
                if(key==264)then -- arrow down
                    if(self.textY<#self.lines)then
                        self.textY = self.textY+1
                        if(self.textX>self.lines[self.textY]:len()+1)then self.textX = self.lines[self.textY]:len()+1 end

                        if(self.textY>=self.hIndex+self.h)then
                            self.hIndex = self.hIndex+1
                        end
                    end
                end
                if(key==262)then -- arrow right
                    self.textX = self.textX+1
                    if(self.textY<#self.lines)then
                        if(self.textX>self.lines[self.textY]:len()+1)then
                            self.textX = 1
                            self.textY = self.textY+1
                        end
                    elseif(self.textX > self.lines[self.textY]:len())then
                        self.textX = self.lines[self.textY]:len()+1
                    end
                    if(self.textX<1)then self.textX = 1 end
                    if(self.textX<self.wIndex)or(self.textX>=self.w+self.wIndex)then
                        self.wIndex = self.textX-self.w+1
                    end 
                    if(self.wIndex<1)then self.wIndex = 1 end 

                end
                if(key==263)then -- arrow left
                    self.textX = self.textX-1
                    if(self.textX>=1)then
                        if(self.textX<self.wIndex)or(self.textX>=self.w+self.wIndex)then
                            self.wIndex = self.textX+1
                        end  
                    end
                    if(self.textY>1)then
                        if(self.textX<1)then
                            self.textY = self.textY-1
                            self.textX = self.lines[self.textY]:len()+1
                            self.wIndex = self.textX-self.w+1
                        end
                    end
                    if(self.textX<1)then self.textX = 1 end     
                    if(self.wIndex<1)then self.wIndex = 1 end 
                end
            end
            if(event=="char")then
                self.lines[self.textY] = self.lines[self.textY]:sub(1,self.textX-1)..key..self.lines[self.textY]:sub(self.textX,self.lines[self.textY]:len())
                self.textX = self.textX+1
                if(self.textX>=self.w+self.wIndex)then self.wIndex = self.wIndex+1 end
            end
            self.cursorX = anchX+(self.textX <= self.lines[self.textY]:len() and self.textX-1 or self.lines[self.textY]:len())-(self.wIndex-1)
            if(self.cursorX>self.x+self.w-1)then self.cursorX = self.x+self.w-1 end
            self.cursorY = anchY+(self.textY-self.hIndex < self.h and self.textY-self.hIndex or self.textY-self.hIndex-1)
            if(self.changeFunc~=nil)then
                callAll(self.changeFunc)
            end
        end
    end
end

function textfield:mouseEvent(event,typ,x,y)
    if(object.mouseEvent(self,event,typ,x,y))then
        if(event=="mouse_click")then
            local anchX,anchY = self:getAnchorPosition()
            local absX,absY = self:relativeToAbsolutePosition(self:getAnchorPosition())
            if(self.lines[y-absY+self.hIndex]~=nil)then
                self.textX = x-absX+self.wIndex
                self.textY = y-absY+self.hIndex
                if(self.textX>self.lines[self.textY]:len())then
                    self.textX = self.lines[self.textY]:len()+1
                end
                if(self.textX<self.wIndex)then
                    self.wIndex = self.textX-1
                    if(self.wIndex<1)then self.wIndex = 1 end
                end
                self.cursorX = anchX+self.textX-self.wIndex
                self.cursorY = anchY+self.textY-self.hIndex
                self.frame:setCursorBlink(true)
                self.changed = true
            end
        end
        
        if(event=="mouse_scroll")then -- buggggy
            self.hIndex = self.hIndex+typ
            if(self.hIndex<1)then self.hIndex = 1 end
            if(self.hIndex>=#self.lines-self.h)then self.hIndex = #self.lines-self.h end
            self.changed = true
        end
        return true
    end
    return false
end

function textfield:drawObject()
    object.drawObject(self) -- Base class
    if(self.draw)then
        for index=0,self.h-1 do
            self.frame.fWindow.setBackgroundColor(self.bgcolor)
            self.frame.fWindow.setTextColor(self.fgcolor)
            local text = ""
            if(self.lines[index+self.hIndex]~=nil)then 
                text = self.lines[index+self.hIndex]
            end
            text = text:sub(self.wIndex, self.w+self.wIndex-1)      
            local n = self.w-text:len()
            if(n<0)then n = 0 end
            text = text..string.rep(" ", n)

            self.frame.fWindow.setCursorPos(self:getAnchorPosition(self.x,self.y+index))
            self.frame.fWindow.write(text)
        end
        if(self.cursorX==nil)or(self.cursorX<self.x)or(self.cursorX>self.x+self.w)then self.cursorX = self.x end
        if(self.cursorY==nil)or(self.cursorY<self.y)or(self.cursorY>self.y+self.h)then self.cursorY = self.y end
        self.frame.fWindow.setCursorPos(self.cursorX,self.cursorY)

        self.changed = false
    end
end


function textfield:getFocusEvent()
    object.getFocusEvent(self)
    self.frame:setCursorBlink(true)
end

function textfield:loseFocusEvent()
    object.loseFocusEvent(self)
    self.frame:setCursorBlink(false)
end




function frame:addScrollbar(name)
    if(self:getObject(name) == nil)then
        local obj = scrollbar:new()
        obj.name = name;obj.frame=self;
        obj.maxValue = obj.h
        obj.value = obj.maxValue/obj.h
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function scrollbar:setSize(w,h)
    object.setSize(self,w,h)
    if(self.barType=="vertical")then
        self.maxValue = self.h
        self.value = self.maxValue/self.h
    elseif(self.barType=="horizontal")then
        self.maxValue = self.w
        self.value = self.maxValue/self.w
    end
    return self
end

function scrollbar:drawObject()
    object.drawObject(self) -- Base class
    if(self.draw)then
        local x,y = self:getAnchorPosition()
            self.frame.fWindow.setBackgroundColor(self.bgcolor)
            self.frame.fWindow.setTextColor(self.fgcolor)
        if(self.barType=="vertical")then
            for curPos=0,self.h-1 do
                self.frame.fWindow.setCursorPos(x,y+curPos)
                if(tostring(self.maxValue/self.h*(curPos+1))==tostring(self.value))then
                    self.frame.fWindow.setBackgroundColor(self.symbolColor)
                    self.frame.fWindow.write(string.rep(self.symbol,self.w))
                    self.frame.fWindow.setBackgroundColor(self.bgcolor)
                else
                    self.frame.fWindow.write(string.rep(" ",self.w))
                end
            end
        end
        if(self.barType=="horizontal")then
            for curPos=0,self.h-1 do
                self.frame.fWindow.setCursorPos(x,y+curPos)
                self.frame.fWindow.write(string.rep(" ",(self.value/(self.maxValue/self.w))-1))
                self.frame.fWindow.setBackgroundColor(self.symbolColor)
                self.frame.fWindow.write(self.symbol)
                self.frame.fWindow.setBackgroundColor(self.bgcolor)
                self.frame.fWindow.write(string.rep(" ",self.maxValue/(self.maxValue/self.w)-(self.value/(self.maxValue/self.w))))
            end
        end
        self.changed = false
    end
end

function scrollbar:mouseEvent(event,typ,x,y)
    if(object.mouseEvent(self,event,typ,x,y))then
        if(event=="mouse_click")or(event=="mouse_drag")then -- remove mouse_drag if i want to make objects moveable uwuwuwuw
            local dx,dy = self:relativeToAbsolutePosition(self:getAnchorPosition())
            if(self.barType=="vertical")then
                for index=0,self.h-1 do
                    if(dx<=x)and(dx+self.w>x)and(dy+index==y)then
                        self:setValue(self.maxValue/self.h*(index+1))
                        self.changed = true
                    end
                end
            end
            if(self.barType=="horizontal")then
                for index=0,self.w-1 do
                    if(dx+index==x)and(dy<=y)and(dy+self.y>y)then
                        self:setValue(self.maxValue/self.w*(index+1))
                        self.changed = true
                    end
                end
            end
        end
        if(event=="mouse_scroll")then
            self:setValue(self.value + (self.maxValue/(self.barType=="vertical" and self.h or self.w))*typ)
            self.changed = true
        end
        if(self.value>self.maxValue)then self:setValue(self.maxValue) end
        if(self.value<self.maxValue/(self.barType=="vertical" and self.h or self.w))then self:setValue(self.maxValue/(self.barType=="vertical" and self.h or self.w)) end
        return true
    end
end

function scrollbar:setSymbol(symbol)
    self.symbol = string.sub(symbol,1,1)
    self.changed = true
    return self
end

function scrollbar:setMaxValue(val)
    self.maxValue = val
    if(self.barType=="vertical")then
        self:setValue(self.maxValue/self.h)
    elseif(self.barType=="horizontal")then
        self:setValue(self.maxValue/self.w)
    end
    self.changed = true
    return self
end

function scrollbar:setSymbolColor(color)
    self.symbolColor = color
    self.changed = true
    return self
end

function scrollbar:setBarType(typ)
    self.barType = typ:lower()
    self.changed = true
    return self
end

local processes = {}
local process = {}
local processId = 0

function process:new(path,window,...)
    local args = table.pack( ... )
    local newP = setmetatable({path=path},{__index = self})
    newP.window = window
    newP.processId = processId
    newP.coroutine = coroutine.create(function()
        os.run({NyoUI=NyoUI}, path, table.unpack(args))
    end)
    processes[processId] = newP
    processId = processId + 1
    return newP
end

function process:resume(event, ...)
    term.redirect(self.window)
    local ok, result = coroutine.resume( self.coroutine, event, ... )
    self.window = term.current()
    if ok then
        self.filter = result
    else
        NyoUI.debug( result )
    end
end

function process:isDead()
    if(self.coroutine~=nil)then
        if(coroutine.status(self.coroutine)=="dead")then
            table.remove(processes, self.processId)
            return true
        end
    else
        return true
    end
    return false
end

function process:getStatus()
    if(self.coroutine~=nil)then
        return coroutine.status(self.coroutine)
    end
    return nil
end

function process:start()
    coroutine.resume(self.coroutine)
end

function frame:addProgram(name)
    if(self:getObject(name) == nil)then
        local obj = program:new()
        obj.name = name;obj.frame=self;
        obj.pWindow = window.create(self.fWindow,obj.x,obj.y,obj.w,obj.h)
        self:addObject(obj)
        return obj;
    else
        return nil, "id "..name.." already exists";
    end
end

function program:show()
    object.show(self)
    self.pWindow.setBackgroundColor(self.bgcolor)
    self.pWindow.setTextColor(self.fgcolor)
    self.pWindow.setVisible(true)
    return self
end

function program:hide()
    object.hide(self)
    self.pWindow.setVisible(false)
    return self
end

function program:setPosition(x,y)
    object.setPosition(self,x,y)
    self.pWindow.reposition(self.x, self.y)
    return self
end

function program:setSize(w,h)
    object.setSize(self,w,h)
    self.pWindow.reposition(self.x, self.y, self.w, self.h)
    return self
end

function program:getStatus()
    return process:getStatus()
end

function program:drawObject()
    object.drawObject(self) -- Base class
    if(self.draw)then
        self.pWindow.redraw()
        self.changed = false
    end
end

function program:execute(path,...)
    self.process = process:new(path, self.pWindow, ...)
    self.process:resume()
    return self
end

function program:stop()
    if(self.process~=nil)then
        if not(self.process:isDead())then
            self.process:resume("terminate")
            if(self.process:isDead())then
                self.pWindow.setCursorBlink(false)
            end
        end
    end
    return self
end

function program:mouseEvent(event,typ,x,y)
    if(object.mouseEvent(self,event,typ,x,y))then
        if(self.process==nil)then return false end
        if not(self.process:isDead())then
            local absX,absY = self:relativeToAbsolutePosition(self:getAnchorPosition())
            self.process:resume(event, typ, x-absX+1, y-absY+1)
        end
        return true
    end
end

function program:keyEvent(event,key)    
    if(self:isFocusedObject())then
        if(self.process==nil)then return false end
        if not(self.process:isDead())then
            object.keyEvent(event,key)
            if(self.draw)then
                self.process:resume(event, key)
            end
        end
    end
end

function program:eventListener(event,p1,p2,p3,p4)
    object.eventListener(self,event,p1,p2,p3,p4)
    if(self.process==nil)then return end
    if not(self.process:isDead())then
        if(event~="mouse_click")and(event~="mouse_up")and(event~="mouse_scroll")and(event~="mouse_drag")and(event~="key_up")and(event~="key")and(event~="char")and(event~="terminate")then
            self.process:resume(event,p1,p2,p3,p4)
        end
        if(event=="terminate")and(self:isFocusedObject())then
            self.frame.terminatedTime = os.clock()
            self.process:resume(event)
            self.pWindow.clear()
            self.pWindow.setCursorPos(1,1)
            self.pWindow.setCursorBlink(false)
        end
    end
end

local function checkTimer(timeObject)
    for a,b in pairs(activeFrame.objects)do
        for k,v in pairs(b)do  
            if(v.__type=="Timer")and(v.active)then 
                if(v.timeObj == timeObject)then
                    v.call(v)
                    if(v.repeats~=0)then
                        v.timeObj = os.startTimer(v.timer)
                        v.repeats = (v.repeats > 0 and v.repeats-1 or v.repeats)
                    end
                end
            end
        end
    end
    if(#animations>0)then
        for k,v in pairs(animations)do
            if(v.timeObj==timeObject)then
                v:onPlay()
            end
        end
    end
end

local function handleChangedObjectsEvent()
    local changed = activeFrame.changed
    for a,b in pairs(activeFrame.objects)do
        for k,v in pairs(b)do
            if(v.changed)then
                changed = true
            end
        end
    end
    if(changed)then
        if(activeFrame.draw)then
            activeFrame:drawObject()
        end
    end
end

if(NyoUI.debugger)then
    NyoUI.debugFrame = NyoUI.createFrame("NyoUIDebuggingFrame"):showBar():setBackground(colors.lightGray):setTitle("Debug",colors.black,colors.gray)
    NyoUI.debugList = NyoUI.debugFrame:addList("debugList"):setSize(NyoUI.debugFrame.w - 2, NyoUI.debugFrame.h - 3):setPosition(2,3):setSymbol(""):setBackground(colors.gray):setItemColors(colors.gray):setTextAlign("left"):show()
    NyoUI.debugFrame:addButton("back"):setAnchor("right"):setSize(1,1):setText("\42"):onClick(function() NyoUI.oldFrame:show() end):setBackground(colors.red):show()
    NyoUI.debugLabel = NyoUI.debugFrame:addLabel("debugLabel"):onClick(function() NyoUI.oldFrame = activeFrame NyoUI.debugFrame:show() end):setBackground(colors.black):setForeground(colors.white):setAnchor("bottom"):show()
end

function NyoUI.startUpdate()
    if not(NyoUI.updater)then
        handleChangedObjectsEvent()
        NyoUI.updater = true
        while NyoUI.updater do
            local event, p1,p2,p3,p4 = os.pullEventRaw()
            activeFrame:eventListener(event,p1,p2,p3,p4)
            if(event=="mouse_click")then
                activeFrame:mouseEvent(event,p1,p2,p3)
            end
            if(event=="mouse_scroll")then
                activeFrame:mouseEvent(event,p1,p2,p3)
            end
            if(event=="mouse_drag")then
                activeFrame:mouseEvent(event,p1,p2,p3)
            end
            if(event=="mouse_up")then
                activeFrame:mouseEvent(event,p1,p2,p3)
            end
            if(event=="timer")then
                checkTimer(p1)
            end
            if(event=="char")or(event=="key")then
                activeFrame:keyEvent(event,p1)
                keyModifier[p1] = true
            end
            if(event=="key_up")then
                keyModifier[p1] = false
            end
            handleChangedObjectsEvent()
        end
    end
end

function NyoUI.stopUpdate()
    NyoUI.updater = false
end

if(NyoUI.debugger)then
    function NyoUI.debug(...)
        local args = {...}
        if(activeFrame.name~="NyoUIDebuggingFrame")then
            NyoUI.debugLabel:setParent(activeFrame)
        end
        local str = ""
        for k,v in pairs(args)do
            str = str..tostring(v)..(#args~=k and ", " or "")
        end
        NyoUI.debugLabel:setText("[Debug] "..str)
        NyoUI.debugList:addItem(str)
        if(#NyoUI.debugList.items>NyoUI.debugList.h)then NyoUI.debugList:removeItem(1) end

        NyoUI.debugLabel:show()
    end

end

function NyoUI.getFrame(name)
    return _frames[name];
end

function NyoUI.getActiveFrame()
    if(activeFrame.name=="NyoUIDebuggingFrame")then
        return oldFrame
    end
    return activeFrame
end

return NyoUI;