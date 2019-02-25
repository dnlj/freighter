local CRATE = {}
local f = freighter

CRATE.name = "Simple OpenGL Image Library"
CRATE.source = "http://www.lonesock.net/files/soil.zip"

CRATE.addIncludeDirectories = function()
	return CRATE.dir .."/include"
end

CRATE.addLibraryDirectoires = function()
	return CRATE.dir .."/lib/".. freighter.basicConfigString .."_%{cfg.architecture}"
end

CRATE.addLibraries = function()
	return "soil"
end

local build_vs = function(cfg, archMap)
	local arch = archMap["vs"][cfg.arch]
	local config
	local args = {
		"-maxcpucount",
		"/t:Build",
		"/verbosity:minimal",
		"/p:WindowsTargetPlatformVersion=".. f.vs.sdkVersion,
		"/p:OutDir=\"".. CRATE.dir .."/lib/".. cfg.config .."_".. cfg.arch .."/\"",
	}
	
	if cfg.config == "debug" or cfg.config == "release" then
		config = cfg.config:sub(1,1):upper() .. cfg.config:sub(2)
		table.insert(args, "/p:Configuration=".. config)
	else
		f.error("Config ".. cfg.config .." is not supported")
	end
	
	-- Build
	f.execute('"'.. f.vs.devenv ..'" SOIL.sln /upgrade', "[DEVENV]")
	
	-- TODO: suppress build warnings
	f.execute('"'.. f.vs.msbuild ..'" SOIL.sln '.. table.concat(args, " "), "[MSBUILD]")
end

CRATE.build = function(cfg)
	os.rmdir("lib")
	local vs, year = string.match(cfg.type, "^(vs)(%d%d%d%d)$")
	
	local archMap = {
		["vs"] = {
			["x86"] = "Win32",
			["x86_64"] = "x64",
		}
	}
	
	local dir = "Simple OpenGL Image Library/projects/VC9"
	f.pushWorkingDir(dir)
	
	if vs then
		build_vs(cfg, archMap)
	else
		f.error("Action ".. cfg.type .." not supported")
	end
	
	f.popWorkingDir()
	
	--[[local vs, year = string.match(cfg.type, "^(vs)(%d%d%d%d)$")
	
	local cmakeArgs = {
		"-DGLFW_BUILD_EXAMPLES=OFF",
		"-DGLFW_BUILD_TESTS=OFF",
		"-DGLFW_BUILD_DOCS=OFF",
	}
	
	local archMap = {
		["vs"] = {
			["x86"] = "Win32",
			["x86_64"] = "x64",
		}
	}
	
	local dir = CRATE.dir .."/build_".. cfg.config .."_".. cfg.arch
	f.pushWorkingDir(dir)
	
	if vs then
		build_vs(cfg, archMap, cmakeArgs)
	else
		f.error("Action ".. cfg.type .." not supported")
	end
	
	f.popWorkingDir()--]]
end

return CRATE
