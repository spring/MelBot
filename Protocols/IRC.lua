function protocol:GetInfo()
  return {
    name   = "IRC",
    desc   = "Can log into IRC servers.",
    author = "MelTraX"
  }
end

function protocol:Login()
  self.conn = socket.tcp()
  self.conn:settimeout(2)
  if self.conn:connect(self.config.host, self.config.port) then
    self:Send("NICK " .. self.config.user .. "\nUSER Miranda M1210 server :Jan Holthusen\n")
    self.loggedIn = self.connectionManager.updates
    self:Update(-1)
  else
    self.loggedIn = false
  end
  self.conn:settimeout(0)
end
function protocol:Join(channel)
  self:Send("JOIN #" .. channel .. "\n")
end
function protocol:Leave(channel)
  self:Send("PART #" .. channel .. "\n")
end
function protocol:Say(channel, message)
  if string.sub(message, 1, 4) == "/me " then
    local newMessage = string.char(1) .. "ACTION " .. string.sub(message, 5) .. string.char(1)
    self:Send("PRIVMSG #" .. channel .. " :" .. newMessage .. "\n")
  else
    self:Send("PRIVMSG #" .. channel .. " :" .. message .. "\n")
  end
  socket.sleep(1)
end
function protocol:PM(to, message)
  --self:Send("PRIVMSG #swp :" .. message .. "\n")
  --socket.sleep(1)
end
function protocol:Update(update)
  if update % 10 == 0 then
    self:Send("PING " .. self.config.host .. "\n")
  end
  if self.loggedIn and update == self.loggedIn + 10 then
    for _,v in ipairs(self.config.channels) do
      self:Join(v)
    end
  end
  while true do
    local input, err = self:Receive()
    if update % 30 == 0 and (err ~= nil and err ~= "timeout" or not self.loggedIn) then
      if self.config.debug ~= nil then
        print(self.connID .. " Error: " .. tostring(err) .. " - Connected: " .. tostring(self.loggedIn))
      end
      self:Shutdown()
      self.loggedIn = update
      self:Login()
      break
    end
    if input == nil then
      break
    else
      local host, cmd, params = SplitParameters(input, 3)
      if cmd == "PRIVMSG" then
        local sender = string.match(host, "^:([^!]+)")
        local recipient, msg = SplitParameters(params, 2)
        msg = string.sub(msg, 2)
        if string.sub(recipient, 1, 1) == "#" then
          local from = { conn=self.connID, user=sender}
          if string.sub(msg, 1, 8) == string.char(1) .. "ACTION " then
            connectionManager:Said(string.sub(recipient, 2), from, "/me " .. string.sub(msg, 9))
          else
            connectionManager:Said(string.sub(recipient, 2), from, msg)
          end
        else
          --connectionManager:GotPM({ conn=self.connID, user=sender}, msg)
        end
      elseif host == "PING" then
        self:Send("PONG " .. cmd)
      end
    end
  end
end
function protocol:Shutdown()
  self.conn:close()
end

function protocol:Send(msg)
  if self.config.debug ~= nil then
    print(self.connID .. " out: " .. msg)
  end
  self.conn:send(msg)
end
function protocol:Receive()
  returnValue = { self.conn:receive(msg) }
  if self.config.debug ~= nil then
    print(self.connID .. " in: " .. tostring(returnValue[1]))
  end
  return unpack(returnValue)
end
