-- =====================================================================
-- JCJenson Hub -- main loader owo
-- =====================================================================

local SCRIPTS = {
	[142823291] = {
		name = "Murder Mystery 2",
		url = "https://raw.githubusercontent.com/DeadSignalFound/JcJensonHub/refs/heads/main/scripts/mm2.luau",
	},
	[70845479499574] = {
		name = "Bite By Night",
		url = "https://raw.githubusercontent.com/DeadSignalFound/JcJensonHub/refs/heads/main/scripts/BBN.luau",
	},
}

local entry = SCRIPTS[game.PlaceId]
if not entry then
	local supported = {}
	for placeId, info in pairs(SCRIPTS) do
		supported[#supported + 1] = string.format("%s (%d)", info.name, placeId)
	end
	warn(
		string.format(
			"[JCJensonHub] PlaceId %s is not supported.\nSupported: %s",
			tostring(game.PlaceId),
			table.concat(supported, ", ")
		)
	)
	return
end


local function envLookup(name)
	local ok, value = pcall(function()
		return (_G :: any)[name]
	end)
	if ok then
		return value
	end
	return nil
end

local function resolveExecutorRequest()
	local synTbl = envLookup("syn")
	if typeof(synTbl) == "table" and typeof(synTbl.request) == "function" then
		return synTbl.request
	end
	local httpRequest = envLookup("http_request")
	if typeof(httpRequest) == "function" then
		return httpRequest
	end
	local httpTbl = envLookup("http")
	if typeof(httpTbl) == "table" and typeof(httpTbl.request) == "function" then
		return httpTbl.request
	end
	local request = envLookup("request")
	if typeof(request) == "function" then
		return request
	end
	return nil
end

local function httpGetText(url)
	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end

	local httpRequest = resolveExecutorRequest()
	if httpRequest then
		local reqOk, response = pcall(httpRequest, { Url = url, Method = "GET" })
		if
			reqOk
			and typeof(response) == "table"
			and tonumber(response.StatusCode) == 200
			and typeof(response.Body) == "string"
			and response.Body ~= ""
		then
			return response.Body
		end
	end

	return nil
end

print(string.format("[JCJensonHub] Loading %s...", entry.name))

local source = httpGetText(entry.url)
if type(source) ~= "string" or source == "" then
	warn(
		string.format(
			"[JCJensonHub] Failed to fetch %s script. Check network/executor HTTP and re-execute.",
			entry.name
		)
	)
	return
end

local loader = loadstring or envLookup("load")
if typeof(loader) ~= "function" then
	warn("[JCJensonHub] Executor exposes neither loadstring nor load; cannot run scripts.")
	return
end

local chunk, compileErr = loader(source, "@JCJensonHub/" .. entry.name)
if typeof(chunk) ~= "function" then
	warn(string.format("[JCJensonHub] Failed to compile %s: %s", entry.name, tostring(compileErr)))
	return
end

local execOk, execErr = pcall(chunk)
if not execOk then
	warn(string.format("[JCJensonHub] %s errored during load: %s", entry.name, tostring(execErr)))
end
