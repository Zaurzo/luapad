-- https://gist.github.com/Zaurzo/6cbb742037e4dd79c873f18923479405

local throwError do
    local error = error

    local debug_getinfo = debug.getinfo
    local string_format = string.format
    local string_sub = string.sub

    function throwError(nparam, expected, got)
        local name = debug_getinfo(1, 'n').name or '?'
        local info = debug_getinfo(2, 'Sl')

        local msg = string_format("bad argument #%d to '%s' (%s expected, got %s)", nparam, name, expected, got)
        local source = string_sub(info.source, 2)

        return error(source .. ':' .. info.currentline .. ': ' .. msg, 3)
    end
end

local RunString = RunString
local ErrorNoHaltWithStack = ErrorNoHaltWithStack

local rawset = rawset
local rawget = rawget
local type = type

function CompileString(code, identifier, handleError)
    local tn = type(code)

    if tn ~= 'string' and tn ~= 'number' then
        return throwError(1, 'string', tn)
    end

    if identifier ~= nil then
        tn = type(identifier)

        if tn ~= 'string' and tn ~= 'number' then
            return throwError(2, 'string', tn)
        end
    else
        identifier = 'CompileString'
    end

    code = 'local function f(...)' .. code .. ' end\nrawset(_G,"_COMPILESTRING",f)'

    local err = RunString(code, identifier, false)

    if err then
        if handleError == false then
            return err
        else
            return ErrorNoHaltWithStack(err) -- tail call so it doesn't appear in stack
        end
    end

    local compiledFunc = rawget(_G, '_COMPILESTRING')
    if compiledFunc == nil then return end

    rawset(_G, '_COMPILESTRING', nil)

    return compiledFunc
end