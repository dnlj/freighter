local vs = {}
local f = freighter
local whereArgs = "-prerelease -latest"

local downloadVSWhere = function()
	if not os.isfile("vswhere.exe") then
		local res, status = http.get("https://api.github.com/repos/Microsoft/vswhere/releases/latest")
		
		if status ~= "OK" then
			f.error("Unable to find download location for vswhere.exe\n".. status)
		end
		
		local assets = json.decode(res).assets
		local url
		
		for k,v in pairs(assets) do
			if v.name == "vswhere.exe" then
				url = v.browser_download_url
			end
		end
		
		if not url then
			f.error("Unable to find download location for vswhere.exe")
		end
		
		f.log("Downloading vswhere.exe")
		local status = f.httpDownload(url, "vswhere.exe")
		
		if status ~= "OK" then
			f.error("Unable to download vswhere.exe\n".. status)
		end
	end
end

local getVSWhereInfo = function()
	-- TODO: add way to pick version
	local res, err = os.outputof("\"".. vs.where .."\" -nologo -utf8 -format json ".. whereArgs)

	if err ~= 0 then
		f.error("Could not find Visual Studio vswhere.exe")
	end

	local info = json.decode(res)
	
	if #info == 0 then
		f.error("No Visual Studio installation found")
	end
	
	return info
end

local setVSInfo = function()
	local info = getVSWhereInfo()
	
	local max = 1
	for k,v in pairs(info) do
		if not v.installationVersion then
			f.error("Unable to determine Visual Studio version")
		end
		
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

		if err ~= 0 then
			f.error("Could not find Visual Studio MSBuild.exe")
		end
		
		vs.msbuild = res
	end
end

downloadVSWhere()
vs.where = os.getcwd() .."/vswhere.exe"
setVSInfo()
