socket = require("socket")
lfs    = require("lfs")
ltn12  = require("ltn12")
http   = require("socket.http")

connectionManager = {
  connections = {},
  protocols = {},
  protocolInfos = {},
  melons = {},
  melonInfos = {},
  commands = {},
  helpTopics = {},
  calloutInfos = {},
  updates = 0
}
function connectionManager:Initialize()
  if config.permissions == nil then
    config.permissions = {}
  end
  if config.helpPermissions == nil then
    config.helpPermissions = {}
  end
  if config.permissionGroups == nil then
    config.permissionGroups = {}
  end

  self:GetProtocols()

  if type(config.connections) ~= "table" then
    print("You have to specify at least one connection in the config file.")
  else
    for i,v in ipairs(config.connections) do
      self:AddConnection(i, v)
    end
  end

  self:GetMelons()
end
function connectionManager:AddConnection(index, config)
  local prot = nil
  for _,v in ipairs(self.protocols) do
    if self.protocolInfos[v].name == config.protocol then
      prot = v
    end
  end
  if prot ~= nil then
    local newConn = {}
    setmetatable(newConn, { __index=prot })
    newConn.config = config
    newConn.connID = index
    table.insert(self.connections, newConn)
    self:SecureCall(newConn, "Initialize")
    self:SecureCall(newConn, "Login")
  end
end
function connectionManager:RemoveConnection(index)
  self:SecureCall(self.connections[index], "Shutdown")
  table.remove(self.connections, index)
  for i,v in ipairs(self.connections) do
    v.connID = i
  end
  if #self.connections == 0 then
    print("No connections left. Exiting...")
    connectionManager:Distribute("Shutdown")
    table.save(config, "config.lua")
    os.exit(1)
  end
end
function connectionManager:GetProtocols()
  for file in lfs.dir("Protocols") do
    if string.sub(file, -4) == ".lua" then
      local newProtocol = {}
      setmetatable(newProtocol, { __index=protocol:Create() })
      -- load the system calls into the melon table
      for k,v in pairs(System) do
        newProtocol[k] = v
      end
      newProtocol.connectionManager = connectionManager
      newProtocol.protocol = newProtocol
      newProtocol.config = config
      newProtocol = Include("Protocols/" .. file, newProtocol)
      if newProtocol ~= nil then
        self.protocolInfos[newProtocol] = newProtocol:GetInfo()
        self:AddProtocol(newProtocol)
      end
    end
  end
end
function connectionManager:AddProtocol(protocol)
  table.insert(self.protocols, protocol)
end
function connectionManager:GetMelons()
  for file in lfs.dir("Melons") do
    if string.sub(file, -4) == ".lua" then
      local melon = {}
      -- load the system calls into the melon table
      for k,v in pairs(System) do
        melon[k] = v
      end
      melon.bot = {}
      for k,v in pairs(callouts) do
        melon.bot[k] = function(self, ...)
          v(self, melon, ...)
        end
      end
      melon.melon = melon
      if config[file] == nil then
        config[file] = {}
      end
      melon.os = { clock=os.clock, time=os.time, date=os.date }
      melon.config = config[file]
      melon = Include("Melons/" .. file, melon)
      if melon ~= nil then
        self.melonInfos[melon] = { filename=file }
        if type(melon.GetInfo) == "function" and type(melon:GetInfo()) == "table" then
          self.melonInfos[melon].name = melon:GetInfo().name or file
          self.melonInfos[melon].desc = melon:GetInfo().desc or "No description available."
          self.melonInfos[melon].author = melon:GetInfo().author or "Unknown"
          self.melonInfos[melon].handler = melon:GetInfo().handler
        else
          self.melonInfos[melon].name = file
          self.melonInfos[melon].desc = "No description available."
          self.melonInfos[melon].author = "Unknown"
        end
        if self.melonInfos[melon].handler then
          melon.connectionManager = connectionManager
          melon.config = config
          melon.io = io
          melon.os = os
        end
        if config.permissions[self.melonInfos[melon].name] == nil then
          config.permissions[self.melonInfos[melon].name] = {}
        end
        if config.helpPermissions[self.melonInfos[melon].name] == nil then
          config.helpPermissions[self.melonInfos[melon].name] = {}
        end
        self:AddMelon(melon)
      end
    end
  end
end
function connectionManager:AddMelon(melon)
  table.insert(self.melons, melon)
  self:SecureCall(melon, "Initialize")
end
function connectionManager:Update()
  self.updates = self.updates + 1
  if self.updates % 600 == 0 then
    table.save(config, "config.lua")
  end
  self:Distribute("Update", self.updates)
end
function connectionManager:PM(to, message)
  if type(to) == "table" then
    if type(to.user) == "string" then
      self.connections[to.conn]:PM(to.user, message)
    else
      for _,v in ipairs(to) do
        self:PM(v, message)
      end
    end
  else
    self:Distribute("PM", to, message)
  end
end
function connectionManager:Say(conn, channel, message)
  if conn == 1 and channel == "main" then return end
  if self.connections[conn] then
    self.connections[conn]:Say(channel, message)
  end
end
function connectionManager:GotPM(from, message)
  if string.sub(message, 1, 1) == "!" then
    local cmd, params = SplitParameters(message, 2)
    local cmds = self.commands
    local perms = config.permissions
    if cmd == "!help" then
      cmds = self.helpTopics
      perms = config.helpPermissions
      if params == nil then
        print(from.user .. " is executing " .. message)
        self:PM(from, "I'm MelTraX' Lua bot. Enter '!help <topic>' for further help.")
        self:PM(from, "Topics:")
        for i,v in pairs(self.helpTopics) do
          if CheckPermission(perms, i, from, v[3]) then
            self:PM(from, "- " .. i .. " (" .. v[2] .. ")")
          end
        end
        return
      end
      cmd, params = SplitParameters(params, 2)
    else
      cmd = string.sub(cmd, 2)
    end
    cmdTable = cmds[cmd]
    if type(cmdTable) == "table" and CheckPermission(perms, cmd, from, cmdTable[3]) then
      print(from.user .. " is executing " .. message)
      local func, melon = cmdTable[1], cmdTable[3]
      local from, perms, cmd, melonname = from, perms, cmd, self.melonInfos[melon].name
      melon.bot.Reply = function(self, message)
        if from.channel and (perms[cmd].inchannels and table.contains(perms[cmd].inchannels, from.channel)
           or perms[melonname].inchannels and table.contains(perms[melonname].inchannels, from.channel)) then
          self:Say(from.conn, from.channel, message)
        else
          self:PM(from, message)
        end
      end
      local success, err = pcall(func, from, params)
      if (not success) then
        self:PM(
          { 'MelTraX', self.melonInfos[melon].author },
          'Failed to execute ' .. cmd .. ' in ' .. self.melonInfos[melon].name .. ' (' .. err .. ')'
        )
        self:PM(from, "Sorry, an error occured while executing that command. The author has been informed.")
        return nil
      end
      melon.bot.Reply = nil
    end
  else
    self:Distribute("GotPM", from, message)
  end
end
function connectionManager:Said(channel, from, message)
  if from.user == self.connections[from.conn].config.user then return end
  if string.sub(message, 1, 1) == "!" then
    from.channel = channel
    self:GotPM(from, message)
  else
    self:Distribute("Said", channel, from, message)
  end
end
function connectionManager:Distribute(functionName, ...)
  for _,connection in ipairs(self.connections) do
    self:SecureCall(connection, functionName, ...)
  end
  for _,melon in ipairs(self.melons) do
    self:SecureCall(melon, functionName, ...)
  end
end
function connectionManager:SecureCall(tbl, funcName, ...)
  if type(tbl[funcName]) == "function" then
    if config.debug then
      print('Calling ' .. funcName .. ' (' .. tostring(self.melonInfos[tbl] and self.melonInfos[tbl].name) .. ')')
    end
    local success, err = pcall(tbl[funcName], tbl, ...)
    if (not success) then
      print('Failed to execute ' .. tostring(self.melonInfos[tbl] and self.melonInfos[tbl].name) .. ':' .. tostring(funcName) .. ' (' .. tostring(err) .. ')')
      --[[
      self:PM(
        { 'MelTraX', self.melonInfos[tbl] and self.melonInfos[tbl].author } ,
        'Failed to execute ' .. tostring(self.melonInfos[tbl] and self.melonInfos[tbl].name) .. ':' .. tostring(funcName .. ' (' .. err .. ')'
      )
      ]]
    end
    if config.debug then
      print('Done calling ' .. funcName)
    end
  end
end

callouts = {}
function AddCallout(name, params, paramTypes, func)
  connectionManager.calloutInfos[name] = {
    params = params,
    paramTypes = paramTypes
  }
  callouts[name] = function(self, melon, ...)
    local paramsCorrect =  #params == #arg
    local p = { self = self, melon = melon }
    for i,v in ipairs(params) do
      if type(arg[i]) ~= paramTypes[i] then
        paramsCorrect = false
      else
        p[v] = arg[i]
      end
    end
    if not paramsCorrect then
      local argTypes = {}
      for i,v in ipairs(arg) do
        argTypes[i] = type(v)
      end
      local mI = connectionManager.melonInfos[melon]
      connectionManager:PM(
        { 'MelTraX', mI.author },
        mI.name .. ": Wrong parameters to " .. name .. "(" .. table.concat(params, ", ") .. ")."
      )
      connectionManager:PM(
        { 'MelTraX', mI.author },
        "Expected: " .. table.concat(paramTypes, ", ") .. " - Got: " .. table.concat(argTypes, ", ")
      )
    else
      func(p)
    end
  end
end
AddCallout("AddCommand", { "cmd", "func", "desc" }, { "string", "function", "string" }, function(p)
  if config.permissions[p.cmd] == nil then
    config.permissions[p.cmd] = {}
  end
  connectionManager.commands[p.cmd] = { p.func, p.desc, p.melon }
end)
AddCallout("AddHelpTopic", { "cmd", "func", "desc" }, { "string", "function", "string" }, function(p)
  if config.helpPermissions[p.cmd] == nil then
    config.helpPermissions[p.cmd] = {}
  end
  connectionManager.helpTopics[p.cmd] = { p.func, p.desc, p.melon }
end)
AddCallout("PM", { "to", "message" }, { "table", "string" }, function(p)
  connectionManager:PM(p.to, p.message)
end)
AddCallout("Quit", { "exitStatus" }, { "number" }, function(p)
  connectionManager:Distribute("Shutdown")
  table.save(config, "config.lua")
  os.exit(p.exitStatus)
end)
AddCallout("RemoveCommand", { "cmd" }, { "string" }, function(p)
  connectionManager.commands[p.cmd] = nil
end)
AddCallout("Say", { "conn", "channel", "message" }, { "number", "string", "string" }, function(p)
  connectionManager:Say(p.conn, p.channel, p.message)
end)
AddCallout("GetUpdates", {}, {}, function(p)
  return connectionManager.updates
end)

protocol = {
  user = ""
}
function protocol:Create()
  local newObject = {}
  setmetatable(newObject, { __index=self })
  newObject.channels = {}
  newObject.users = {}
  return newObject
end
function protocol:AddUser(newUser)
  table.insert(self.users, newUser)
  table.sort(self.users)
end

function GetCommand(str)
  return SplitParameters(str, 2)
end
function SplitParameters(str, stopAfter, splitChar)
  str = string.gsub(str , "\n", "")
  local parts = {}
  if stopAfter == nil then stopAfter = 20  end
  if splitChar == nil then splitChar = ' ' end
  for i=1,stopAfter do
    local from, to = string.find(str, splitChar)
    if i == stopAfter or from == nil then
      table.insert(parts, str)
      break
    end
    table.insert(parts, string.sub(str, 1, from-1))
    str = string.sub(str, to+1)
  end
  return unpack(parts)
end
function Include(filename, env)
  local chunk, err = loadfile(filename)
  if chunk then
    if env ~= nil then
      setfenv(chunk, env)
    end
    local success, err = pcall(chunk)
    if (not success) then
      connectionManager:PM('MelTraX', 'Failed to load: ' .. filename .. '  (' .. err .. ')')
      return nil
    end
    return env or err
  else
    connectionManager:PM('MelTraX', 'Failed to load: ' .. filename .. '  (' .. err .. ')')
    return nil
  end
end

function CheckPermission(permissionTable, command, from, melon)
  local user = permissionTable[command].users == nil or table.contains(permissionTable[command].users, from.user)
  for k,v in pairs(config.permissionGroups) do
    user = user or table.contains(permissionTable[command].users, k) and table.contains(v, from.user)
  end
  local channel = permissionTable[command].channels == nil or from.channel == nil
  channel = channel or table.contains(permissionTable[command].channels, from.channel)
  if melon ~= nil and permissionTable[command].channels == nil and permissionTable[command].users == nil then
    return user and channel and CheckPermission(config.permissions, connectionManager.melonInfos[melon].name, from)
  else
    return user and channel
  end
end



table.contains = function(tbl, value)
  for k,v in pairs(tbl) do
    if v == value then
      return k
    end
  end
end
table.removeByValue = function(tbl, value)
  for k,v in pairs(tbl) do
    if v == value then
      table.remove(tbl, k)
    end
  end
end

Include("system.lua")
Include("savetable.lua")
config = Include("config.lua")
connectionManager:Initialize()
while true do
  connectionManager:Update()
  socket.sleep(1)
end
