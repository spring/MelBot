function protocol:GetInfo()
  return {
    name   = "Spring",
    desc   = "Can log into TASServer (the Spring Lobby).",
    author = "MelTraX"
  }
end

function protocol:Initialize()
  self.connected = false
  self.linesPerSecond = 10
end
function protocol:Login()
  self.conn = socket.tcp()
  self.conn:settimeout(1)
  self.connected = self.conn:connect(self.config.host, self.config.port)
  if self.connected then
    self:Send("LOGIN " .. self.config.user .. " " .. self.config.password .. " 0 * MelTraX LuaBot\n")
    for _,v in ipairs(self.config.channels) do
      self:Join(v)
    end
  end
  self.conn:settimeout(0)
end
function protocol:Join(channel)
  self:Send("JOIN " .. channel .. "\n")
end
function protocol:Leave(channel)
  self:Send("LEAVE " .. channel .. "\n")
end
function protocol:Say(channel, message)
  if string.sub(message, 1, 4) == "/me " then
    self:Send("SAYEX " .. channel .. " " .. string.sub(message, 5) .. "\n")
  else
    self:Send("SAY " .. channel .. " " .. message .. "\n")
  end
end
function protocol:PM(to, message)
  self:Send("SAYPRIVATE " .. to .. " " .. message .. "\n")
end
function protocol:Update(update)
  if not self.conn then
    self:Login()
  end

  if update % 10 == 0 then
    self:Send("PING\n")
  end
  while true do
    local input, err = self:Receive()
    if update % 30 == 0 and (err ~= nil and err ~= "timeout" or not self.connected) then
      if self.config.debug ~= nil then
        print(self.connID .. " Error: " .. tostring(err) .. " - Connected: " .. tostring(self.connected))
      end
      self:Shutdown()
      self:Login()
      break
    end
    if input == nil then
      break
    else
      local cmd, params = GetCommand(input)
      if cmd == "SAIDPRIVATE" then
        local user, msg = SplitParameters(params, 2)
        connectionManager:GotPM({ conn=self.connID, user=user }, msg)
      elseif cmd == "SAID" then
        local channel, user, msg = SplitParameters(params, 3)
        connectionManager:Said(channel, { conn=self.connID, user=user }, msg)
      elseif cmd == "SAIDEX" then
        local channel, user, msg = SplitParameters(params, 3)
        connectionManager:Said(channel, { conn=self.connID, user=user }, "/me " .. msg)
      elseif cmd == "ADDUSER" then
        self:AddUser(SplitParameters(params))
      elseif cmd == "SERVERMSG" and string.sub(params,1,18) == "You've been kicked" then
        print(self.connID .. " Notice: " .. params)
        connectionManager:RemoveConnection(self.connID)
        return
      elseif cmd == "DENIED" then
        print(self.connID .. " Notice: We've been denied to login. (" .. params .. ")")
        if params:match("logged in") then
          self:Shutdown()
          return
        else
          print(self.connID .. " Unknown reason: Shutting down.")
          connectionManager:RemoveConnection(self.connID)
          return
        end
      end
    end
  end
end
function protocol:Shutdown()
  self.connected = false
  self.conn:close()
  self.conn = nil
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
