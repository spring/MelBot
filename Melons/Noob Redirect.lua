function melon:GetInfo()
  return {
    name   = "Noob Redirect",
    desc   = "Gives the right command for often mistyped ones.",
    author = "MelTraX"
  }
end
function melon:Initialize()
  bot:AddCommand("time", Ingame, "-> /ingame")
  bot:AddCommand("ingame", Ingame, "-> /ingame")
  bot:AddCommand("ping", Ping, "-> /ping")
  bot:AddCommand("channels", Channels, "-> /channels")
end
function Ingame(from, params)
  bot:Reply("If you're searching for the command that shows you the time you played Spring, it's /ingame.")
end
function Ping(from, params)
  bot:Reply("If you're searching for the command that shows you the ping to the lobby server, it's /ping.")
end
function Channels(from, params)
  bot:Reply("If you're searching for the list of all lobby channels, try /channels.")
end
