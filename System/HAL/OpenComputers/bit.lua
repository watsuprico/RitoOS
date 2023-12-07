-- "Install" Lua5.1 bit library

local args = {...}
local Internal = args[1]

if (bit32 ~= nil) then
    _G.bit = {
        bnot = bit32.bnot,
        band = bit32.band,
        bor = bit32.bor,
        bxor = bit32.bxor,
        brshift = bit32.arshift,
        blshift = bit32.lshift,
        blogic_rshift = bit32.rshift,
    }
else
    Internal.BootConfig.DoFile("/System/HAL/OpenComputers/bit.lua54")
end