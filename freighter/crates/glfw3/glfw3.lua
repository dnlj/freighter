local CRATE = {}
local f = freighter

CRATE.name = "Graphics Library Framework (GLFW)"
CRATE.source = "https://github.com/glfw/glfw.git"

CRATE.addIncludeDirectories = function()
	return CRATE.dir .."/include"
end

CRATE.addLibraryDirectoires = function()
	return CRATE.dir .."/lib/".. freighter.basicConfigString .."_%{cfg.architecture}"
end

CRATE.addLibraries = function()
	return "glfw3"
end

local build_vs = function(cfg, archMap, cmakeArgs)
	local arch = archMap["vs"][cfg.arch]
	f.assert(arch, "Architecture ".. cfg.arch .." is not supported")
	table.insert(cmakeArgs, "-G \"".. f.vs.cmake .."\"")
	table.insert(cmakeArgs, "-A ".. arch)
	
	-- Make project files
	f.execute("cmake ".. table.concat(cmakeArgs, " ") .." ..", "[CMAKE]")
	
	local config
	local args = {
		"-maxcpucount",
		"/t:Build",
		"/verbosity:minimal",
		"/p:OutDir=\"".. CRATE.dir .."/lib/".. cfg.config .."_".. cfg.arch .."/\"",
	}
	
	if cfg.config == "debug" or cfg.config == "release" then
		config = cfg.config:sub(1,1):upper() .. cfg.config:sub(2)
		table.insert(args, "/p:Configuration=".. config)
	else
		f.error("Config ".. cfg.config .." is not supported")
	end
	
	-- Build
	f.execute('"'.. f.vs.msbuild ..'" GLFW.sln '.. table.concat(args, " "), "[MSBUILD]")
end

local build_gmake = function(cfg, archMap, cmakeArgs)
	local arch = archMap["gmake"][cfg.arch]
	f.assert(arch, "Architecture ".. cfg.arch .." is not supported")

	table.insert(cmakeArgs, "-G \"Unix Makefiles\"")
	table.insert(cmakeArgs, "-DCMAKE_CXX_FLAGS=\"-m".. arch .."\"")
	table.insert(cmakeArgs, "-DCMAKE_C_FLAGS=\"-m".. arch .."\"")

	-- Make project files
	f.execute("cmake ".. table.concat(cmakeArgs, " ") .." ..", "[CMAKE]")

	-- Build
	f.execute("make", "[MAKE]")

	-- Organize
	f.moveFile("src", CRATE.dir .."/lib/".. cfg.config .."_".. cfg.arch, "libglfw3.a")
end

CRATE.build = function(cfg)
	local vs, year = string.match(cfg.type, "^(vs)(%d%d%d%d)$")
	
	local cmakeArgs = {
		"-DGLFW_BUILD_EXAMPLES=OFF",
		"-DGLFW_BUILD_TESTS=OFF",
		"-DGLFW_BUILD_DOCS=OFF",
	}
	
	local archMap = {
		["vs"] = {
			["x86"] = "Win32",
			["x86_64"] = "x64",
		},
		["gmake"] = {
			["x86"] = "32",
			["x86_64"] = "64",
		},
	}
	
	local dir = CRATE.dir .."/build_".. cfg.config .."_".. cfg.arch
	f.pushWorkingDir(dir)
	
	if vs then
		build_vs(cfg, archMap, cmakeArgs)
	elseif cfg.type == "gmake" then
		build_gmake(cfg, archMap, cmakeArgs)
	else
		f.error("Action ".. cfg.type .." not supported")
	end
	
	f.popWorkingDir()
end

return CRATE
