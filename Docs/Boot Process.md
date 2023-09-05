init.lua (or startup)
SecureBoot.lua (verify Boot.lua)
Boot.lua (secure since we've verified the hash, does the actual booting)
|
HFS.lua (file system)
|
System.lua
|
| *recovery mode* ---> Recovery.boot
|
Load TaskMan API
|
|
CodeX (userspace)

# Booting RitoOS
The first step is the bootstraper, `startup.lua` (on ComputerCraft) or `init.lua` (on OpenComputers).

These two files are responsible for launching the `SecureBoot.lua` file and providing a error screen if any part of the boot process fails.\
Since on ComputerCraft, if `startup.lua` ends without shutting down the system (no more code to execute), ComputerCraft runs the CC shell, which we do not want!\
OpenComputers does not have this issue, per-say, as the system should shutdown when there's no more code to execute. Regardless, we still call the native shutdown function.

The bootstraper is also responsible for clearing the screen and drawing the OS text.


## SecureBoot.lua
Secure boot is used to validate the upcoming boot process, sorta like a slim version of Danvik.\
**This is not actually implemented! Only the idea!**


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
1) Crypto.api (used in hashing and signature checks...)
2) Boot.lua (boot file)
3) HFS.lua (filesystem)
5) Recovery.lua (recovery file)
6) FileHashes.secboot (sig check, hash storage file for above)

Files Boot.lua / the System will validate:
1) SecureBoot.lua
2) Vault data
3) Any other critical code

APIs (such as from /System/APIs/) can be configure to be scanned and validated each time they're loaded.
-> Regardless of that setting, they will always be scanned when loading into the System space.


## Boot.lua
This does the actual booting, setting up the filesystem, abstraction layer, drivers, scheduler, etc and calls the CodeX.Initiate() function to bring the user to the login screen.


We try to avoid the which comes first, chicken or egg problem, but ehh it can still be wobbly.\
For example, once access control (Holtin) is implemented, a dummy "yes to everything" version will need to loaded, then the filesystem, and then the real version can replace the dummy version. This way the function as exposed, allowing the FileSystem to take advantage of them, but means we can then use the FileSystem to load the access control list. blah

### Order:
1) Copy native functions to `Internal.Native` (they are then deleted from `_G` restricting them to the OS. _Unloading is disabled in debug mode_).
2) Setup the Holtin dummy functions
3) Load the FileSystem (_now we're cooking_), mount drives (the boot drive on OpenComputers, "/" (and "/rom" if in debug mode) on ComputerCraft)
4) Load "Option" file, apply boot configuration
5) Setup device drivers
6) Setup abstraction layer (common APIs such as `term`, `print` etc)
7) Draw boot screen (a little late, but ..)
8) Load RIT (System API)
9) --
10) Setup ViewPorts (similar to ComputerCraft's `window` api)
11) Redraw boot screen (although almost done with the boot)
12) Load CodeX and enter main OS message loop