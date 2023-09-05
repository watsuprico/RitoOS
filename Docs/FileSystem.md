# Hudston FileSystem (HFS)

`Segments(path: string): table (string)`\
Returns a table containing one entry for each canonical segment of the given path.\
For example, `"foo/bar"` becomes `{"foo","bar"}`, `"foo/bar/../baz"` becomes `{"foo","baz"}`.

`Canonical(path: string): string`\
Returns the canonical form of the specified path, i.e. a path containing no "indirections" such as `.` or `...` For example, the paths `/tmp/../bin/ls.lua` and `/bin/./ls.lua` are equivalent, and their canonical form is `/bin/ls.lua`.

`Combine(path1: string, path2: string[, ...]): string`\
Combines two or more paths.\
Note that all paths other than the first are treated as relative paths, even if they begin with a slash.\
The canonical form of the resulting concatenated path is returned, so `Combine("a", "..")` results in an empty string.

`GetDrive(path: string): Drive, string, boolean`\
Takes a path and returns the drive the path lives on and the path with the drive.\
That is, it looks up if the path hits any mounts points and then returns the drive the mount points to and the path with the mount path removed.\
So, if you have a drive mounted at `/myDrive` and run this function with `/myDrive/some/file` you'll get the drive `/myDrive` points to and then the path `/some/file`.\
The returns boolean (#3) is whether the mount is read-only or not.

`GetDrives(): table (driveData)`\
Returns all mounted drives

`GetOpenComputersDriveComponent(filter): filesystem`
**Only supported on OpenComputers platform**.\
Returns the `filesystem` component given a filter, which can the drive label or address.

`Mount(driveComponent: (filesystem | string), path: string, [, name: string [, makeReadOnly: boolean = false]): Drive`
Creates a new `Drive` and "mounts" it to a path, allowing the drive to be access and process any filesystem actions on/in the path.\
`driveComponent`: On OpenComputers, either the `filesystem` component or a filter (such as the drive label or address) used to find the `filesystem` component. On ComputerCraft, the path ('/rom/').\
`path`: location where the drive will be accessed from\
`name`: friendly name of the drive. On OpenComputers, this defaults to the drive's label. On ComputerCraft this defaults to the path without the trailing "/".
`makeReadOnly`: whether you want write access to be blocked by the Drive object

`GetMounts(): table (mountData)`\
Returns all mounts paths.\
Mount data is:
`DriveName`: the drive name (which is the index within the `GetDrives()` table)
`ReadOnly`: whether this mount is read-only

`UnMount(path: string)`\
Removes the mount `path`.


`CanAccess(path: string): boolean`
This is a placeholder for the most part. Once access control is implemented, this will become more useful. For now returns "true" if the path is readable (hits a mount point).

`GetName(path: string): string`
Returns the leaf of a path (`/some/path/to/a/file -> file`)

`GetParent(path: string): string`
Returns the parent directory of a path (`/some/path/to/a/file -> /some/path/to/a/`)

`IsDriveRoot(path: string): string`
Returns whether the path is a mount path, that is it points to the root of a mount (drive).


## Drive
The "Drive" object is the underlying interactions with the actual filesystem (floppies and hard drives).\
Drive serves as an abstraction layer between the hardware and the filesystem, this is the who's doing the actual filesystem syscalls.

On OpenComputers, this wraps around the `filesystem` component, which is the interactions with the hard drive or floppy disk. _Note: `filesystem` must be in **managed** mode!_

On ComputerCraft, this wraps around the `fs` calls. Since there's no direct drive access, only access via the mount path in CC, the drive object calls the appropriate `fs` function but appends the drive's actual path to the path.\
So, what I mean by this is if you're trying to read from the `rom` "drive", doing `:List("/programs/")` would actually be equivalent to calling `fs.list("/rom/programs/")`, since "`/rom/`" is the actual path of the drive in CC.


Drive has essentially the same methods as HFS. The only difference is HFS is using `GetDrive(...)` to find the drive then calling the appropriate method on the drive while passing the path (with the mount directory being removed).



### Creating a Drive
`.New(driveComponent: (filesystem | string), makeReadOnly: boolean): Drive`\
Wraps around a filesystem provided by the hardware.
On OpenComputers, driveComponent can be the `filesystem` component or a string used to lookup the `filesystem` component using the `GetOpenComputersDriveComponent(filter)` function.\
On ComputerCraft, the path to the drive.

`driveComponent`: the the underlying filesystem. For OpenComptuers, this would be a [filesystem](https://ocdoc.cil.li/component:filesystem) component. For ComputerCraft, this would be a drive path (such as "/", "/rom", "/disk1").\
`makeReadOnly`: whether to mark the drive as read-only. Default is `false`.

Returns: `Drive` - the drive object you've created


`:GetLabel(): string`\
Returns the drive name

`:CanAccess(path: string): boolean`\
Placeholder for access control, returns true


`:MarkReadOnly([enable: boolean = true]): boolean`\
Attempts to mark the drive as read-only (if `enable` is true) or as writable (if `enable` is false)\
Returns true if successful, false if the drive is marked read-only by the driveComponent (cannot be written to).

`:List(path: string): table (string[])`\
List of files in a given directory on the drive. Sorted A-Z, a-z. Directories have a trailing "/".\
If you do not have access (`:CanAccess()`) to a particular directory/file, it'll be removed.

`:Exists(path: string): boolean`\
Tests whether a file or directory exists

`:IsDirectory(path: string): boolean`\
Tests whether a path is a directory

`:IsFile(path: string): boolean`\
Tests whether a path is a file

`:IsReadOnly(path: string): boolean`\
Tests whether a file or directory is read-only

`:GetAttributes(path: string): table`\
Returns a list of attributes:\
`LastModified`: time the path was last modified _Not supported in some older versions of ComputerCraft_\
`Created`: time the path was created _Not supported in OpenComputers and some older versions of ComputerCraft_\
`IsReadOnly`: path is read-only\
`IsDirectory`: path is a directory\
`Size`: size of the path takes up on the disk\
`DriveName`: name of the drive the path is on


`:GetCapacity(): number`\
Returns the capacity of the drive.

`:GetFreeSpace(): number`\
Returns the free space on the drive.\
_On OpenComputers, this is the capacity - used space_

`:GetUsedSpace(): number`\
Returns the amount of spaced used on the drive.\
_On ComputerCraft, this is the capacity - free space_

`:GetSize(path: string): number`\
Returns the size of a file.

`:LastModified(path: string): number`\
Returns the last time a file was modified.
_Not supported in some older versions of ComputerCraft. On ComputerCraft, uses the attributes._

`:CreateDirectory(path: string): boolean`\
Creates a directory.\
Returns true if created or already exists (and is a directory).

`:CreateFile(path: string): boolean`\
Creates a file.\
Returns true if creates or already exists (and is a file).

`:DeleteDirectory(path: string): boolean`\
Deletes a directory.\
Returns true if the directory exists and was deleted.

`:DeleteFile(path: string): boolean`
Deletes a file.\
Returns true if the file exists and was deleted.

`:Delete(path: string): boolean`
Deletes a file or directory.\
Returns true if successful.


`:Copy(path: string, destination: string[, overwrite: boolean = false): boolean`\
Copies a single file or directory recursively.\
_On OpenComputers, uses `ReadAllBytes()` and `WriteAllBytes()` in order to copy file(s)._\
_On ComputerCraft, uses `fs.copy()`._

`:Move(path: string, destination: string[, overwrite: boolean = false): boolean`
Moves a single file or directory recursively.\
_On OpenComputers, first uses `:Copy()` to copy the contents and then `:Delete()` to remove the original._\
_On ComputerCraft, uses `fs.move()`._


`:Open(path: string, mode: string (r, w, a, rb, wb, or ab)): FileHandle, nil`
Opens a new file handle using one of the following modes: r (read), w (write), a (append), rb (read bytes), wb (write bytes), and ab (append bytes)\
Returns a [FileHandle](#FileHandle)



`Drive:AppendAllBytes(path: string, bytes: string, table (string), number): boolean[, string]`\
Opens a file, appends bytes, then closes the file\
`path`: path to the file to append to\
`bytes`: either a string of bytes, table of bytes (converted to string), or a single byte (number) to append to the file.\
Returns `true` if successful, `false` if failed along with a reason

`Drive:AppendAllText(path: string, text: string, table (string)): boolean[, string]`\
Opens a file, appends text string, then closes the file\
`path`: path to the file to append to\
`bytes`: either a string or table (converted to string) to append to the file.\
Returns `true` if successful, `false` if failed along with a reason

`Drive:AppendAllLines(path: string, lines: string, table (string)): boolean[, string]`\
Opens a file, appends a table of lines, then closes the file\
`path`: path to the file to append to\
`bytes`: either a string or table (converted to string with "\n" between each table entry) to append to the file.\
Returns `true` if successful, `false` if failed along with a reason


`Drive:ReadAllBytes(path): string | nil[, string]`\
Opens a file, reads all bytes, then closes the file. Returns a string of bytes.\
`path`: path to the file to read
Returns `string` with the data or `nil` if unable to open the file with the reason being returned as well.

`Drive:ReadAllText(path): string | nil[, string]`\
Opens a file, reads all text, then closes the file. Returns a string of the file contents\
`path`: path to the file to read
Returns `string` with the data or `nil` if unable to open the file with the reason being returned as well.

`Drive:ReadAllLines(path): string | nil[, string]`\
Opens a file, reads all text, then closes the file. Returns the text as table split on the "\n" character, which is consumed.\
So, each line is the file is added to a table with the ending "\n" removed.\
`path`: path to the file to read
Returns `string` with the data or `nil` if unable to open the file with the reason being returned as well.


`Drive:WriteAllBytes(path: string, bytes: string, table (string), number): boolean[, string]`\
Opens a file, writes bytes, then closes the file\
`path`: path to the file to write to\
`bytes`: either a string of bytes, table of bytes (converted to string), or a single byte (number) to write to the file.
Returns `true` if successful, `false` if failed along with a reason

`Drive:WriteAllText(path: string, text: string, table (string)): boolean[, string]`\
Opens a file, writes text string, then closes the file\
`path`: path to the file to write to\
`bytes`: either a string or table (converted to string) to write to the file.
Returns `true` if successful, `false` if failed along with a reason

`Drive:WriteAllLines(path: string, lines: string, table (string)): boolean[, string]`\
Opens a file, writes a table of lines, then closes the file\
`path`: path to the file to write to\
`bytes`: either a string or table (converted to string with "\n" between each table entry) to write to the file.
Returns `true` if successful, `false` if failed along with a reason




## FileHandle
A file handle is given by the [Drive](#Drive) object and represents a file on the disk.

(common)
`.Seek([whence: string = "cur"[, offset: number = 1]]): number`
`.Flush(): nil`
`.Close(): nil`

(if read mode)
`.Read([count: number = 1]): string, number, nil`
`.ReadAll(): string, number, nil`
`.ReadLine(): string, number, nil`

(if write mode)
`.Write([text: string, number = ""]): nil`
`.WriteLine([text: string, number = "\n"]): nil` (same as above, but appends "\n" to `text`).


# ComputerCraft Compatibility:
The following is a table of support filesystem functions normally found in ComputerCraft and their support level in HFS.

| Method 			| Status 			|
| --				| --				|
complete(...)		| Only available on the ComputerCraft platform |
find(path)			| Only available on the ComputerCraft platform |
isDriveRoot(path)	| Fully supported 	|
list(path)			| Fully supported 	|
combine(path, ...)	| Fully supported 	|
getName(path)		| Fully supported 	|
getDir(path)		| Fully supported 	|
getSize(path)		| Fully supported 	|
exists(path)		| Fully supported 	|
isDir(path)			| Fully supported 	|
isReadOnly(path)	| Fully supported 	|
makeDir(path)		| Fully supported 	|
move(path, dest)	| Fully supported 	|
copy(path, dest)	| Fully supported 	|
delete(path)		| Fully supported 	|
open(path, mode)	| Fully supported 	|
getDrive(path)		| Fully supported 	|
getFreeSpace(path)	| Fully supported 	|
getCapacity(path)	| Fully supported 	|
attributes(path)	| Fully supported 	|