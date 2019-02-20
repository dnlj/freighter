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

CRATE.build = function(cfg)
	-- TODO: split into generate and build phases for simplification
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
		}
	}
	
	local dir = CRATE.dir .."/build_".. cfg.config .."_".. cfg.arch
	f.pushWorkingDir(dir)
	
	if vs then
		local arch = archMap["vs"][cfg.arch]
		f.assert(arch, "Architecture ".. cfg.arch .." is not supported")
		table.insert(cmakeArgs, "-G \"".. f.vs.cmake .."\"")
		table.insert(cmakeArgs, "-A ".. arch)
	end
	
	-- Make project files
	f.execute("cmake ".. table.concat(cmakeArgs, " ") .." ..", "[CMAKE]")
	
	if vs then
		local config
		local args = {
			"-maxcpucount",
			"/t:Build",
			"/verbosity:minimal",
			-- TODO: why does output path not work?
			"/p:OutputPath=\"".. CRATE.dir .."/lib/".. cfg.config .."_".. cfg.arch .."\"",
		}
		
		if cfg.config == "debug" or cfg.config == "release" then
			config = cfg.config:sub(1,1):upper() .. cfg.config:sub(2)
			config = cfg.config
			table.insert(args, "/p:Configuration=".. config)
		else
			f.error("Config ".. cfg.config .." is not supported")
		end
		
		-- Build
		-- TODO: temp
		f.execute('"'.. f.vs.msbuild ..'" GLFW.sln '.. table.concat(args, " "), "[MSBUILD]")
		
		-- Organize
		--f.moveFile("src/".. config, CRATE.dir .."/lib/".. cfg.config .."_".. cfg.arch, "glfw3.lib")
	end
	
	f.popWorkingDir()
end

return CRATE
