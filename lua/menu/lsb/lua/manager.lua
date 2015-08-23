local err = function(err)
	lsb.util.print("Failed to check for updates!")
	lsb.util.print(string.format("Error: %s", err))
end

-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- decoding
local dec = function(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

lsb.util.print("Checking for updates...")

http.Fetch("https://api.github.com/repos/glua/luaserverbrowser/commits?sha=master", function(body)
	local commits = util.JSONToTable(body)
	local head = commits[1]

	if not(head) then
		lsb.util.print("Unable to check for updates - try again later!")
		return
	end

	if(file.Read("lsb/VERSION.dat") == head.sha) then
		lsb.util.print("You're up to date!")
		return
	end

	http.Fetch(string.format("%s?recursive=1", head.commit.tree.url), function(body)
		local tree = util.JSONToTable(body)

		local num = 0

		for k, v in pairs(tree.tree) do
			if(v.type == "blob") then
				num = num + 1
			end
		end

		http.Fetch("https://api.github.com/rate_limit", function(body)
			if(util.JSONToTable(body).resources.core.remaining < num) then
				lsb.util.print("Unable to check for updates - try again later!")
				return
			end

			lsb.util.print("Update found!")

			local errored = false
			local files = {}

			for k, v in ipairs(tree.tree) do
				if(v.type == "tree") then
					files[string.format("lsb/%s", v.path)] = false
				else
					local filename = string.format("%s.dat", v.path) --v.path:gsub("%....?.?$", ".dat")

					http.Fetch(v.url, function(body)
						local tab = util.JSONToTable(body)

						if not(tab.content) then
							if not(errored) then
								lsb.util.print("Failed to download update")
							end

							errored = true
							return
						end

						if not(tab.encoding == "base64") then
							err(string.format("Unknown encoding '%s'", tab.encoding))

							if not(errored) then
								lsb.util.print("Failed to download update")
							end

							errored = true
						end

						files[string.format("lsb/%s", filename)] = dec(tab.content)

						print(filename, table.Count(files), #tree.tree)

						if(table.Count(files) == #tree.tree) then
							lsb.util.print("Update downloaded")

							for k, v in pairs(files) do
								if not(v) then
									file.CreateDir(k)
								else
									file.Write(k, v)
								end
							end

							lsb.util.print("Update installed!")
						end
					end, err)
				end
			end

			file.Write("lsb/VERSION.dat", head.sha)
		end, err)
	end, err)
end, err)