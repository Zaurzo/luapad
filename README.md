# Luapad
A simple lua run tool for Garry's Mod.
![image](https://github.com/user-attachments/assets/d66411e1-3f8e-4d35-8468-edaebbef5e42)

### Clientside console commands
```lua
luapad -- Opens the editor if you have permission to run it.
luapad_auth_refresh -- Rerequests the permission to use the editor.
```

The code executes in a env with some extra useful things
```lua
_G.me -- The code runner player entity
_G.tr -- The eyetrace of the code runner
_G.this -- The entity the code runner is looking at
_G.there -- The hitpos of the code runner eyetrace
_G.here -- The current position of the code runner
_G.bot -- player.GetBots()[1]
```

#### SV Hooks
```
LuapadCanRunSV ply | return true to allow
LuapadCanRunCL ply | return true to allow
LuapadRanSV ply code
```

#### SH Hooks
```
LuapadCustomizeEnv ply env
```
