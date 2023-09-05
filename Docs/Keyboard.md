# Keyboard

## Events
### KeyDown
Fired when a key is pressed.

Event data:
| Arg index | Type | Description |
| -- | -- | -- |
| 1 | `number` | The key code of the key pressed |
| 2 | `table` | Table of modifier keys and their states. Example: `{["Ctrl"] = false, ["Shift"] = false, ["Alt"] = false, ["ScrollLock"] = false}` |


_On the OpenComputer platform, the `Character` event is emitted right after this event_.\
_For compatibility with ComputerCraft, the [key](https://tweaked.cc/event/key.html) event is also emitted right after this event._


### KeyHold
Fired once a key is held and every second (depending on the platform) while the key is being held.

Event data:
| Arg index | Type | Description |
| -- | -- | -- |
| 1 | `number` | The key code of the key being held |
| 2 | `table` | Table of modifier keys and their states. Example: `{["Ctrl"] = false, ["Shift"] = false, ["Alt"] = false, ["ScrollLock"] = false}` |
| 3 | `number` | Number of seconds the key has been held (duration) |


_For compatibility with ComputerCraft, the [key](https://tweaked.cc/event/key.html) event is also emitted right after this event._


### KeyHoldReleased
Fired once a key is released from being held. (This is only fired if `KeyHold` was previously fired for this key.)\
A `KeyUp` event will also be fired shortly after this event.

Event data:
| Arg index | Type | Description |
| -- | -- | -- |
| 1 | `number` | The key code of the key released |
| 2 | `table` | Table of modifier keys and their states. Example: `{["Ctrl"] = false, ["Shift"] = false, ["Alt"] = false, ["ScrollLock"] = false}` |
| 3 | `number` | Number of seconds the key was held for (duration) |


### KeyUp
Fired when a key is released (not necessarily after being held, but after being pressed (`KeyDown`)).

Event data:
| Arg index | Type | Description |
| -- | -- | -- |
| 1 | `number` | The key code of the key released |
| 2 | `table` | Table of modifier keys and their states. Example: `{["Ctrl"] = false, ["Shift"] = false, ["Alt"] = false, ["ScrollLock"] = false}` |


_For compatibility with ComputerCraft, the [key_up](https://tweaked.cc/event/key_up.html) event is also emitted right after this event._


### Keyboard_Character
Fired when a key is pressed that represents a character, such as the "s" key.

Event data:
| Arg index | Type | Description |
| -- | -- | -- |
| 1 | `string` | The character of the key pressed |
| 2 | `table` | Table of modifier keys and their states. Example: `{["Ctrl"] = false, ["Shift"] = false, ["Alt"] = false, ["ScrollLock"] = false}` |

_For compatibility with ComputerCraft, the [char](https://tweaked.cc/event/char.html) event is also emitted right after this event._
_On the OpenComputers platform, this is fired immediately (with) the `KeyDown` event._


### Keyboard_Paste
Fired when data is pasted in by the user. This differs from RitoOS's clipboard, as this is data pasted by the _users's_ computer, such as Windows.

Event data:
| Arg index | Type | Description |
| -- | -- | -- |
| 1 | `string` | Text pasted in |
| 2 | `table` | Table of modifier keys and their states. Example: `{["Ctrl"] = false, ["Shift"] = false, ["Alt"] = false, ["ScrollLock"] = false}` |

_For compatibility with ComputerCraft, the [paste](https://tweaked.cc/event/paste.html) event is also emitted right after this event._