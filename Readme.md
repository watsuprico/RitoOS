# RitoOS: Project Hudson
A multi-platform (Minecraft) OS\* targeting ComputerCraft and OpenComputers.


\* Not technically an operating system (we're not managing memory, resources, devices, etc...), but as close as we can get when it comes to ComputerCraft and OpenComputers.


---

## **IMPORTANT NOTE**:
This project is in the very early stages, alpha type stuff here. Expect things (the APIs) to change drastically at any time.\
Only A few things (such as the boot process and filesystem) are actually in the "beta" stage and may not change dramatically.

At the time of writing, current work is being made on the keyboard drive, EventEmitter and logging in (sessions and the scheduler), along with a few [APIs](./System/RIT/).


To aid with development, most all security features are not enabled (or really implemented 😅). Additionally, the internal tables and variables are accessible to anyone via `Internal.`.\
And lastly, to quickly exit to the shell (on ComputerCraft) or a REPL (on OpenComputer), scroll down then click. This causes the main OS loop to throw an error and handing control back up a level (the shell on ComputerCraft and the REPL in `init.lua` on OpenComputer).\
_Use `writeOutput()` to print to the screen on OpenComputer._



---

## Current progress
At the moment support on both platforms is rocky, OpenComputers more than ComputerCraft.\
The issues with OpenComputers seem to be related to graphics, which doesn't surprise me (the GPU driver and term abstraction layer were quickly and messily thrown together!). If you have any experience there, please feel free to fix those up first!




Below is a table of ComputerCraft APIs, events, and peripherals and their current support.


Implemented means the platform's native methods/APIs are used or recreated fully from scratch and has full parity with the CC variant, where as _emulated_ can mean a few things:
1) the API/feature is not natively supported by a platform,
2) full parity was not achievable between the two,
3) and/or support is available but only for compatibility sake

Implemented is where the feature is more-or-less fully supported, no questions.\
Emulated is where the feature will _work_, but being translated to a common level. For example, RedNet is not supported on OpenComputers, but we still emulate RedNet.


Because most programs are written for ComputerCraft, and I am not writing support for OpenOS on OpenComputers, most (if not all) of the ComputerCraft features (APIs, events, etc) will be supported in some manner.\
This also works when it comes to more advance features available on OpenComputers, such as direct GPU control or networking. These features will be available, but not used in the common applications/APIs.



### Supported features:
#### ComputerCraft:
| API name | Status | ComputerCraft | OpenComputers |
| -- | -- | -- | -- |
| colo(u)rs		| Fully supported  |
| fs			| See [Hudson FileSystem (HFS)](./Docs/FileSystem.md) |
| keys			| Implemented (emulate CC's) |
| os			| Partial support | Implemented | Implemented |
| paintutils	| Partial support |
| parallel		| Partial support |
| term			| Partial support | Implemented | Emulated (GPU driver) |
| vector		| Implemented | Implemented | Implemented |
| window		| Partial support | Implemented | Emulated |


| Event	name			| Status | ComputerCraft | OpenComputers |
| -- | -- | -- | -- |
| char					| Supported (keyboard_character)	| Implemented | Emulated |
| key					| Supported (keydown)	| Implemented | Implemented |
| key_up				| Supported (keyup)	| Implemented | Implemented |
| paste					| Supported (keyboard_paste)	| Implemented | Implemented |




### Not yet supported features:
#### ComputerCraft:

Not yet supported:
| API name | Status |
| -- | -- |
| commands		|	Not implemented / emulated |
| disk			|	Not implemented / emulated |
| gps			|	Not implemented / emulated |
| help			|	Not implemented / emulated - **will not implement**. |
| http			|	Not implemented / emulated |
| io			|	Not implemented / emulated |
| multishell	|	Not implemented / emulated |
| peripheral	|	Not implemented / emulated |
| pocket		|	Not implemented / emulated |
| rednet		|	Not implemented / emulated |
| redstone		|	Not implemented / emulated |
| settings		|	Not implemented / emulated - **may not implement**. _Some settings might be emulated, but it's not decided at this moment._ |
| shell			|	Not implemented / emulated |
| textutils		|	Not implemented / emulated |
| turtle		|	Not implemented / emulated - **will not implement**. _Will be available to CC turtles, but no other devices._ |


| Event	name			|							|
| --					|	--						|
| alarm					|	Not supported / handled	|
| computer_command		|	Not supported / handled	|
| disk					|	Not supported / handled	|
| disk_eject			|	Not supported / handled	|
| file_transfer			|	Not supported / handled	|
| http_check			|	Not supported / handled	|
| http_failure			|	Not supported / handled	|
| http_success			|	Not supported / handled	|
| modem_message			|	Not supported / handled	|
| monitor_resize		|	Not supported / handled	|
| monitor_touch			|	Not supported / handled	|
| mouse_click			|	Not supported / handled	|
| mouse_drag			|	Not supported / handled	|
| mouse_scroll			|	Not supported / handled	|
| mouse_up				|	Not supported / handled	|
| peripheral			|	Not supported / handled	|
| peripheral_detach		|	Not supported / handled	|
| rednet_message		|	Not supported / handled	|
| redstone				|	Not supported / handled	|
| speaker_audio_empty	|	Not supported / handled	|
| task_complete			|	Not supported / handled	|
| term_resize			|	Not supported / handled	|
| terminate				|	Not supported / handled	|
| timer					|	Not supported / handled	|
| turtle_inventory		|	Not supported / handled	|
| websocket_closed		|	Not supported / handled	|
| websocket_failure		|	Not supported / handled	|
| websocket_message		|	Not supported / handled	|
| websocket_success		|	Not supported / handled	|