function melon:GetInfo()
  return {
    name    = "Basic Commands",
    desc    = "Provides basic bot commands and help topics.",
    author  = "MelTraX",
    handler = true  -- raw access to connectionManager  
  }
end
function melon:Initialize()
  bot:AddHelpTopic("commands", CommandsHelp, "lists all commands (grouped by melon) - optional param: melonname")
end
function CommandsHelp(from, params)
  bot:Reply("Melons and Commands:")
  for _,v in ipairs(connectionManager.melons) do
    local info = connectionManager.melonInfos[v]
    bot:Reply("* " .. info.name .. " (" .. info.desc .. ") by " .. info.author)
    if params == nil or params == info.name then
      for i,w in pairs(connectionManager.commands) do
        if w[3] == v and CheckPermission(config.permissions, i, from, w[3]) then
          bot:Reply("  - !" .. i .. " (" .. w[2] .. ")")
        end
      end
    end
  end
end
