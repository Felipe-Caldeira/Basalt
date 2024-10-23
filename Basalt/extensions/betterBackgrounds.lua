local bbgExtension = {}

function bbgExtension.extensionProperties(original)
    original:initialize("VisualElement")
    original:addProperty("backgroundSymbol", "char", "")
    original:addProperty("backgroundSymbolColor", "color", colors.red)
end

function bbgExtension.init(original)
    original:extend("Init", function(self)
        local originalRender = self.render
        self.render = function(self)
            originalRender(self)
            local bg = self:getBackgroundSymbol()
            if (bg ~= "") or (bg ~= " ") then
                local width, height = self:getSize()
                bg = bg:sub(1, 1)
                for i = 1, height do
                    self:addText(1, i, bg:rep(width))
                end
            end
        end
        return self
    end)
end

return {
    VisualElement = bbgExtension
}
