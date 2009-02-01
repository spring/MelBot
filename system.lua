--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    system.lua
--  brief:   defines the global entries placed into a melon's table
--  author:  Dave Rodgers (modified by Jan Holthusen)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (System == nil) then

  System = {
    --
    --  Helper functions
    --

    GetCommand = GetCommand,
    SplitParameters = SplitParameters,
    CheckPermission = CheckPermission,

    --
    --  Additional libraries
    --

    lfs = lfs,
    socket = socket,
    http = http,
    ltn12 = ltn12,

    --
    --  Standard libraries
    --
    --io = io,
    --os = os,
    math = math,
    --debug = debug,
    table = table,
    string = string,
    --package = package,
    --coroutine = coroutine,
    
    --  
    --  Standard functions and variables
    --
    assert         = assert,
    error          = error,

    print          = print,
    
    next           = next,
    pairs          = pairs,
    ipairs         = ipairs,

    tonumber       = tonumber,
    tostring       = tostring,
    type           = type,

    collectgarbage = collectgarbage,
    gcinfo         = gcinfo,

    unpack         = unpack,
    select         = select,

    --dofile         = dofile,
    --loadfile       = loadfile,
    --loadlib        = loadlib,
    loadstring     = loadstring,
    --require        = require,

    
    getmetatable   = getmetatable,
    setmetatable   = setmetatable,

    rawequal       = rawequal,
    rawget         = rawget,
    rawset         = rawset,

    getfenv        = getfenv,
    setfenv        = setfenv,

    pcall          = pcall,
    xpcall         = xpcall,

    _VERSION       = _VERSION
  }

end
