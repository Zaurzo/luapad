luapad = luapad or {}

include( "luapad/shared/colors.lua" )
include( "luapad/shared/prettyprint.lua" )
include( "luapad/shared/code_execution.lua" )

include( "luapad/client/luapad_editorpanel.lua" )
include( "luapad/client/luapad_consolepanel.lua" )
include( "luapad/client/luapad_theme.lua" )
include( "luapad/client/functions.lua" )
include( "luapad/client/luapad.lua" )
include( "luapad/client/settings.lua" )
include( "luapad/client/console_hud.lua" )

include( "luapad/menu/cvars.lua" )
include( "luapad/menu/compilestring.lua" ) -- Re-implement CompileString to the menu state

-- Load DVerticalDivider in the menu state, as it isn't by default
if not vgui.Exists( "DVerticalDivider" ) then
    include( "vgui/dverticaldivider.lua" )
end