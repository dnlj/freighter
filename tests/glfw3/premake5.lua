require("../../freighter")


freighter.setCratesDirectory("../../freighter/crates")

-------------------------------------------------------------------------------
-- Main premake settings
--------------------------------------------------------------------------------
workspace("TestWorkspace")
	configurations {"Debug", "Debug2", "Release"}
	platforms {"x86_64", "x86"}
	characterset "Unicode"
	kind "ConsoleApp"
	language "C++"
	cppdialect "C++latest"
	systemversion "latest"
	rtti "Off"
	warnings "Default"
	flags {
		"FatalWarnings",
		"MultiProcessorCompile",
	}
	targetdir "./bin/%{cfg.buildcfg}_%{cfg.architecture}"
	objdir "./obj/%{prj.name}/%{cfg.buildcfg}_%{cfg.architecture}"
	startproject "TestProject"
	
	filter "action:vs*"
		buildoptions{
			"/wd4996", -- Disable some warnings about things Visual Studio has taken apon itself to deem "deprecated"
		}
	
	filter "platforms:x86_64"
        architecture "x86_64"
		
	filter "platforms:x86"
        architecture "x86"
		
	filter "configurations:Debug"
		symbols "On"
		defines {"DEBUG"}
	
	filter "configurations:Release"
		optimize "Full"
		defines {"RELEASE"}
		
		
--------------------------------------------------------------------------------
-- Projects
--------------------------------------------------------------------------------
project("TestProject")
	freighter.use {
		"glfw3"
	}
	
	files {
		"*.cpp"
	}
