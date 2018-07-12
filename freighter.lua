-- TODO: premake5 freighter --download XYZ (allow short hand -d)
-- TODO: premake5 freighter --build XYZ (allow shorthand -b)
-- TODO: Make this a premake module?
-- TODO: Clean command so you can rebuild from fresh without redownload. If git will need to run commands (git clean -dfx)

freighter = {}

local p = premake
local f = freighter
local sizeof = function(tbl) local c = 0 for _ in pairs(tbl) do c = c + 1 end return c end

f._crates = {}
f.basicConfigString = [[%{freighter.getBasicConfig(cfg.buildcfg)}]]

f.vs = {}
f.vs["2017"] = require("freighter/vs2017")

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
	error("\n\t[Freighter] ".. err, level + 2)
end

f.log = function(...)
	io.write("[Freighter] ", ...)
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
			
			local oldwd = os.getcwd()
			os.chdir(crate.dir)
			os.execute("git clean -dffx")
			os.chdir(oldwd)
		else
			os.execute("git clone ".. crate.source .." ".. crate.dir)
		end
	elseif ext == ".zip" then
		f.error("TODO: Zip not currently supported.")
	else
		f.error("Unknown source type")
	end
end

f._build = function(crate, cfg)
	local cc = {}
	
	cc.type = _ARGS[1]
	cc.arch = cfg.architecture
	cc.config = f.getBasicConfig(cfg.buildcfg)
	
	if not cc.type then
		f.error("No build type specified")
	end
	
	f.log("Building ", crate.name, " (", table.concat({cc.type, cc.arch, cc.config}, ", "), ")")
	
	crate._configs = crate._configs or {}
	
	-- Skip duplicate configs
	for k,v in pairs(crate._configs) do
		if cc.type == v.type
			and cc.arch == v.arch
			and cc.config == v.config then
			return
		end
	end
	
	table.insert(crate._configs, cc)
	
	if crate.build then
		crate.build(cc)
	end
end

newaction {
	trigger = "freighter",
	description = "Downloads, builds, and use freighter crates.",
	
	onProject = function(prj)
		if sizeof(f._crates) == 0 then return end
		f._verifyCratesDir()
		
		for uid, crate in pairs(f._crates) do
			f.log("=== ", crate.name, " ===")
			f._fetch(crate)
			
			for cfg in p.project.eachconfig(prj) do
				-- TODO: Allow some kind of mapping/settings for builds. Look into using p.api.register
				f._build(crate, cfg)
			end
		end
	end,
}
