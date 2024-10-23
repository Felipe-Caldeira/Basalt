local Logger = {}
Logger.__index = Logger

fs.delete("basaltLogs.txt")

function Logger.new(filename, prefix)
    local self = setmetatable({}, Logger)
    self.filename = filename or "basaltLogs.txt"
    self.prefix = prefix or "Debug"
    return self
end

function Logger:setFile(filename)
    self.filename = filename
end

function Logger:setPrefix(prefix)
    self.prefix = prefix
end

function Logger:log(...)
    local file = io.open(self.filename, "a")
    if (file == nil) then
        error("Could not open file " .. self.filename .. "!")
    end
    local args = {...}
    local message = ""
    for _, v in pairs(args) do
        message = message .. tostring(v) .. " "
    end
    file:write("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "][" .. self.prefix .. "]: " .. message .. "\n")
    file:close()
end

setmetatable(Logger, {
    __call = function(self, ...)
        local instance = Logger.new()
        instance:log(...)
    end
})

return Logger
