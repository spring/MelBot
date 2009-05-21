function melon:GetInfo()
  return {
    name    = "Developer Tools",
    desc    = "Provides help subcommands for callins and callouts and !doline, !load.",
    author  = "MelTraX",
    handler = true
  }
end
function melon:Initialize()
  bot:AddHelpTopic("callouts", CalloutsHelp, "lists all callouts")
  bot:AddHelpTopic("callins", CallinsHelp, "lists all callins")
  bot:AddHelpTopic("from/to", FromHelp, "devs please read - explains from and to values of callins and callouts")
  bot:AddCommand("doline", DoLine, "executes Lua code")
  bot:AddCommand("echo", Echo, "executes Lua code and PMs the return value")
  bot:AddCommand("load", Load, "downloads the given melon via http and reloads all melons")
  bot:AddCommand("reload", Reload, "reloads all melons")
  bot:AddCommand("delete", Delete, "deletes the given melon and reloads all melons")
end
function CalloutsHelp(from, params)
  bot:Reply("Callouts:")
  for i,v in pairs(connectionManager.calloutInfos) do
    bot:Reply("- " .. i .. "(" .. table.concat(v.params, ", ") .. ")")
  end
end
function CallinsHelp(from, params)
  bot:Reply("Callins:")
  bot:Reply("- Initialize()")
  bot:Reply("- Update(updates)")
  bot:Reply("- Said(channel, from, message)")
  bot:Reply("- GotPM(from, message)")
  bot:Reply("- Shutdown()")
end
function FromHelp(from, params)
  bot:Reply("Please note that the from and to parameters in the callins and callouts are no string")
  bot:Reply("values anymore. They are a table with host, bot and user because.")
end
function DoLine(from, params)
  if from.conn == 1 and (from.user == "MelTraX" or from.user == "[LCC]quantum") then
    local func = loadstring(params)
    local env = { from=from, params=params }
    setmetatable(env, { __index=melon })
    setfenv(func, env)
    if func == nil then
      bot:Reply("That's not a valid statement.")
    else
      func()
    end
  else
    bot:Reply("Sorry, you don't have permission to execute !doline.")
  end
end
function Echo(from, params)
  if from.conn == 1 and (from.user == "MelTraX" or from.user == "[LCC]quantum") then
    local func = loadstring("return " .. params)
    local env = { from=from, params=params }
    setmetatable(env, { __index=melon })
    setfenv(func, env)
    if func == nil then
      bot:Reply("That's not a valid statement.")
    else
      local returnValue = func()
      bot:Reply(tostring(returnValue))
      if type(returnValue) == 'table' then
        for i,v in pairs(returnValue) do
          bot:Reply('  '..tostring(i)..' = '..tostring(v))
        end
      end
    end
  else
    bot:Reply("Sorry, you don't have permission to execute !doline.")
  end
end
function Reload(from, params)
  for _,melon in ipairs(connectionManager.melons) do
    connectionManager:SecureCall(melon, "Shutdown")
  end
  connectionManager.melons = {}
  connectionManager.melonInfos = {}
  connectionManager.commands = {}
  connectionManager.commandInfos = {}
  connectionManager.helpTopics = {}
  connectionManager:GetMelons()
end
function Load(from, params)
  if from.conn == 1 and (from.user == "MelTraX" or from.user == "[LCC]quantum") then
    if string.sub(params, -4) ~= ".lua" then
      bot:Reply("That doesn't seem to be a Lua file.")
    else
      local content = http.request(params)
      if content == nil then
        bot:Reply("Error while downloading. Check if the link works and try again.")
      else
        local rev = string.reverse(params)
        local pos = string.find(rev, "/")
        local basename = string.reverse(string.sub(rev, 1, pos-1))
        local file = io.open("Melons/" .. basename, "w")
        file:write(content)
        file:flush()
        file:close()
        Reload(from, params)
      end
    end
  else
    bot:Reply("Sorry, you don't have permission to execute !load.")
  end
end
function Delete(from, params)
  if from.conn == 1 and (from.user == "MelTraX" or from.user == "[LCC]quantum") then
    for _,v in ipairs(connectionManager.melons) do
      local mI = connectionManager.melonInfos[v]
      if mI.name == params and mI.author == from.user then
        os.remove("Melons/" .. mI.filename)
        Reload(from, params)
        return
      end
    end
  end
end
