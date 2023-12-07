--[[

	FileSystem

]]


local args = {...}
local Internal = args[1]

if (Internal == nil or type(Internal) ~= "table") then
	error("Missing Internal object!")
end


-- Is OpenComputer?
local oc = Internal.Platform == "oc" and true or false

local ComputerCraftFS = Internal.Native.fs
local ExposeCompatibilityLayer = Internal.FileSystem.ExposeCompatibilityLayer

local HFS = {} -- .. the filesystem ..

local Drives = {} -- Managed drives
local Mounts = {} -- Mounts -> drives



-- Helpers
local function insertUniqueValue(tbl, value)
	for _, v in ipairs(tbl) do
		if v == value then
			return  -- Value already exists, no need to insert
		end
	end
	table.insert(tbl, value)  -- Insert the value if it doesn't already exist
end

local function isValidFileMode(mode)
	local validOptions = { "r", "w", "a", "rb", "wb", "ab" }
	for _, option in ipairs(validOptions) do
		if mode == option then
			return true
		end
	end
	return false
end

local function checkArg(n, have, ...)
	have = type(have)
	local function check(want, ...)
		if not want then
			return false
		else
			return have == want or check(...)
		end
	end
	if not check(...) then
		local msg = string.format("bad argument #%d (%s expected, got %s)", n, table.concat({...}, " or "), have)
		error(msg, 3)
	end
end


-- HFS being
HFS.Errors = {
	["FileExists"] = "File already exists",
	["FileNotFound"] = "File not found",

	["ReadOnly"] = "Drive is read-only",
	["NoAccess"] = "Permissions denied"
}



--[[
	Drives:
		["driveName"] = {
			Name = "driveName"
			OpenComputersComponent = .. filesystem component
			ComputerCraftPath = .. path/to/drive ("/" or "/rom/")

			Type = "fixed", "removable", "network", "virtual"
			ReadOnly = false,
		}
	
	Mounts:
		["/mount/path"] = {
			DriveName = "driveName",
			ReadOnly = false,
		}

]]


--[[

	Returns a table containing one entry for each Canonical segment of the given path. Examples:
		"foo/bar" -> {"foo","bar"}
		"foo/../bar" -> {"foo","bar"}

]]
HFS.Segments = function(path)
	local parts = {}
	for part in path:gmatch("[^\\/]+") do
		local current, up = part:find("^%.?%.$")
		if current then
			if up == 2 then
				table.remove(parts)
			end
		else
			table.insert(parts, part)
		end
	end
	return parts
end

-- Returns the Canonical form of the specified path, i.e. a path containing no "indirections" such as . or ...
HFS.Canonical = function(path)
	local isDir = false
	if (string.sub(path, -1) == "/") then
		isDir = true
	end

	local result = table.concat(HFS.Segments(path), "/")

	if (isDir) and (string.sub(result, -1) ~= "/") then
		result = result .. "/" -- add back the trailing "/"
	end

	if string.sub(path, 1, 1) == "/" then
		return "/" .. result
	else
		return result
	end
end
-- Concatenates two or more paths. Note that all paths other than the first are treated as relative paths, even if they begin with a slash.
HFS.Combine = function(...)
	local set = table.pack(...)
	for index, value in ipairs(set) do
		checkArg(index, value, "string")
	end
	return HFS.Canonical(table.concat(set, "/"))
end


--[[

	Get the drive object for a particular path and then the path on that drive

	For example, if you have a drive mounted at /myDrive/ and call this with the path "/myDrive/someFile", you'll get the drive object for "myDrive" and the path "/someFile"

]]
HFS.GetDrive = function(path)
	checkArg(1, path, "string")

	if (string.sub(path, 0, 1) ~= "/") then
		path = "/" .. path
	end

	local path = HFS.Canonical(path)

	local bestMount = ""
	for mountPath, mountData in pairs(Mounts) do
		if (string.sub(path, 0, #mountPath) == mountPath) and (Drives[mountData.DriveName] ~= nil) then
			-- there's the drive, bud
			if (#mountPath > #bestMount) then -- deeper
				bestMount = mountPath
			end
		end
	end

	if bestMount ~= "" then
		local drivePath = string.sub(path, #bestMount+1)
		local mountData = Mounts[bestMount]
		local drive = Drives[mountData.DriveName]
		return drive, drivePath, bestMount
	end
end



--[[

	Drive object

	{
		OpenComputersComponent = .. filesystem component
		ComputerCraftPath = .. path/to/drive ("/" or "/rom/")

		--Type = "fixed", "removable", "network", "virtual"
		ReadOnly = false,


		-- methods
	}
]]
local Drive = {} -- Drive object
Drive.__index = Drive

function Drive.New(driveComponent, makeReadOnly)
	if (driveComponent == nil) then
		error("driveComponent (#1) cannot be nil.")
	end

	local self = {}
	setmetatable(self, Drive)
	if oc then
		if (type(driveComponent) == "string") then
			driveComponent = HFS.GetOpenComputersDriveComponent(driveComponent)
		end

		if (type(driveComponent) ~= "table" or driveComponent.getLabel == nil) then
			error("driveComponent (#1) must be a filesystem component from a FloppyDisk or HardDrive.")
		end
		self.OpenComputersComponent = driveComponent

		if (driveComponent.isReadOnly()) then
			makeReadOnly = true
		end
	else
		if (type(driveComponent) ~= "string" or ComputerCraftFS.isDir(driveComponent) == false) then
			error("driveComponent (#1) must be a string pointing to the real path of the drive.")
		end
		self.ComputerCraftPath = driveComponent

		if (ComputerCraftFS.isReadOnly(driveComponent)) then
			makeReadOnly = true
		end
	end

	if (makeReadOnly == true) then
		self.ReadOnly = true;
	end

	return self
end

--[[
	Returns the name of the drive
]]
function Drive:GetLabel()
	return self.Name
end

--[[
	Placeholder for access control
]]
function Drive:CanAccess(path)
	return true
end

--[[
	Marks/unmarks the drive as read-only
	Returns if successful, false if the underlying filesystem disallows it (permanently read-only)
]]
function Drive:MarkReadOnly(enable)
	if enable == nil then enable = true end
	checkArg(1, enable, "boolean")
	if oc then
		if (self.OpenComputersComponent.isReadOnly() and not enable) then
			return false
		end
	else
		if (ComputerCraftFS.isReadOnly(driveComponent) and not enable) then
			return false
		end
	end
	self.ReadOnly = enable
	return true
end

-- these are the actual filesystem interactions

--[[
	List of files in a given directory on the drive. Sorted A-Z, a-z. Directories have a trailing "/".
]]
function Drive:List(path)
	local contents = {}
	if oc then
		contents = self.OpenComputersComponent.list(path)
		if (contents == nil) then
			return contents
		end
		contents.n = nil -- the count, but list should not return that
	else
		local path = HFS.Combine(self.ComputerCraftPath, path)
		contents = ComputerCraftFS.list(path)
		for i,name in ipairs(contents) do
			if (ComputerCraftFS.isDir(HFS.Combine(path, name)) and string.sub(name, -1) ~= "/") then
				contents[i] = name .. "/" -- add the trailing "/" to signify directory
			end
		end
	end
	
	local toRemove = {}
	for i,name in ipairs(contents) do
		if (not self:CanAccess(HFS.Combine(path, name))) then
			table.insert(toRemove, i)
		end
	end
	for i = #toRemove, 1, -1 do
		table.remove(contents, toRemove[i])
	end

	return contents
end

--[[
	Tests whether a file or directory exists
]]
function Drive:Exists(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end

	if oc then
		return self.OpenComputersComponent.exists(path)
	else
		local path = HFS.Combine(self.ComputerCraftPath, path)
		return ComputerCraftFS.exists(path)
	end
end
--[[
	Tests whether a path is a directory
]]
function Drive:IsDirectory(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end

	if oc then
		return self.OpenComputersComponent.isDirectory(path)
	else
		local path = HFS.Combine(self.ComputerCraftPath, path)
		return ComputerCraftFS.isDir(path)
	end
end
--[[
	Tests whether a path is a file
]]
function Drive:IsFile(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end

	if (not self:Exists(path)) then
		return false
	end

	return not self:IsDirectory(path)
end

--[[
	Tests whether a file or directory is read-only
]]
function Drive:IsReadOnly(path)
	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end

	if (self.ReadOnly == true) then
		return true
	end

	if oc then
		return self.OpenComputersComponent.isReadOnly()
	else
		if (path ~= nil) then
			path = HFS.Combine(self.ComputerCraftPath, path)
		else
			path = self.ComputerCraftPath
		end
		return ComputerCraftFS.isReadOnly(path)
	end
end

--[[
	Returns various file attributes (currently tracked by the underlying system)
		LastModified
		Created <-- not supported on OpenComputers
		IsReadOnly
		IsDirectory
		Size
		
		DriveName

	CompatibilityLayer:
		modified & modification
		created
		isReadOnly
		isDir
		size

		driveName
]]
function Drive:GetAttributes(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end

	local attributes = {}

	if not oc and type(ComputerCraftFS.attributes) == "function" then
		ccpath = HFS.Combine(self.ComputerCraftPath, path)
		local attr = ComputerCraftFS.attributes(path)
		attributes.LastModified = attr.modified
		if (attr.modified == nil) then
			attributes.LastModified = attr.modification
		end
		attributes.Created = attr.created
		attributes.IsReadOnly = attr.isReadOnly
		attributes.IsDirectory = attr.isDir
		attributes.Size = attr.size
	end
	
	if oc then
		attributes.LastModified = self.OpenComputersComponent.lastModified(path)
	end

	if (attributes.Size == nil) then
		attributes.Size = self:GetSize(path)
	end
	if (attributes.IsDirectory == nil) then
		attributes.IsDirectory = self:IsDirectory(path)
	end
	if (attributes.IsReadOnly == nil) then
		attributes.IsReadOnly = self:IsReadOnly(path)
	end

	attributes.DriveName = self:GetLabel()

	if (ExposeCompatibilityLayer) then
		attributes.modified = attributes.LastModified
		attributes.modification = attributes.LastModified
		attributes.created = attributes.Created
		attributes.isReadOnly = attributes.IsReadOnly
		attributes.isDir = attributes.IsDir
		attributes.size = attributes.Size
		attributes.driveName = attributes.DriveName
	end

	return attributes
end

--[[
	Returns the capacity of the drive
]]
function Drive:GetCapacity()
	if (not self:CanAccess("/")) then
		return false, HFS.Errors.NoAccess
	end

	if oc then
		return self.OpenComputersComponent.spaceTotal()
	else
		local path = self.ComputerCraftPath
		return ComputerCraftFS.getCapacity(path)
	end
end
--[[
	Returns the free space on the drive
]]
function Drive:GetFreeSpace()
	if (not self:CanAccess("/")) then
		return false, HFS.Errors.NoAccess
	end

	if oc then
		return self.OpenComputersComponent.spaceTotal() - self.OpenComputersComponent.spaceUsed()
	else
		local path = self.ComputerCraftPath
		return ComputerCraftFS.getFreeSpace(path)
	end
end
--[[
	Returns the amount of spaced used on the drive
]]
function Drive:GetUsedSpace()
	if (not self:CanAccess("/")) then
		return false, HFS.Errors.NoAccess
	end

	if oc then
		return self.OpenComputersComponent.spaceUsed()
	else
		local path = self.ComputerCraftPath
		return ComputerCraftFS.getCapacity(path) - ComputerCraftFS.getFreeSpace(path)
	end
end
--[[
	Returns the size of a file
]]
function Drive:GetSize(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end

	if oc then
		return self.OpenComputersComponent.size(path)
	else
		path = HFS.Combine(self.ComputerCraftPath, path)
		return ComputerCraftFS.getSize(path)
	end
end

--[[
	Returns the last time a file was modified.
]]
function Drive:LastModified(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end

	if oc then
		return self.OpenComputersComponent.lastModified(path)
	else
		if (type(ComputerCraftFS.attributes) ~= nil) then
			path = HFS.Combine(self.ComputerCraftPath, path)
			local attr = ComputerCraftFS.attributes(path)
			
			if (attr.modified ~= nil) then
				return attr.modified
			else
				return attr.modification
			end
		end
	end
end


-- Actually hitting it
--[[
	Creates a directory.
]]
function Drive:CreateDirectory(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end
	if (self:IsReadOnly(path)) then
		return false, HFS.Errors.ReadOnly
	end

	if (self:IsDirectory(path)) then
		return true
	end
	if oc then
		return self.OpenComputersComponent.makeDirectory(path)
	else
		local path = HFS.Combine(self.ComputerCraftPath, path)
		return ComputerCraftFS.makeDir(path)
	end
end
--[[
	Creates a file
]]
function Drive:CreateFile(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end
	if (self:IsReadOnly(path)) then
		return false, HFS.Errors.ReadOnly
	end

	if (self:IsFile(path)) then
		return true
	end
	self:WriteAllText(path, "")
end

--[[
	Deletes a directory
]]
function Drive:DeleteDirectory(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end
	if (self:IsReadOnly(path)) then
		return false, HFS.Errors.ReadOnly
	end

	if (self:IsDirectory(path)) then
		return self:Delete(path)
	else
		return false
	end
end
--[[
	Deletes a file
]]
function Drive:DeleteFile(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end
	if (self:IsReadOnly(path)) then
		return false, HFS.Errors.ReadOnly
	end

	if (self:IsFile(path)) then
		return self:Delete(path)
	else
		return false
	end
end
--[[
	Deletes a directory or file
]]
function Drive:Delete(path)
	checkArg(1, path, "string")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end
	if (self:IsReadOnly(path)) then
		return false, HFS.Errors.ReadOnly
	end

	if oc then
		return self.OpenComputersComponent.remove(path)
	else
		local path = HFS.Combine(self.ComputerCraftPath, path)
		return ComputerCraftFS.delete(path)
	end
end

-- bit harder (requires cross-drive support! best option is to open current -> read . open new -> write . delete current (if move))
--[[
	Copies a directory or file to a new destination.
	Destination can be on another drive, uses mounts to determine this.

	Will not overwrite an existing file unless overwrite specified.
]]
function Drive:Copy(path, destination, overwrite)
	checkArg(1, path, "string")
	checkArg(2, destination, "string")
	overwrite = overwrite ~= nil and overwrite or false
	checkArg(3, overwrite, "boolean")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end
	if (self:IsReadOnly(path)) then
		return false, HFS.Errors.ReadOnly
	end

	local destinationDrive, destinationDrivePath = HFS.GetDrive(destination)

	if (not destinationDrive:CanAccess(destinationDrivePath)) then
		return false, HFS.Errors.NoAccess
	end
	if (destinationDrive:IsReadOnly(destinationDrivePath)) then
		return false, HFS.Errors.ReadOnly
	end

	local fullySuccessful = true

	-- since destinationDrive could be us, could be someone else, just use the open and write for that drive (even if it may be us!)

	if (destinationDrive:Exists(destinationDrivePath)) then
		if (overwrite) then
			destinationDrive:Delete(destinationDrivePath)
		else
			return false, HFS.Errors.FileExists
		end
	end

	if not oc then
		local path = HFS.Combine(self.ComputerCraftPath, path)
		local destination = HFS.Combine(destinationDrive.ComputerCraftPath, destinationDrivePath)
		return ComputerCraftFS.copy(path, destination)
	end


	-- Check if the source is a directory
	if self:IsDirectory(path) then
		-- Create the destination directory if it doesn't exist
		if not destinationDrive:Exists(destinationDrivePath) then
			destinationDrive:CreateDirectory(destinationDrivePath)
		end

		-- Get the list of files and directories in the source directory
		local sourceContents = self:List(path)

		-- Recursively copy each file and subdirectory
		for _, entry in ipairs(sourceContents) do
			local sourceEntryPath = HFS.Combine(path, entry)
			local destinationEntryPath = HFS.Combine(destinationDrivePath, entry)
			local success = self:Copy(sourceEntryPath, destinationEntryPath, overwrite)
			if not success then
				fullySuccessful = false
			end
		end
	else
		-- Copy a file
		local contents = self:ReadAllBytes(path) or ""
		destinationDrive:WriteAllBytes(destinationDrivePath, contents)
	end

	return fullySuccessful
end
--[[
	Moves a directory or file to a new destination.
	Destination can be on another drive, uses mounts to determine this.

	Will not overwrite an existing file unless overwrite specified.
]]
function Drive:Move(path, destination, overwrite) -- cheeky :)
	checkArg(1, path, "string")
	checkArg(2, destination, "string")
	overwrite = overwrite ~= nil and overwrite or false
	checkArg(3, overwrite, "boolean")

	if (not self:CanAccess(path)) then
		return false, HFS.Errors.NoAccess
	end
	if (self:IsReadOnly(path)) then
		return false, HFS.Errors.ReadOnly
	end

	local destinationDrive, destinationDrivePath = HFS.GetDrive(destination)
	if (not destinationDrive:CanAccess(destinationDrivePath)) then
		return false, HFS.Errors.NoAccess
	end
	if (destinationDrive:IsReadOnly(destinationDrivePath)) then
		return false, HFS.Errors.ReadOnly
	end

	if not oc then
		local path = HFS.Combine(self.ComputerCraftPath, path)
		local destination = HFS.Combine(destinationDrive.ComputerCraftPath, destinationDrivePath)
		return ComputerCraftFS.move(path, destination)
	end

	self:Copy(path, destination, overwrite)
	return self:Delete(path)
end

-- hmmm
--[[
	Opens a new file handle using one of the following modes: r (read), w (write), a (append), rb (read bytes), wb (write bytes), and ab (append bytes)

	Handle is then returned to you with the following methods:
		.Read([count=1]): reads a number of bytes or characters from the file
		.ReadAll(): reads the remainder of the file
		.ReadLine([withTrailing=false]): reads up to a '\n' character, withTrailing indicates whether the "\n" is included

		.Write(text): writes a character, byte or string/string of bytes.
		.WriteLine(text): appends a "\n" character to the text, same behavior as above

		.Seek([whence="cur" [, offset=1] ]): moves the read head. Whence can be set (beginning of file), cur (current position) or end (end of file). Offset moves n spaces from whence.

		.Flush(): saves the file to disk without closing the handle. Has no affect on OpenComputers
		.Close(): closes the file handle

	CompatibilityLayer methods are the same names with lowerCaseCammel
]]
function Drive:Open(path, mode) -- this is different between the two, try to get the same behavior
	checkArg(1, path, "string")
	checkArg(2, mode, "string")
	-- modes: (r)ead, (w)rite, (a)ppend and br, bw, ba (same, but for binary mode)

	if (not isValidFileMode(mode)) then
		error("#2 expected valid mode (r,w,a,rb,wb,ab).")
	end

	if (not self:CanAccess(path)) then
		return nil, HFS.Errors.NoAccess
	end

	local writing = false
	if (mode ~= "r" and mode ~= "rb") then
		writing = true
	end

	if (self:IsReadOnly(path) and writing) then
		return nil, HFS.Errors.ReadOnly
	end

	local handle = {}

	local underlyingHandle = nil
	if oc then
		underlyingHandle = self.OpenComputersComponent.open(path, mode)
	else
		local path = HFS.Combine(self.ComputerCraftPath, path)
		underlyingHandle = ComputerCraftFS.open(path, mode)
		-- print("path: " .. path .. " || handle: " .. tostring(underlyingHandle))
	end

	local closed = false
	local function ocVerifyHandleOpen()
		if (underlyingHandle == nil) and (not closed) then
			underlyingHandle = self.OpenComputersComponent.open(path, mode)
		end
	end

	if (underlyingHandle == nil) then
		return underlyingHandle, HFS.Errors.FileNotFound
	end

	if (not writing) then
		function handle.Read(count)
			if (count == nil) then count = 1 end
			checkArg(1, count, "number")

			if (count < 1) then
				count = 1
			end

			if oc then
				ocVerifyHandleOpen()
				return self.OpenComputersComponent.read(underlyingHandle, count)
			else
				return underlyingHandle.read(count)
			end
		end

		function handle.ReadAll()
			if oc then
				ocVerifyHandleOpen()
				local lastRead = self.OpenComputersComponent.read(underlyingHandle, 1028)
				if (lastRead == nil) then
					return nil
				end

				local data = lastRead
				while (lastRead ~= nil) do
					lastRead = self.OpenComputersComponent.read(underlyingHandle, 512)
					if (lastRead ~= nil) then
						data = data .. lastRead
					else
						break
					end
				end
				return data
			else
				return underlyingHandle.readAll()
			end
		end

		function handle.ReadLine(withTrailing)
			if (withTrailing == nil) then withTrailing = false end
			checkArg(1, withTrailing, "boolean")
			if oc then
				ocVerifyHandleOpen()
				-- same as above, sorta
				local lastRead = self.OpenComputersComponent.read(underlyingHandle, 1028)
				if (lastRead == nil) then
					return nil
				end

				local data = lastRead
				while (lastRead ~= nil or lastRead == "\n") do
					lastRead = self.OpenComputersComponent.read(underlyingHandle, 512)
					if (lastRead ~= nil) then
						data = data .. lastRead
					else
						break
					end
				end
				return data
			else
				return underlyingHandle.readLine(withTrailing)
			end
		end
	else -- writing
		function handle.Write(text)
			if (text == nil) then text = "" end
			checkArg(1, text, "string", "number")
			if oc then
				ocVerifyHandleOpen()
				return self.OpenComputersComponent.write(underlyingHandle, text)
			else
				return underlyingHandle.write(text)
			end
		end
		function handle.WriteLine(text)
			if (text == nil) then
				return handle.write("\n")
			else
				checkArg(1, text, "string", "number")
				return handle.write(text .. "\n")
			end
		end
	end

	function handle.Seek(whence, offset)
		if (whence == nil) then whence = "cur" end
		checkArg(1, whence, "string")
		offset = offset ~= nil and offset or 1
		checkArg(2, offset, "string")

		if oc then
			ocVerifyHandleOpen()
			return self.OpenComputersComponent.seek(underlyingHandle, whence, offset)
		else
			return underlyingHandle.seek(whence, offset)
		end
	end


	function handle.Flush()
		if oc then
			-- to my understanding, this isn't a thing in OpenComputers ... but it does flush on close ...
			-- so as dumb as it sounds, close the handle, then reopen it... except the reopen is done elsewhere!
			-- local result = self.OpenComputersComponent.close(underlyingHandle)
			-- underlyingHandle = nil
			return true
		else
			return underlyingHandle.flush()
		end
	end

	function handle.Close()
		closed = true
		if oc then
			return self.OpenComputersComponent.close(underlyingHandle)
		else
			return underlyingHandle.close()
		end
	end

	if ExposeCompatibilityLayer then
		if (not writing) then
			function handle.read(count)
				return handle.Read(count)
			end
			function handle.readAll()
				return handle.ReadAll()
			end
			function handle.readLine()
				return handle.ReadLine()
			end
		else
			function handle.write(text)
				return handle.Write(text)
			end
			function handle.writeLine(text)
				return handle.WriteLine(text)
			end
		end
		function handle.seek(whence, offset)
			return handle.Seek(whence, offset)
		end
		function handle.flush()
			return handle.Flush()
		end
		function handle.close()
			return handle.Close()
		end
	end

	return handle
end


-- read/write then close
--[[
	Opens a file, appends bytes, then closes the file
]]
function Drive:AppendAllBytes(path, bytes)
	checkArg(1, path, "string")
	checkArg(2, bytes, "string", "table", "number")

	local contents = bytes
	if (type(bytes) == "table") then
		contents = table.concat(bytes, "")
	end

	local handle, err = self:Open(path, "ab")
	if handle == nil then return false, err end
	handle.write(contents)
	handle.close()
	return true
end
--[[
	Opens a file, appends text string, then closes the file
]]
function Drive:AppendAllText(path, text)
	checkArg(1, path, "string")
	checkArg(2, text, "table", "string")

	local contents = text
	if (type(text) == "table") then
		contents = table.concat(text, "")
	end

	local handle, error = self:Open(path, "a")
	if handle == nil then return false, err end
	handle.write(contents)
	handle.close()
	return true
end
--[[
	Opens a file, appends a table of lines, then closes the file
]]
function Drive:AppendAllLines(path, lines)
	checkArg(1, path, "string")
	checkArg(2, lines, "table", "string")

	local contents = ""
	if (type(lines) == "table") then
		contents = table.concat(lines, "\n")
	end

	return self:writeAllLines(path, contents)
end

--[[
	Opens a file, reads all bytes, then closes the file
]]
function Drive:ReadAllBytes(path)
	checkArg(1, path, "string")
	local handle, err = self:Open(path, "rb")
	if handle == nil then return nil, err end
	local contents = handle.readAll()
	handle.close()
	return contents
end
--[[
	Opens a file, reads all text, then closes the file
]]
function Drive:ReadAllText(path)
	checkArg(1, path, "string")
	local handle, err = self:Open(path, "r")
	if handle == nil then return nil, err end
	local contents = handle.readAll()
	handle.close()
	return contents
end
--[[
	Opens a file, reads all text, then closes the file.
	Returns the text as an array split on the "\n" character, which is consumed.
]]
function Drive:ReadAllLines(path)
	checkArg(1, path, "string")
	-- read all text, split on \n
	local contents, err = self:ReadAllText(path)
	if contents == nil then return false, err end
	local lines = {}
	for line in contents:gmatch("[^\n]*") do
      	table.insert(lines, line)
	end
	return lines
end

--[[
	Opens a file, writes bytes, then closes the file
]]
function Drive:WriteAllBytes(path, bytes)
	checkArg(1, path, "string")
	checkArg(2, bytes, "string", "table", "number")

	local contents = bytes
	if (type(bytes) == "table") then
		contents = table.concat(bytes, "")
	end

	local handle, err = self:Open(path, "wb")
	if not handle then return false, err end
	handle.write(contents)
	handle.close()
	return true
end
--[[
	Opens a file, writes text string, then closes the file
]]
function Drive:WriteAllText(path, text)
	checkArg(1, path, "string")
	checkArg(2, text, "table", "string")

	local contents = text
	if (type(text) == "table") then
		contents = table.concat(text, "")
	end

	local handle, err = self:Open(path, "w")
	if not handle then return false, err end
	handle.write(contents)
	handle.close()
	return true
end
--[[
	Opens a file, writes a table of lines, then closes the file
]]
function Drive:WriteAllLines(path, lines)
	checkArg(1, path, "string")
	checkArg(2, lines, "table", "string")

	local contents = ""
	if (type(lines) == "table") then
		contents = table.concat(lines, "\n")
	end

	return self:writeAllLines(path, contents)
end

HFS.Drive = Drive -- expose the Drive class directly.






--[[

	****************
	FileSystem calls
	****************
	
]]




-- Take something like the bootaddress -> filesystem
function HFS.GetOpenComputersDriveComponent(filter)
	if not oc then
		error("Unsupported platform (requires OpenComputers)")
	end

	checkArg(1, filter, "string")
	local address
	for component in Internal.Native.component.list("filesystem", true) do
		if Internal.Native.component.invoke(component, "getLabel") == filter then
			address = component
			break
		end
			if component:sub(1, filter:len()) == filter then
			address = component
			break
		end
	end
	
	if not address then
		return nil, "no such file system"
	end
	local component = Internal.Native.component.proxy(address)
	return component
end

--[[
	
	Creates a new Drive object and mounts it to path.

	Returns the new drive object
]]
function HFS.Mount(driveComponent, path, name, makeReadOnly)
	if oc then
		checkArg(1, driveComponent, "table", "string")
	else
		checkArg(1, driveComponent, "string")
	end
	checkArg(1, path, "string")

	path = HFS.Canonical(path) -- clean it up
	if (string.sub(path, -1) == "/") then
		path = string.sub(path, 0, #path-1) -- remove trailing /
	end
	if (string.sub(path, 0, 1) ~= "/") then
		path = "/" .. path -- add leading /
	end

	local existingMount = Mounts[path]
	if (existingMount ~= nil) then
		error("Cannot mount drive to " .. path .. ". " .. existingMount.DriveName .. " already exists there.")
	end

	local drive = Drive.New(driveComponent, makeReadOnly)
	if (name ~= nil and type(name) == "string") then
		drive.Name = name
	else
		if oc then
			drive.Name = driveComponent.getLabel() or path
		else
			drive.Name = path
		end
	end

	Mounts[path] = {
		["DriveName"] = drive.Name,
		["ReadOnly"] = drive.ReadOnly
	}

	Drives[drive.Name] = drive

	return drive
end




if Internal.debug then
	HFS.GetDrives = function()
		return Drives
	end
	HFS.GetMounts = function()
		return Mounts
	end
end


-- Drive wrappers (fs)

--[[
	Place holder, checks if the path hits a mount point (drive)
]]
HFS.CanAccess = function(path) -- Can we access this path?
	checkArg(1, path, "string")
	local drive, pathOnDrive, myMountPath = HFS.GetDrive(path)
	if (drive ~= nil) then
		return drive:CanAccess(path)
	else
		return false
	end
end

--[[
	Gets the leaf name of a path (file name)
]]
HFS.GetName = function(path)
	checkArg(1, path, "string")
	path = HFS.Canonical(path)
	local wasDir = false
	if (string.sub(path, -1) == "/") then
		wasDir = true
		path = string.sub(path, 0, -1) -- remove trailing /
	end
	local _, index = string.find(path,".*/")
	if index then
		return string.sub(path, index + 1)
	end
	return path
end
HFS.GetFileName = HFS.GetName
--[[
	Gets the directory to a file, or the parent directory of a directory.
]]
HFS.GetParent = function(path)
	local parent = string.match(path, "(.+)/[^/]+$")
	return parent ~= nil and parent .. "/" or "/"
end

--[[
	List of files in a given directory. Sorted A-Z, a-z. Directories have a trailing "/".
	Includes any additional mounts in the directory.
]]
HFS.List = function(path)
	local drive, pathOnDrive, myMountPath = HFS.GetDrive(path)
	local driveContents = drive:List(pathOnDrive)

	-- Add mount paths
	for mountPath, mountData in pairs(Mounts) do
		if (mountPath ~= myMountPath) and (string.sub(mountPath, 0, #path) == path) and (Drives[mountData.DriveName] ~= nil) then
			insertUniqueValue(driveContents, string.sub(mountPath, 2, #mountPath) .. "/")
		end
	end
	if (driveContents ~= nil) then
		table.sort(driveContents)
	end
	return driveContents
end

--[[
	Tests whether a file or directory exists
]]
HFS.Exists = function(path)
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:Exists(pathOnDrive)
end
--[[
	Tests whether a path is a directory
]]
HFS.IsDirectory = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:IsDirectory(pathOnDrive)
end
--[[
	Tests whether a path is a file
]]
HFS.IsFile = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:IsFile(pathOnDrive)
end
--[[
	Tests whether a file or directory is read-only
]]
HFS.IsReadOnly = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:IsReadOnly(pathOnDrive)
end
--[[
	Tests whether a path is the root of a drive (mount)
]]
HFS.IsDriveRoot = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	if (#pathOnDrive == 0) then
		return true
	end
end

--[[
	
	Returns various file attributes (currently tracked by the underlying system)
		LastModified
		Created <-- not supported on OpenComputers
		IsReadOnly
		IsDirectory
		Size
		
		DriveName

	CompatibilityLayer:
		modified & modification
		created
		isReadOnly
		isDir
		size

		driveName

]]
HFS.GetAttributes = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:GetAttributes(pathOnDrive)
end

--[[
	Returns the capacity of a drive
]]
HFS.GetCapacity = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:GetCapacity(pathOnDrive)
end
--[[
	Returns the amount of free space on a drive
]]
HFS.GetFreeSpace = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:GetFreeSpace(pathOnDrive)
end
--[[
	Returns the amount of space used on a drive
]]
HFS.GetUsedSpace = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:GetUsedSpace(pathOnDrive)
end
--[[
	Returns the size of a file
]]
HFS.GetSize = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:GetSize(pathOnDrive)
end

--[[
	Returns the last time a file was modified.
]]
HFS.LastModified = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:LastModified(pathOnDrive)
end

-- Actually hitting it
--[[
	Creates a directory.
]]
HFS.CreateDirectory = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:CreateDirectory(pathOnDrive)
end
--[[
	Creates a file
]]
HFS.CreateFile = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:CreateFile(pathOnDrive)
end
--[[
	Deletes a directory
]]
HFS.DeleteDirectory = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:DeleteDirectory(pathOnDrive)
end
--[[
	Deletes a file
]]
HFS.DeleteFile = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:DeleteFile(pathOnDrive)
end
--[[
	Deletes a directory or file
]]
HFS.Delete = function(path)
	checkArg(1, path, "string")
	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:Delete(pathOnDrive)
end
--[[
	Copies a directory or file to a new destination.
	Destination can be on another drive, uses mounts to determine this.

	Will not overwrite an existing file unless overwrite specified.
]]
HFS.Copy = function(path, destination, overwrite)
	checkArg(1, path, "string")
	checkArg(2, destination, "string")
	overwrite = overwrite ~= nil and overwrite or false
	checkArg(3, overwrite, "boolean")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:Copy(pathOnDrive, destination, overwrite)
end
--[[
	Moves a directory or file to a new destination.
	Destination can be on another drive, uses mounts to determine this.

	Will not overwrite an existing file unless overwrite specified.
]]
HFS.Move = function(path, destination, overwrite) -- cheeky :)
	checkArg(1, path, "string")
	checkArg(2, destination, "string")
	overwrite = overwrite ~= nil and overwrite or false
	checkArg(3, overwrite, "boolean")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:Move(pathOnDrive, destination, overwrite)
end


--[[
	Opens a new file handle using one of the following modes: r (read), w (write), a (append), rb (read bytes), wb (write bytes), and ab (append bytes)

	Handle is then returned to you with the following methods:
		.Read([count=1]): reads a number of bytes or characters from the file
		.ReadAll(): reads the remainder of the file
		.ReadLine([withTrailing=false]): reads up to a '\n' character, withTrailing indicates whether the "\n" is included

		.Write(text): writes a character, byte or string/string of bytes.
		.WriteLine(text): appends a "\n" character to the text, same behavior as above

		.Seek(whence[, offset=1]): moves the read head. Whence can be set (beginning of file), cur (current position) or end (end of file). Offset moves n spaces from whence.

		.Flush(): saves the file to disk without closing the handle. Has no affect on OpenComputers
		.Close(): closes the file handle

	CompatibilityLayer methods are the same names with lowerCaseCammel
]]
HFS.Open = function(path, mode) -- this is different between the two, try to get the same behavior
	checkArg(1, path, "string")
	checkArg(2, mode, "string")
	if (not isValidFileMode(mode)) then
		error("#2 expected valid mode (r,w,a,rb,wb,ab).")
	end

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:Open(pathOnDrive, mode) -- this is different between the two, try to get the same behavior
end


-- read/write then close
--[[
	Opens a file, appends bytes, then closes the file
]]
HFS.AppendAllBytes = function(path, bytes)
	checkArg(1, path, "string")
	checkArg(2, bytes, "string", "table")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:AppendAllBytes(pathOnDrive, bytes)
end
--[[
	Opens a file, appends text string, then closes the file
]]
HFS.AppendAllText = function(path, text)
	checkArg(1, path, "string")
	checkArg(2, text, "table", "string", "number")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:AppendAllText(pathOnDrive, text)
end
--[[
	Opens a file, appends a table of lines, then closes the file
]]
HFS.AppendAllLines = function(path, lines)
	checkArg(1, path, "string")
	checkArg(2, lines, "table", "string")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:AppendAllLines(pathOnDrive, lines)
end

--[[
	Opens a file, reads all bytes, then closes the file
]]
HFS.ReadAllBytes = function(path)
	checkArg(1, path, "string")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:ReadAllBytes(pathOnDrive)
end
--[[
	Opens a file, reads all text, then closes the file
]]
HFS.ReadAllText = function(path)
	checkArg(1, path, "string")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:ReadAllText(pathOnDrive)
end
--[[
	Opens a file, reads all text, then closes the file.
	Returns the text as an array split on the "\n" character, which is consumed.
]]
HFS.ReadAllLines = function(path)
	checkArg(1, path, "string")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:ReadAllLines(pathOnDrive)
end

--[[
	Opens a file, writes bytes, then closes the file
]]
HFS.WriteAllBytes = function(path, bytes)
	checkArg(1, path, "string")
	checkArg(2, bytes, "string", "table", "number")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:WriteAllBytes(pathOnDrive, bytes)
end
--[[
	Opens a file, writes text string, then closes the file
]]
HFS.WriteAllText = function(path, text)
	checkArg(1, path, "string")
	checkArg(2, text, "table", "string")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:WriteAllText(pathOnDrive, text)
end
--[[
	Opens a file, writes a table of lines, then closes the file
]]
HFS.WriteAllLines = function(path, lines)
	checkArg(1, path, "string")
	checkArg(2, lines, "table", "string")

	local drive, pathOnDrive = HFS.GetDrive(path)
	return drive:WriteAllLines(pathOnDrive, lines)
end





-- Compatibility (remove later)

if (ExposeCompatibilityLayer) then
	HFS.combine = function(basePath, ...)
		return HFS.Combine(basePath, ...)
	end
	HFS.getName = function(path)
		return HFS.GetName(path)
	end
	HFS.getDir = function(path)
		return HFS.GetParent(path)
	end
	HFS.getDrive = function(path)
		checkArg(1, path, "string")
		local drive, pathOnDrive = HFS.GetDrive(path)
		return drive.GetLabel()
	end

	HFS.list = function(path)
		return HFS.List(path)
	end
	HFS.exists = function(path)
		return HFS.Exists(path)
	end
	HFS.isDir = function(path)
		return HFS.IsDirectory(path)
	end
	HFS.isDriveRoot = function(path)
		return HFS.IsDriveRoot(path)
	end
	HFS.isReadOnly = function(path)
		return HFS.IsReadOnly(path)
	end

	HFS.getSize = function(path)
		return HFS.GetSize(path)
	end
	HFS.getFreeSpace = function(path)
		return HFS.GetFreeSpace(path)
	end
	HFS.getCapacity = function(path)
		return HFS.GetCapacity(path)
	end

	HFS.attributes = function(path)
		return HFS.GetAttributes(path)
	end

	HFS.makeDir = function(path)
		return HFS.CreateDirectory(path)
	end
	HFS.move = function(fromPath, toPath)
		return HFS.Move(fromPath, toPath, false)
	end
	HFS.copy = function(fromPath, toPath)
		return HFS.Copy(fromPath, toPath, false)
	end
	HFS.delete = function(path)
		return HFS.Delete(path)
	end

	HFS.open = function(path, mode)
		return HFS.Open(path, mode)
	end


	-- ComputerCraft only (for now)
	HFS.find = function(...)
		if (oc) then
			error("Unsupported platform (requires ComputerCraft)") -- can do this later
		else
			return ComputerCraftFS.find(...)
		end
	end
	HFS.complete = function(...)
		if (oc) then
			error("Unsupported platform (requires ComputerCraft)")
		else
			return ComputerCraftFS.complete(...)
		end
	end
end

return HFS