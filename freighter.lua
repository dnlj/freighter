-- TODO: premake5 freighter --download XYZ (allow short hand -d)
-- TODO: premake5 freighter --build XYZ (allow shorthand -b)
-- TODO: Make this a premake module?
-- TODO: Clean command so you can rebuild from fresh without redownload. If git will need to run commands (git clean -dfx)

freighter = {}

local p = premake
local f = freighter
local sizeof = function(tbl) local c = 0 for _ in pairs(tbl) do c = c + 1 end return c end

f._crates = {}
f._wdStates = {}
f.prefix = "[Freighter]"
f.basicConfigString = [[%{freighter.getBasicConfig(cfg.buildcfg)}]]
f._tempErrorPrefix = nil

f.setCratesDirectory = function(dir)
	f._cratesDir = path.normalize(path.getabsolute(dir))
end

f.use = function(crates)
	for _,cuid in pairs(crates) do
		f._loadCrate(cuid)
		
		local crate = f._crates[cuid]
		
		if crate.addFiles then
			files {crate.addFiles()}
		end
		
		if crate.addIncludeDirectories then
			includedirs {crate.addIncludeDirectories()}
		end
		
		if crate.addLibraries then
			links {crate.addLibraries()}
		end
		
		if crate.addLibraryDirectoires then
			libdirs {crate.addLibraryDirectoires()}
		end
	end
end

f.getBasicConfig = function(cfg)
	cfg = string.lower(cfg)
	
	if string.find(cfg, "debug") then
		return "debug"
	elseif string.find(cfg, "release") then
		return "release"
	end
	
	return "unknown"
end

f.error = function(err, level)
	level = level or 0
	error(
		"\n\t"
		.. f.prefix
		.. (f._tempErrorPrefix or "")
		.. (err:sub(1,1) == "[" and "" or " ")
		.. err
		, level + 2
	)
end

f.assert = function(cond, msg)
	if not cond then
		f.error(msg, 1)
	end
	return cond
end

f.log = function(...)
	io.write(
		f.prefix,
		f._tempErrorPrefix or "",
		select(1, ...):sub(1,1) == "[" and "" or " ",
		...)
	io.write("\n")
end

f.moveFile = function(fromFolder, toFolder, fileName)
	os.mkdir(toFolder)
	local succ, err = os.rename(fromFolder .."/".. fileName, toFolder .."/".. fileName)
	
	if not succ then
		f.error(err, 1)
	end
end

f.moveFiles = function(tbl)
	for k,v in pairs(tbl) do
		f.moveFile(table.unpack(v))
	end
end

f.httpDownload = function(url, file, opt)
	opt = opt or {}
	opt.progress = opt.progress or f._progress_bar
	return http.download(url, file, opt),
		io.write("\n") and nil or nil
end

f.execute = function(cmd, prefix)
	cmd = '"'.. cmd ..'"' -- TODO: not sure if this works on linux (see https://stackoverflow.com/questions/27333777/)
	local pipe = f.assert(io.popen(cmd .." 2>&1"), "Could not execute: ".. cmd)
	prefix = prefix and prefix .." " or ""
	
	while true do
		local data = pipe:read()
		if not data then break end
		f.log(prefix, data)
	end
end

f._verifyCratesDir = function()
	if f._cratesDir == nil then
		f.error("No crates directory specified.")
	end
end

f._loadCrate = function(cuid)
	if f._crates[cuid] then return end
	
	f._verifyCratesDir()
	
	local file = f._cratesDir .."/".. cuid .."/".. cuid ..".lua"
	
	if os.isfile(file) then
		f._crates[cuid] = dofile(file)
		f._crates[cuid].uid = cuid
		f._crates[cuid].dir = f._cratesDir .."/".. cuid .."/cache"
	else
		f.error("Unable to find crate: ".. cuid)
	end
end

-- TODO: Handle timeout
f._fetch = function(crate)
	if not crate.source then
		f.error("No source given for crate")
	end
	
	f.log("Fetching ", crate.name)
	
	local ext = string.sub(crate.source, -4)
	local alreadyExists = os.isdir(crate.dir)
	
	if ext == ".git" then
		if alreadyExists then
			f.log("Crate already in cache. Cleaning.")
			f.pushWorkingDir(crate.dir)
			f.execute("git clean -dfx", "[GIT]")
			f.popWorkingDir()
		else
			f.execute("git clone ".. crate.source .." ".. crate.dir, "[GIT]")
		end
	elseif ext == ".zip" then
		os.mkdir(crate.dir)
		local file = crate.dir .."/".. crate.uid ..".zip"
		
		if os.isfile(file) then
			for k,v in pairs(os.match(crate.dir .."/*")) do
				if v ~= file then
					if os.isfile(v) then
						os.remove(v)
					else
						os.rmdir(v)
					end
				end
			end
		else
			local status = f.httpDownload(crate.source, file)
			f.assert(status == "OK", "Unable to download: ".. crate.source)
		end
		
		zip.extract(file, crate.dir)
		for _, v in pairs(os.matchfiles(crate.dir .."/**")) do
			f.assert(os.chmod(v, 777))
		end
	else
		f.error("Unknown source type")
	end
end

f._build = function(crate, act, cfg)
	local cc = {}
	
	cc.type = act.trigger
	cc.arch = cfg.architecture
	cc.config = f.getBasicConfig(cfg.buildcfg)
	cc._act = act
	cc._cfg = cfg
	
	crate._configs = crate._configs or {}
	
	-- Skip duplicate configs
	for k,v in pairs(crate._configs) do
		if cc.type == v.type
			and cc.arch == v.arch
			and cc.config == v.config then
			return
		end
	end
	
	f.log("Building ", crate.name, " (", table.concat({cc.type, cc.arch, cc.config}, ", "), ")")
	table.insert(crate._configs, cc)
	
	if crate.build then
		crate.build(cc)
	end
end

f._progress_bar = function(total, current)
	local pre = "["
	local post = string.format("] %3d%%", math.floor((current / total) * 100))
	
	local w = 80 - #pre - #post
	local c = (current / total) * w
	local fill = string.rep("=", math.floor(c))
	local blank = string.rep(".", math.ceil(w - c))
	
	io.write("\r", pre, fill, blank, post)
end

f.pushWorkingDir = function(dir)
	f.assert(os.mkdir(dir))
	table.insert(f._wdStates, os.getcwd())
	os.chdir(dir)
end

f.popWorkingDir = function()
	local dir = table.remove(f._wdStates)
	
	if dir then
		os.chdir(dir)
	end
end


newaction {
	trigger = "freighter",
	description = "Downloads, builds, and use freighter crates.",
	
	onProject = function(prj)
		if sizeof(f._crates) == 0 then return end
		f._verifyCratesDir()
		
		-- Get the action to build for
		local act = p.action.get(_ARGS[1])
		f.assert(act, "Invalid action: ".. tostring(_ARGS[1]))
		
		-- Load Visual Studio settings if required
		do
			local vs, year = string.match(act.trigger, "^(vs)(%d%d%d%d)$")
			if vs == "vs" then
				f.assert(os.host() == "windows",
					"Unable to build Visual Studio projects on non-windows systems (action = ".. act.trigger ..")"
				)

				f._vsyear = year
				f.vs = require("freighter/vs")
				f._vsyear = nil
			end
		end
		
		-- Build all crates
		for uid, crate in pairs(f._crates) do
			f._tempErrorPrefix = "[".. uid .."]"
			f._fetch(crate)
			
			for cfg in p.project.eachconfig(prj) do
				f.assert(
					p.action.supportsconfig(act, cfg),
					"Invalid config for action: ".. tostring(act)
				)
				
				-- TODO: Allow some kind of mapping/settings for builds. Look into using p.api.register
				f.pushWorkingDir(crate.dir)
				f._build(crate, act, cfg)
				f.popWorkingDir()
			end
		end
		
		f._tempErrorPrefix = nil
	end,
}
