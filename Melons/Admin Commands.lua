function melon:GetInfo()
  return {
    name    = "Admin Commands",
    desc    = "Provides bot and permission management (ie !restart, !quit).",
    author  = "MelTraX",
    handler = true  -- raw access to connectionManager  
  }
end
function melon:Initialize()
  bot:AddCommand("join", Join, "joins a channel")
  bot:AddCommand("leave", Leave, "leaves a channel")
  bot:AddCommand("connect", Connect, "connects to a new server - params: protocol host port user password channels")
  bot:AddCommand("disconnect", Disconnect, "disconnects from a server - params: connectionID from !listconnections")
  bot:AddCommand("reconnect", Reconnect, "reconnects to a server - params: connectionID from !listconnections")
  bot:AddCommand("listconnections", ListConnections, "lists all connections of the bot")
  bot:AddCommand("permission", Permission, "changes permissions - params: 'add|remove' 'user|channel|inchannel' command user|group|channel")
  bot:AddCommand("group", Group, "changes permission groups - params: 'add|remove' group user")
  bot:AddCommand("listpermissions", ListPermissions, "lists permissions for all commands")
  bot:AddCommand("listgroups", ListGroups, "lists all groups")
  bot:AddCommand("restart", Restart, "restarts the bot")
  bot:AddCommand("quit", Quit, "quits the bot")
end
function Join(from, params)
  table.insert(config.connections[from.conn].channels, params)
  connectionManager.connections[from.conn]:Join(params)
end
function Leave(from, params)
  for i,v in ipairs(config.connections[from.conn].channels) do
    if v == params then
      table.remove(config.connections[from.conn].channels, i)
    end
  end
  connectionManager.connections[from.conn]:Leave(params)
end
function Connect(from, params)
  local p = {}
  p.protocol, p.host, p.port, p.user, p.password, channels = SplitParameters(params, 6)
  p.channels = { SplitParameters(channels) }
  table.insert(config.connections, p)
  connectionManager:AddConnection(#config.connections, p)
end
function Disconnect(from, params)
  connectionManager:RemoveConnection(tonumber(params))
  local conn = connectionManager.connections[tonumber(params)]
  conn:Shutdown()
  table.remove(config.connections, tonumber(params))
end
function Reconnect(from, params)
  local conn = connectionManager.connections[tonumber(params)]
  conn:Shutdown()
  conn:Login()
end
function ListConnections(from, params)
  for i,v in ipairs(connectionManager.connections) do
    local cI = v.config
    bot:Reply(i .. " - Protocol: " .. cI.protocol .. ", Host: " .. cI.host .. ", User: " .. cI.user .. ", Channels: " .. table.concat(cI.channels, ", "))
  end
end
function ListPermissions(from, params)
  bot:Reply("Command Permissions:")
  for k,v in pairs(config.permissions) do
    if type(v.users) == "table" then
      bot:Reply("- " .. k .. " (users): " .. table.concat(v.users, ", "))
    end
    if type(v.channels) == "table" then
      bot:Reply("- " .. k .. " (channels): " .. table.concat(v.channels, ", "))
    end
    if type(v.inchannels) == "table" then
      bot:Reply("- " .. k .. " (reply in channel): " .. table.concat(v.inchannels, ", "))
    end
  end
  bot:Reply("Help Permissions:")
  for k,v in pairs(config.helpPermissions) do
    if type(v.users) == "table" then
      bot:Reply("- " .. k .. " (users): " .. table.concat(v.users, ", "))
    end
    if type(v.channels) == "table" then
      bot:Reply("- " .. k .. " (channels): " .. table.concat(v.channels, ", "))
    end
  end
end
function ListGroups(from, params)
  bot:Reply("Groups:")
  for k,v in pairs(config.permissionGroups) do
    bot:Reply("- " .. k .. ": " .. table.concat(v, ", "))
  end
end
function Permission(from, params)
  local action, permType, cmd, usersOrChannels = SplitParameters(params, 4)
  cmd = string.gsub(cmd, "_", " ")
  uOtTable = { SplitParameters(usersOrChannels) }
  if action == "add" then
    for _,v in ipairs(uOtTable) do
      if config.permissions[cmd][permType .. "s"] == nil then
        config.permissions[cmd][permType .. "s"] = {}
      end
      table.insert(config.permissions[cmd][permType .. "s"], v)
    end
  elseif action == "remove" then
    for _,v in ipairs(uOtTable) do
      table.removeByValue(config.permissions[cmd][permType .. "s"], v)
    end
    if #config.permissions[cmd][permType .. "s"] == 0 then
      config.permissions[cmd][permType .. "s"] = nil
    end
  end
end
function Group(from, params)
  local action, group, users = SplitParameters(params, 3)
  usersTable = { SplitParameters(users) }
  if action == "add" then
    for _,v in ipairs(usersTable) do
      if config.permissionGroups[group] == nil then
        config.permissionGroups[group] = {}
      end
      table.insert(config.permissionGroups[group], v)
    end
  elseif action == "remove" then
    for _,v in ipairs(usersTable) do
      table.removeByValue(config.permissionGroups[group], v)
    end
    if #config.permissionGroups[group] == 0 then
      config.permissionGroups[group] = nil
    end
  end
end
function Restart(from, params)
  bot:Quit(0)
end
function Quit(from, params)
  if from.conn == 1 and (from.user == "MelTraX" or from.user == "[LCC]quantum") then
    bot:Quit(1)
  end
end
