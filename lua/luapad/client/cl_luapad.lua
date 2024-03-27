-- Autorefresh support
if IsValid( luapad.Frame ) then
    luapad.Frame:Remove()
end

function luapad.SaveScript()
    local contents = luapad.getCurrentScript()
    contents = string.gsub( contents, "   	", "\t" )
    local path = string.gsub( luapad.PropertySheet:GetActiveTab():GetPanel().path, "data/luapad", "", 1 )
    Msg( "data/luapad" .. path .. luapad.PropertySheet:GetActiveTab():GetPanel().name )

    if not file.Exists( path .. luapad.PropertySheet:GetActiveTab():GetPanel().name, "DATA" ) then
        luapad.SaveAsScript()
    else
        file.Write( path .. luapad.PropertySheet:GetActiveTab():GetPanel().name, contents )

        if file.Exists( path .. luapad.PropertySheet:GetActiveTab():GetPanel().name, "DATA" ) then
            luapad.SetStatus( "File succesfully saved!", Color( 72, 205, 72, 255 ) )
        else
            luapad.SetStatus( "Save failed! (check your filename for illegal characters)", Color( 205, 72, 72, 255 ) )
        end
    end
end

function luapad.SaveAsScript()
    Derma_StringRequest( "Luapad", "You are about to save a file, please enter the desired filename.", luapad.PropertySheet:GetActiveTab():GetPanel().path .. luapad.PropertySheet:GetActiveTab():GetPanel().name, function( filename )
        local contents = luapad.getCurrentScript()

        --I really do hate how '.' is a wildcard...
        if string.find( filename, "../" ) == 1 then
            filename = string.gsub( filename, "../", "", 1 )
        end

        local dirs = string.Explode( "/", string.gsub( filename, "data/", "", 1 ) )
        local d = ""

        for k, v in ipairs( dirs ) do
            if k == #dirs then break end --don't make a directory for the filename
            d = d .. v .. "/"

            if not file.IsDir( d, "DATA" ) then
                file.CreateDir( d )
            end
        end

        file.Write( string.gsub( filename, "data/", "", 1 ), contents )

        if file.Exists( string.gsub( filename, "data/", "", 1 ), "DATA" ) then
            luapad.SetStatus( "File succesfully saved!", Color( 72, 205, 72, 255 ) )
            luapad.PropertySheet:GetActiveTab():GetPanel().name = string.Explode( "/", filename )[#string.Explode( "/", filename )]
            luapad.PropertySheet:GetActiveTab():GetPanel().path = string.gsub( filename, luapad.PropertySheet:GetActiveTab():GetPanel().name, "", 1 )
            luapad.PropertySheet:GetActiveTab():SetText( string.Explode( "/", filename )[#string.Explode( "/", filename )] )
            luapad.PropertySheet:SetActiveTab( luapad.PropertySheet:GetActiveTab() )
        else
            luapad.SetStatus( "Save failed! (check your filename for illegal characters)", Color( 205, 72, 72, 255 ) )
        end
    end, nil, "Save", "Cancel" )
end

function luapad.SaveTabs()
    if not luapad.Frame then return end

    local store = {
        activetab = luapad.PropertySheet:GetActiveTab().name,
        tabs = {}
    }

    for _, v in pairs( luapad.PropertySheet.Items ) do
        local panel = v["Panel"]
        local name = panel.name
        local path = panel.path
        local content = panel:GetValue()
        if content == "" then continue end
        table.insert( store.tabs, { name = name, path = path, content = content } )
    end

    file.Write( "luapad/_tabs.txt", "luapad " .. util.Compress( util.TableToJSON( store ) ) )
end
hook.Add( "ShutDown", "luapad.SaveTabs", luapad.SaveTabs )

function luapad.LoadSavedTabs()
    if not file.Exists( "luapad/_tabs.txt", "DATA" ) then return end
    local store = util.JSONToTable( util.Decompress( file.Read( "luapad/_tabs.txt", "DATA" ):sub( 8 ) ) )

    if store then
        for _, v in pairs( store.tabs ) do
            luapad.AddTab( v.name, v.content, v.path )
        end

        for _, v in pairs( luapad.PropertySheet.Items ) do
            if v["Name"] == store.activetab then
                luapad.PropertySheet:SetActiveTab( v["Tab"] )
            end
        end
    end
end

function luapad.Toggle()
    if not luapad.CanUseCL( LocalPlayer() ) then
        print( "You don't have permission to use Luapad." )
        return
    end

    if IsValid( luapad.Frame ) then
        luapad.Frame:SetVisible( not luapad.Frame:IsVisible() )
        return
    end

    -- Build it, if it doesn't exist
    luapad.Frame = vgui.Create( "DFrame" )
    luapad.Frame:SetSize( ScrW() * 2 / 3, ScrH() * 2 / 3 )
    luapad.Frame:SetPos( ScrW() * 1 / 6, ScrH() * 1 / 6 )
    luapad.Frame:SetTitle( "Luapad" )
    luapad.Frame:ShowCloseButton( true )
    luapad.Frame:MakePopup()

    function luapad.Frame.btnClose:DoClick()
        luapad.Toggle()
        luapad.SaveTabs()
    end

    luapad.Toolbar = vgui.Create( "DPanelList", luapad.Frame )
    luapad.Toolbar:Dock( TOP )
    luapad.Toolbar:SetSize( luapad.Frame:GetWide() - 6, 22 )
    luapad.Toolbar:SetSpacing( 5 )
    luapad.Toolbar:EnableHorizontal( true )
    luapad.Toolbar:EnableVerticalScrollbar( false )

    luapad.PropertySheet = vgui.Create( "DPropertySheet", luapad.Frame )
    luapad.PropertySheet.tabScroller:DockMargin( 0, 0, 0, 0 )
    luapad.PropertySheet.tabScroller:SetOverlap( 0 )
    luapad.PropertySheet.____SetActiveTab = luapad.PropertySheet.SetActiveTab
    function luapad.PropertySheet:SetActiveTab( ... )
        luapad.PropertySheet:____SetActiveTab( ... )

        if luapad.PropertySheet:GetActiveTab() then
            local panel = luapad.PropertySheet:GetActiveTab():GetPanel()
            luapad.Frame:SetTitle( "Luapad - " .. panel.path .. panel.name )
        end
    end
    luapad.PropertySheet.tabScroller:SetTall( 22 )
    luapad.PropertySheet.tabScroller.SetTall = function() end
    luapad.PropertySheet.Paint = function() end

    local console = vgui.Create( "LuapadConsole", luapad.PropertySheet )
    luapad.Frame.Console = console

    local hdiv = vgui.Create( "DVerticalDivider", luapad.Frame )
    hdiv:Dock( FILL )
    hdiv:SetDividerHeight( 5 )
    hdiv:SetTop( luapad.PropertySheet )
    hdiv:SetBottom( console )
    hdiv:SetTopMin( 300 )
    hdiv:SetBottomMin( 100 )
    hdiv:SetTopHeight( luapad.Frame:GetTall() - 100 )

    luapad.PropertySheet:InvalidateLayout()

    luapad.NewTab()

    luapad.AddToolbarItem( "New (CTRL + N)", "icon16/page_white_add.png", luapad.NewTab )
    luapad.AddToolbarItem( "Open (CTRL + O)", "icon16/folder_page_white.png", luapad.OpenScript )
    luapad.AddToolbarItem( "Save (CTRL + S)", "icon16/disk.png", luapad.SaveScript )
    luapad.AddToolbarItem( "Save As (CTRL + ALT + S)", "icon16/disk_multiple.png", luapad.SaveAsScript )

    luapad.AddToolbarSpacer()

    local isSVUser = luapad.CanUseSV( LocalPlayer() )

    luapad.AddToolbarItem( "Run Clientside", "icon16/script_code.png", luapad.RunScriptClient )
    if isSVUser then
        luapad.AddToolbarItem( "Run Serverside", "icon16/script_code_red.png", luapad.RunScriptServer )

        luapad.AddToolbarSpacer()

        luapad.AddToolbarItem( "Run Shared", "icon16/script_lightning.png", function()
            luapad.RunScriptClient()
            luapad.RunScriptServer()
        end )
        luapad.AddToolbarItem( "Run on all clients", "icon16/script_palette.png", luapad.RunScriptServerClient )
        luapad.AddToolbarItem( "Run on specfic client", "icon16/script_go.png", function()
            local menu = DermaMenu()
            for _, v in pairs( player.GetAll() ) do
                if v == LocalPlayer() then continue end
                menu:AddOption( v:Nick(), function()
                    luapad.RunScriptOnClient( v )
                end )
            end
            menu:Open()
        end )
    end

    luapad.LoadSavedTabs()
end

function luapad.AddToolbarItem( tooltip, mat, func )
    local button = vgui.Create( "DImageButton" )
    button:SetImage( mat )
    button:SetTooltip( tooltip )
    button:SetSize( 16, 16 )
    button.DoClick = func
    luapad.Toolbar:AddItem( button )
end

function luapad.AddToolbarSpacer()
    local lab = vgui.Create( "DLabel" )
    lab:SetText( " | " )
    lab:SizeToContents()
    luapad.Toolbar:AddItem( lab )
end

function luapad.SetStatus( str, clr )
    if not IsValid( luapad.Frame ) and not IsValid( luapad.Frame.Console ) then return end

    luapad.Frame.Console:AddConsoleText( str, clr )
end

function luapad.AddTab( name, content, path )
    content = content or ""
    path = path or ""
    content = string.gsub( content, "\t", "	   " )

    local editor = vgui.Create( "LuapadEditor", luapad.PropertySheet )
    editor:SetText( content )
    editor:Dock( FILL )
    editor:RequestFocus()
    editor.name = name
    editor.path = path

    local sheet = luapad.PropertySheet:AddSheet( name, editor, "icon16/page_white.png", false, false )
    local dtab = sheet.Tab

    function dtab:DoRightClick()
        local menu = DermaMenu()
        menu:AddOption( "Close", function()
            local tabCount = table.Count( luapad.PropertySheet.Items )
            if tabCount == 1 then
                luapad.NewTab()
                luapad.PropertySheet:CloseTab( self, true )
                return
            end

            luapad.PropertySheet:CloseTab( self, true )
        end ):SetIcon( "icon16/cross.png" )

        menu:AddOption( "Save", function()
            luapad.SaveScript()
        end ):SetIcon( "icon16/disk.png" )

        menu:AddSpacer()

        menu:AddOption( "Close all but this", function()
            for _, v in pairs( luapad.PropertySheet.Items ) do
                if v["Tab"] == self then continue end
                luapad.PropertySheet:CloseTab( v["Tab"], true )
            end
        end ):SetIcon( "icon16/cross.png" )

        menu:AddOption( "Close all", function()
            for _, v in pairs( luapad.PropertySheet.Items ) do
                luapad.PropertySheet:CloseTab( v["Tab"], true )
            end
        end ):SetIcon( "icon16/cross.png" )

        menu:Open()
    end

    luapad.PropertySheet:SetActiveTab( luapad.PropertySheet.Items[table.Count( luapad.PropertySheet.Items )]["Tab"] )
    luapad.PropertySheet:InvalidateLayout()
end

local newTabNum = 1
function luapad.NewTab( content )
    if not isstring( content ) then
        content = ""
    end

    luapad.AddTab( "untitled" .. newTabNum .. ".txt", content, "data/luapad/" )

    newTabNum = newTabNum + 1
end

function luapad.OpenScript()
    if luapad.OpenTree then
        luapad.OpenTree:Remove()
    end

    local x, y = luapad.PropertySheet:GetPos()
    luapad.OpenTree = vgui.Create( "DTree", luapad.Frame )
    luapad.OpenTree:SetPadding( 5 )
    luapad.OpenTree:SetPos( x + luapad.PropertySheet:GetWide() - luapad.PropertySheet:GetWide() / 4, y + 22 )
    luapad.OpenTree:SetSize( luapad.PropertySheet:GetWide() / 4, luapad.PropertySheet:GetTall() - 23 )

    function luapad.OpenTree:DoClick( node )
        local fileName = node:GetFileName()
        if not fileName then return end
        luapad.AddTab( node.Label:GetValue(), file.Read( fileName, "GAME" ), node.Path )
    end

    luapad.OpenCloseButton = vgui.Create( "DButton", luapad.OpenTree )
    luapad.OpenCloseButton:SetSize( 16, 16 )
    luapad.OpenCloseButton:SetPos( luapad.OpenTree:GetWide() - 20, 4 )
    luapad.OpenCloseButton:SetText( "X" )
    luapad.OpenCloseButton:SetTooltip( "Close" )

    function luapad.OpenCloseButton:DoClick()
        luapad.OpenTree:Remove()
    end

    local node = luapad.OpenTree:AddNode( "garrysmod\\data" )
    node.RootFolder = "data"
    node:MakeFolder( "data", "GAME", true )
    node.Icon:SetImage( "icon16/computer.png" )

    local node2 = luapad.OpenTree:AddNode( "luapad" )
    node2.RootFolder = "data/luapad";
    node2:MakeFolder( "data/luapad", "GAME", true );
    node2.Icon:SetImage( "icon16/folder_page_white.png" );
end

concommand.Add( "luapad", luapad.Toggle )
