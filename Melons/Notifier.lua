function melon:GetInfo()
  return {
    name    = "Notifier",
    desc    = "Opens a socket for lobby notifications (ie SVN commits).",
    author  = "MelTraX"
  }
end
function melon:Update()
  if self.server == nil then
    self.server = assert(socket.bind("*", 8200))
    self.server:settimeout(0)
    print("Notifier: connection is not established.. trying to reconnect..")
    return
  end
  if self.client == nil then
    self.client = self.server:accept()
  end
  if self.client ~= nil then
    self.client:settimeout(0)
    while true do
      local line, err = self.client:receive()
      if err ~= nil and err ~= "timeout" then
        self.client:close()
        self.client = nil
        break
      end
      if line == nil then
        break
      end

      local channels, message = SplitParameters(line, 2)
      local channels = { SplitParameters(channels, nil, ',') }

      print("Notifier: " .. message)
      for _,channel in ipairs(channels) do
        local conn, channel = SplitParameters(channel, 2, ':')
        bot:Say(tonumber(conn), channel, message)
      end
    end
  end
end
function melon:Shutdown()
  if self.client ~= nil then
    self.client:close()
  end
  if self.server ~= nil then
    self.server:close()
  end
end
