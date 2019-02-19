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

local build_vs2017 = function(cfg)
	local configU
	local arch
	
	do -- Validate cfg
		-- Architecture
		if cfg.arch == "x86" then
			arch = "Win32"
		elseif cfg.arch == "x86_64" then
			arch = "x64"
		else
			f.error("Architecture ".. cfg.arch .." is not supported")
		end
		
		-- Config
		if cfg.config == "debug" or cfg.config == "release" then
			configU = cfg.config:sub(1,1):upper() .. cfg.config:sub(2)
		else
			f.error("Config ".. cfg.config .." is not supported")
		end
	end
	
	local dir = CRATE.dir .."/build_".. cfg.arch
	
	do -- Make project files
		local cmakeArgs = {
			"-G \"".. f.vs.cmake .."\"",
			"-DGLFW_BUILD_EXAMPLES=OFF",
			"-DGLFW_BUILD_TESTS=OFF",
			"-DGLFW_BUILD_DOCS=OFF",
			"-A ".. arch,
		}
		
		local oldwd = os.getcwd()
		os.mkdir(dir)
		os.chdir(dir)
		os.execute("cmake ".. table.concat(cmakeArgs, " ") .." ..")
		os.chdir(oldwd)
	end
	
	do -- Build
		local args = "/t:Build /verbosity:minimal /p:Configuration=".. configU
		local fileName = dir .."/GLFW.sln"
		os.execute(f.vs.msbuild .." ".. fileName .." ".. args)
	end
	
	do -- Organize
		f.moveFile(dir .."/src/".. configU, CRATE.dir .."/lib/".. cfg.config .."_".. cfg.arch, "glfw3.lib")
	end
end

CRATE.build = function(cfg)
	if not cfg.type then
		f.error("No build type specified")
	end
	
	local vs, year = string.match(cfg.type, "^(vs)(%d%d%d%d)$")
	
	if vs and year == "2017" then
		build_vs2017(cfg)
	else
		f.error("Build type \"".. cfg.type .."\" is not supported")
	end
end

return CRATE
