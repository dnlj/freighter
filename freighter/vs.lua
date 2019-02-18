local vs = {}
local f = freighter
local whereArgs = "-prerelease -latest"

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
	-- TODO: add way to pick version
	local res, err = os.outputof("\"".. vs.where .."\" -nologo -utf8 -format json ".. whereArgs)
	
	f.assert(err == 0, "Could not find Visual Studio vswhere.exe")

	local info = json.decode(res)
	
	f.assert(#info ~= 0, "No Visual Studio installation found")
	
	return info
end

local setVSInfo = function()
	local info = getVSWhereInfo()
	
	local max = 1
	for k,v in pairs(info) do
		f.assert(v.installationVersion, "Unable to determine Visual Studio version")
		
		if v.installationVersion > info[max].installationVersion then
			max = k
		end
	end
	local ver = info[max]
	
	do -- version
		vs.installationVersion = ver.installationVersion
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
		local res, err = os.outputof("\"".. vs.where .."\" -nologo -utf8 -find MSBuild/**/Bin/MSBuild.exe ".. whereArgs)
		f.assert(err == 0, "Could not find Visual Studio MSBuild.exe")
		vs.msbuild = res
	end
end

downloadVSWhere()
vs.where = os.getcwd() .."/vswhere.exe"
setVSInfo()
