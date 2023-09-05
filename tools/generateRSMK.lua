-- RitoOS Secure Machine Key
-- Generates a random RSMK
local RG = System.GetAPI("RandomGenerator")

local file = fs.open("/System/Vault/RSMK","w")
file.write(RG.RandomString(2048))
file.close()