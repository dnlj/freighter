local vs = {}
vs.year = "2017"
vs.version = "Community"
vs.toolVersion = "15.0"
vs.cmake32 = "Visual Studio 15 2017"
vs.cmake64 = "Visual Studio 15 2017 Win64"

-- TODO: Is there a better way to get these? (look into https://docs.microsoft.com/en-us/cpp/build/building-on-the-command-line#developer-command-files-and-locations)
-- TODO: https://docs.microsoft.com/en-us/visualstudio/msbuild/standard-and-custom-toolset-configurations
vs.msbuild = '"C:/Program Files (x86)/Microsoft Visual Studio/'.. vs.year ..'/'.. vs.version ..'/MSBuild/'.. vs.toolVersion ..'/Bin/msbuild.exe"'
vs.devenv = '"C:/Program Files (x86)/Microsoft Visual Studio/'.. vs.year ..'/'.. vs.version ..'/Common7/IDE/devenv.exe"'

return vs