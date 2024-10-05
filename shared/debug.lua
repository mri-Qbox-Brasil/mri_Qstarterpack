local isServer = IsDuplicityVersion()

---@param type string
---@param message string
---@description Print a message to the console with a specific type
---@usage debugPrint("info", "This is an info message")
function debugPrint(type, message)
    if not Config.Debug then
        return
    end

    local typeLabels = {
        ["info"] = "^2[INFO]^7",
        ["error"] = "^1[ERROR]^7",
        ["warning"] = "^3[WARNING]^7",
        ["success"] = "^2[SUCCESS]^7",
        ["debug"] = "^5[DEBUG]^7",
    }

    local identifier = isServer and "^5[SERVER]^7" or "^4[CLIENT]^7"

    if typeLabels[type] then
        print(typeLabels[type] .. " " .. identifier .. " " .. message)
    else
        print("^2[INFO] " .. identifier .. " " .. message)
    end
end