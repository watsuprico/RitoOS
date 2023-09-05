-- "Install" Lua5.1 bit library

_G.bit = {
    bnot = bit32.bnot,
    band = bit32.band,
    bor = bit32.bor,
    bxor = bit32.bxor,
    brshift = bit32.arshift,
    blshift = bit32.lshift,
    blogic_rshift = bit32.rshift,
}