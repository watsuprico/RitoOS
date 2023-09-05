# Internal (table)

`BootConfig`: table
	.Platform: current hardware platform (0 -> ComputerCraft, 1 -> OpenComputers)
	.LuaVersion: running Lua version
	.LoadFile: function to load files from the boot filesystem

`Platform`: either "cc" or "oc"
`Language`: current language code
`Version`: {Major, Minor, Build} info
`BootLoaderVersion`: but for the boot.lua file

`DeveloperMode`: debug true?

`FileSystem`: FileSystem API

`GetDriver(name: string)`: returns a driver given a name
`DriverStore`: table of drivers


`CodeX`: CodeX internal storage
	`Hashes`:
		`["userId"]`:
			`IHP`: intermediate hash pass
			`salt`: user salt


`Sessions`: asd
	`["System"]`:
		`Processes`:
			`["pId"]`:
				`Name`: process name
				`ViewPorts`: graphics objects process outputs to
					`Main`: Main ViewPort
				`Key`: KeyManager key
				`Threads`: coroutine / threads (table of "pointers" that point to a coroutine in Scheduler.Threads)
				`Path`: Path to the parent folder of the executable
				`Executable`: Name of the program executable
				`IsAppPackage`: RitoOS application package

`SecureMachineKey`: OS key, used for encryption of OS items primarily
`RuntimeKey`: KeyManager key for the OS

`SysEvents`: EventEmitter - abstraction layer for hardware messages, if the computer (CC or OC) emits a message we then dump said message into this event emitter. It is up to the drivers to then react on the message and fire the appropriate event in the System EventEmitter (`System.EventEmitter`)

`SysThreads`: table, coroutine stack for system coroutines (such as CodeX and drivers).