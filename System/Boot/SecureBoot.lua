--[[

	[ SecureBoot ]

	Secure boot is used to validate the upcoming boot process, sorta like a slim version of Danvik.


	The idea is SecureBoot validates the signature of critical components.
	The way this is done is by validating a file's hash to a known good hash, then validate the signature on the known good hashes file.

		So, SecureBoot read the entire 'Boot.lua' file and creates a hash of the file's contents.
		This hash is then compared against the hash for that file stored in FileHashes.secboot.
		_We know the hash is valid because we validated the 'Boot.lua' signature before and store it with a list of hashes. This prevents us from having to validate signatures (which takes time)._
		After checking the hashes for all files, we then validate the 'FileHashes.secboot' file's signature.
		This is where the issues could arise, someone could modify the FileHashes.secboot file then update the signature file.
			To combat this, we use a pin entered by the user to encrypt/decrypt the signature file. This makes it so the file cannot be modified without knowing the user's key.

		After everything is validated, we run the bootloader 'Boot.lua'.
		'Boot.lua' then validates OUR signature. This is to help verify that SecureBoot itself hasn't been modified.

		Afterwards we can boot up :)


		Files SecureBoot validates:
			Crypto.api (used in hashing and signature checks...)
			Boot.lua
			System.lua
			HFS.lua
			Recovery.lua
			FileHashes.secboot

		Files Boot.lua / the System will validate:
			SecureBoot.lua
			TaskMan.lua
			any APIs
			Vault data
			..etc.. 

		APIs (such as from /System/APIs/) can be configure to be scanned and validated each time they're loaded.
		-> Regardless of that setting, they will always be scanned when loading into the System space.
]]

local args = {...}
local BootConfig = args[1]

if (BootConfig == nil or type(BootConfig) ~= "table") then
	error("Missing BootConfig!")
end


if (BootConfig.Platform == 0) then
	BootConfig.LoadFile("/System/Boot/Boot.lua")(BootConfig);
else
	local bootFunction, err = BootConfig.LoadFile("/System/Boot/Boot.lua");
	if not bootFunction then
		if err ~= nil then
			error(err)
		else
			error("Unknown error loading bootloader!")
		end
	else
		bootFunction(BootConfig)
	end
end
