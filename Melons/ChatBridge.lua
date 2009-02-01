function melon:GetInfo()
  return {
    name    = "Chat Bridge",
    desc    = "Redirects chat messages from one server to the other.",
    author  = "MelTraX"
  }
end
function melon:Initialize()
  bot:AddCommand("bridgeadd", AddBridge, "adds a chat bridge - params: conn1 channel1 <-> conn2 channel2")
  bot:AddCommand("bridgelist", ListBridges, "lists all chat bridges")
  bot:AddCommand("bridgeremove", RemoveBridge, "removes a chat bridge - params: bridgeid from !bridgelist")
end
function melon:Said(channel, from, message)
  for _,v in ipairs(config) do
    if from.conn == v.fromConn and channel == v.fromChannel then
      print("Chat Bridge: " .. v.fromConn .. ":" .. v.fromChannel .. " -> " .. v.toConn .. ":" .. v.toChannel .. " -- <" .. from.user .. "> " ..message)
      if string.sub(message, 1, 4) == "/me " then
        bot:Say(v.toConn, v.toChannel, "/me - " .. from.user .. " " .. string.sub(message, 5))
      else
        bot:Say(v.toConn, v.toChannel, "<" .. from.user .. "> " .. message)
      end
    end
  end
end
function AddBridge(from, params)
  local fromConn, fromChannel, direction, toConn, toChannel = SplitParameters(params)
  table.insert(config, {
    fromConn    = tonumber(fromConn),
    fromChannel = fromChannel,
    toConn      = tonumber(toConn),
    toChannel   = toChannel
  })
  if direction == "<->" then
    table.insert(config, {
      fromConn=tonumber(toConn),
      fromChannel=toChannel,
      toConn=tonumber(fromConn),
      toChannel=fromChannel
    })
  end
end
function ListBridges(from, params)
  for i,v in ipairs(config) do
    bot:Reply(i .. " - " .. v.fromConn .. ":" .. v.fromChannel .. " -> " .. v.toConn .. ":" .. v.toChannel)
  end
end
function RemoveBridge(from, params)
  table.remove(config, params)
end
