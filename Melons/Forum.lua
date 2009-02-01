function melon:GetInfo()
  return {
    name   = "Forum Search",
    desc   = "Searches the official Spring message board.",
    author = "MelTraX"
  }
end
function melon:Initialize()
  bot:AddCommand("forum", Search, "returns a link to Spring forum search results")
end
function Search(from, params)
  bot:Reply("http://spring.clan-sy.com/phpbb/search.php?keywords="..url_escape(params))
end
function url_escape (str)
  --[[ copied from http://www.redwiki.net/wiki/wiki/LUA/URLencode%B1%B8%C7%F6%C4%DA%B5%E5 (2008-09-30) ]]
  str = string.gsub (str, "\n", "\r\n")
  str = string.gsub (str, "([^%w ])",
  function (c) return string.format ("%%%02X", string.byte(c)) end)
  str = string.gsub (str, " ", "+")
  return str
end
