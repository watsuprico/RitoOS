local keyMapping = {}
keyMapping[57] = "space"
keyMapping[40] = "apostrophe"
keyMapping[51] = "comma"
keyMapping[12] = "minus"
keyMapping[52] = "period"
keyMapping[53] = "slash"
keyMapping[11] = "zero"
keyMapping[2] = "one"
keyMapping[3] = "two"
keyMapping[4] = "three"
keyMapping[5] = "four"
keyMapping[6] = "five"
keyMapping[7] = "six"
keyMapping[8] = "seven"
keyMapping[9] = "eight"
keyMapping[10] = "nine"
keyMapping[39] = "semicolon"
keyMapping[13] = "equals"
keyMapping[30] = "a"
keyMapping[48] = "b"
keyMapping[46] = "c"
keyMapping[32] = "d"
keyMapping[18] = "e"
keyMapping[33] = "f"
keyMapping[34] = "g"
keyMapping[35] = "h"
keyMapping[23] = "i"
keyMapping[36] = "j"
keyMapping[37] = "k"
keyMapping[38] = "l"
keyMapping[50] = "m"
keyMapping[49] = "n"
keyMapping[24] = "o"
keyMapping[25] = "p"
keyMapping[16] = "q"
keyMapping[19] = "r"
keyMapping[31] = "s"
keyMapping[20] = "t"
keyMapping[22] = "u"
keyMapping[47] = "v"
keyMapping[17] = "w"
keyMapping[45] = "x"
keyMapping[21] = "y"
keyMapping[44] = "z"
keyMapping[26] = "leftBracket"
keyMapping[43] = "backslash"
keyMapping[27] = "rightBracket"
-- keyMapping[145] = "at" -- not used in CC
-- keyMapping[146] = "colon" -- not used in CC
-- keyMapping[147] = "underline" -- not used in CC

keyMapping[41] = "grave" -- accent grave
keyMapping[28] = "enter"
keyMapping[15] = "tab"
keyMapping[14] = "backspace"
keyMapping[210] = "insert"
keyMapping[211] = "delete"

keyMapping[205] = "right"
keyMapping[203] = "left"
keyMapping[208] = "down"
keyMapping[200] = "up"
keyMapping[201] = "pageUp"
keyMapping[209] = "pageDown"
keyMapping[199] = "home"
keyMapping[207] = "end"

keyMapping[58] = "capsLock"
keyMapping[70] = "scrollLock" -- Scroll Lock
keyMapping[69] = "numlock"
-- no print screen :(
keyMapping[197] = "pause"

-- Function keys
keyMapping[59] = "f1"
keyMapping[60] = "f2"
keyMapping[61] = "f3"
keyMapping[62] = "f4"
keyMapping[63] = "f5"
keyMapping[64] = "f6"
keyMapping[65] = "f7"
keyMapping[66] = "f8"
keyMapping[67] = "f9"
keyMapping[68] = "f10"
keyMapping[87] = "f11"
keyMapping[88] = "f12"
keyMapping[100] = "f13"
keyMapping[101] = "f14"
keyMapping[102] = "f15"
keyMapping[103] = "f16"
keyMapping[104] = "f17"
keyMapping[105] = "f18"
keyMapping[113] = "f19"

-- Control
keyMapping[42] = "leftShift"
keyMapping[29] = "leftCtrl"
keyMapping[56] = "leftAlt"
keyMapping[54] = "rightShift"
keyMapping[157] = "rightCtrl"
keyMapping[184] = "rightAlt" -- right Alt

keyMapping[149] = "stop" -- ??


-- Japanese keyboards
keyMapping[112] = "kana"
keyMapping[148] = "kanji"
keyMapping[121] = "convert"
keyMapping[123] = "noconvert"
keyMapping[125] = "yen"
keyMapping[144] = "circumflex"
keyMapping[150] = "ax"

-- Numpad
keyMapping[82] = "numPad0"
keyMapping[79] = "numPad1"
keyMapping[80] = "numPad2"
keyMapping[81] = "numPad3"
keyMapping[75] = "numPad4"
keyMapping[76] = "numPad5"
keyMapping[77] = "numPad6"
keyMapping[71] = "numPad7"
keyMapping[72] = "numPad8"
keyMapping[73] = "numPad9"
keyMapping[55] = "numPadMultiply"
keyMapping[181] = "numPadDivide"
keyMapping[74] = "numPadSubtract"
keyMapping[78] = "numPadAdd"
keyMapping[83] = "numPadDecimal"
keyMapping[179] = "numPadComma"
keyMapping[156] = "numPadEnter"
keyMapping[141] = "numPadEqual"


local keys = {}
for nKey, sKey in pairs(keyMapping) do
    keys[sKey] = nKey
end

-- Alias some keys for ease-of-use and backwards compatibility
keys["return"] = keys.enter --- @local
keys.scollLock = keys.scrollLock --- @local
keys.cimcumflex = keys.circumflex --- @local


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

-- Translate a numerical key code to a human-readable name.
function keys.getName(_nKey)
    checkArg(1, _nKey, "number")
    return keyMapping[_nKey]
end

_G.keys = keys
Internal.Native.keys = keys