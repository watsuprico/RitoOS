# System API
Main API


note: add file system encryption using either the user's IHP OR the machine key
the machine key is to be encrypted using a encryption key, that encryption key is then encrypted by each user's IHP meaning the decryption key can be used by any user but cannot be found on the disk! + no disk decryption key!
additionally, when a new user is added we can use the current user's IHP to decrypt the encryption key then encrypt that using the new user's IHP!




## Events
Various events used throughout other System APIs


`session_logout`: emitted by the session manager when a logout request is issued (logging out of this session)
	_A table is provided as the only event argument and this includes the `Reason` and `GranceDuration`._

`system_shutdown`: emitted by the System API when `System.Shutdown(...)` or `System.Restart(...)` is called.
	_A table is provided as the only event argument and this includes the `Reason`, `GranceDuration` and `WillRestart` (if the shutdown is actually a restart)._







## Generics
`System.Version: string` - RIT version
`System.Errors: table (string)` - Error code lookup


`System.EventEmitter`\
Since all APIs are loaded into the `System` table, which includes `EventEmitter`, there will be a generic, global event emitter which is what `System.EventEmitter` is.\
In general, this is not recommended to listen to this global EventEmitter- pushing events to this is generally fine, but this should be regarded as system messages and critical information.\
Instead, you should use the `System.Session.EventEmitter` API instead, which is localized to the user's session, thus events are only for that user.

System events fired in `System.EventEmitter` will eventually be passed to the session's EventEmitter (given the session is currently active) by the Scheduler. The global EventEmitter here is subject to change, as having an easily accessible global EventEmitter like this can be bad (key logging another user, for example).


`System.CheckArgument(argumentPosition: (number | string), have: any, acceptedType: string[, ...: string(s)]): nil`\
Checks whether the value `have` matches on or more acceptable types (specified by `acceptedType` and `...`). Throws error if `have` is not one of the accepted types.\
`argumentPosition` is used in the error message to tell which argument it is. Error is thrown.\
`System.CheckArgument(1, {}, "string", "number)` -> throws error "bad argument #1 (string or number expected, got table)"


`System.GetLog(name: string, key: string): Logger`\
Allows you to easily write to the OS logs with the `name` being added to the log messages you write.\
Log messages follow this format: `[<os uptime>][<state>] <name> | <message>`, where the first segment is the computer uptime, the second is the "state" ("Info", "Alert", "Warn", or "Error"), name is the name provided to `.GetLogger()`.\
Logger is a table with four functions: `.Info`, `.Alert`, `.Warn` and `.Error`, all of which take one argument "message".


`System.GetAPI(name: string, unique: boolean): table`\
When an api is loaded, it's placed into the `System` table, allowing you to do `System.<api name>` to interact with the table.\
To prevent modification of these APIs, the APIs are loaded and the passed through `System.Table.Seal` in order to seal the API and prevent any modifications. This sealed table is then returned.\
`unique` cause a fresh, unique copy of the API to be loaded from the disk and returned even if it already exists inside the `System` table. This allows you to grab your own unique version of the API no one else has access to.


`System.GetConfig(name: string): table`\
Loads a configuration from `/System/Configuration` using RCF. This will be fixed later, expect changes.

`System.Uptime(): number`\
Number of seconds the system has been on.

`System.Shutdown(cause: string, delay: number): nil`\
Shuts down the system.
Delay is the number of seconds to wait after the "system_shutdown" event is fired and we being to log users off. It is also used in `Session:Logout()`.\
First the "system_shutdown" event is fired (to all users and even if restarting), we wait `delay` seconds, then one-by-one the users are logged out via `Session:Logout()`.\
Afterwards, the system cleans up and then calls the platform's shutdown.

`System.Restart(cause: string, delay: number): nil`\
Restarts the system.
Delay is the number of seconds to wait after the "system_shutdown" event is fired and we being to log users off. It is also used in `Session:Logout()`.\
First the "system_shutdown" event is fired (to all users and even if restarting), we wait `delay` seconds, then one-by-one the users are logged out via `Session:Logout()`.\
Afterwards, the system cleans up and then calls the platform's shutdown.


## FileSystem
`System.FileSystem` is the FileSystem API, but with a few additions:

`System.FileSystem.RemoveLeadingSlash(path: string): string`\
Removes the leading slash `/` from a path. Note this is not recursive, literally removes the first `/`.


`System.FileSystem.Strip(path: string): string`\
Strips any `..` from the path, preventing the path from being translated to higher directories.\
`/my/path/../../to/a/file` -> `/my/path/to/a/file`



## Table
System.Table is a copy of table but with a few additions:

`System.Table.InsertUniqueValue(t: table, value: any): nil`\
Inserts a value `value` into a table using `table.insert` but only if the value is not already in the table.


`System.Table.Protect(original: table): table`\
Protects the original contents of the table by making them read-only, but allowing new content to be added.\
Prevents existing data from being modified or removed. This is also recursive by protecting tables within the original table.\
The table returned is the protected table.


`System.Table.Seal(original: table): table`
Makes a table read-only without the ability to add new keys.\
The table returned is the protected table.



## Localization
`System.Localization.SupportedLanguages`: list of supported languages (file present inside `/System/Localization/`)\
`System.Localization.Languages`: loaded languages

`System.Localization.GetLangauge([name: string]): table`\
Returns the language table for a given language (name), which defaults to the System language