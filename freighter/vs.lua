local vs = {}
local f = freighter
local whereArgs = "-prerelease -sort -nologo -utf8 -format json"

local downloadVSWhere = function()
	if not os.isfile("vswhere.exe") then
		local res, status = http.get("https://api.github.com/repos/Microsoft/vswhere/releases/latest")
		
		f.assert(status == "OK", "Unable to find download location for vswhere.exe\n".. status)
		
		local assets = json.decode(res).assets
		local url
		
		for k,v in pairs(assets) do
			if v.name == "vswhere.exe" then
				url = v.browser_download_url
			end
		end
		
		f.assert(url, "Unable to find download location for vswhere.exe")
		
		f.log("Downloading vswhere.exe")
		local status = f.httpDownload(url, "vswhere.exe")
		
		f.assert(status == "OK", "Unable to download vswhere.exe\n".. status)
	end
end

local getVSWhereInfo = function()
	local res, err = os.outputof("\"".. vs.where .."\" ".. whereArgs)
	f.assert(err == 0, "Could not find Visual Studio vswhere.exe")

	local info = json.decode(res)
	f.assert(#info ~= 0, "No Visual Studio installation found")
	
	return info
end

local setVSInfo = function()
	local info = getVSWhereInfo()
	
	local idx
	for k,v in pairs(info) do
		f.assert(v.catalog and v.catalog.productLineVersion, "Unable to determine Visual Studio year")
		if v.catalog.productLineVersion == f._vsyear then
			idx = k
		end
	end
	
	local ver = info[idx]
	
	do -- version
		f.assert(ver.installationVersion, "Unable to determine Visual Studio version")
		vs.version = ver.installationVersion
		
		vs.major = string.match(vs.version, "^(%d+).")
		f.assert(ver.installationVersion, "Unable to determine Visual Studio major version")
	end
	
	do -- year
		if ver.catalog and ver.catalog.productLineVersion then
			vs.year = ver.catalog.productLineVersion
		else
			f.error("Could not determine Visual Studio year")
		end
	end
	
	do -- devenv
		if ver.productPath then
			vs.devenv = ver.productPath
		else
			f.error("Could not find Visual Studio devenv.exe")
		end
	end
	
	do -- MSBuild
		local res, err = os.outputof("\"".. vs.where .."\" -find MSBuild/".. vs.major .."*/Bin/MSBuild.exe ".. whereArgs)
		f.assert(err == 0, "Could not find Visual Studio MSBuild.exe")
		
		local info = json.decode(res)
		f.assert(#info ~= 0, "Could not find Visual Studio MSBuild.exe")
		f.assert(#info == 1, "Could not determine Visual Studio MSBuild.exe")
		
		vs.msbuild = info[1]
	end
	
	do -- Cmake generator
		vs.cmake = "Visual Studio ".. vs.major .." ".. vs.year
	end
end

downloadVSWhere()
vs.where = os.getcwd() .."/vswhere.exe"
setVSInfo()

return vs
