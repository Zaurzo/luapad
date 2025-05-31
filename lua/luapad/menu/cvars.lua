local conVarValueCache = {}
local conVarCallbackCache = {}

local conVarList = {
    "luapad_font_size_mn",
    "luapad_font_name_mn",
    "luapad_font_weight_mn",
    "luapad_theme_mn"
}

for k, name in ipairs( conVarList ) do
    local callbacks = cvars.GetConVarCallbacks( name )

    if callbacks then
        conVarCallbackCache[name] = callbacks[1][1]
    end

    conVarValueCache[name] = GetConVar( name ):GetString()
end

local function callCvarCallback( name, old, new )
    local callback = conVarCallbackCache[name]

    if callback then
        callback( name, old, new )
    end
end

-- FCVAR_ARCHIVE convars do not save on the menu state - we have to save them manually
local function saveChanges()
    file.Write( "luapad/menustate_cvars.json", util.TableToJSON( conVarValueCache ) )
end

-- Cvar callbacks are not called on the menu state - we have to call them manually
hook.Add( "Think", "luapad_cvars_callbacks", function()
    for k, name in ipairs( conVarList ) do
        local conVar = GetConVar( name )
        if not conVar then continue end

        local previousValue = conVarValueCache[name]
        local currentValue = conVar:GetString()

        if previousValue ~= currentValue then
            if previousValue ~= nil then
                callCvarCallback( name, previousValue, currentValue )
            end

            conVarValueCache[name] = currentValue

            saveChanges()
        end
    end
end )

hook.Add( "ShutDown", "luapad_cvars_save_changes", saveChanges )

local cvarSavedList = file.Read( "data/luapad/menustate_cvars.json", "MOD" )
if not cvarSavedList then return end

cvarSavedList = util.JSONToTable( cvarSavedList )

for name, value in pairs( cvarSavedList ) do
    RunConsoleCommand( name, value )
end