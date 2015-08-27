--[[ 

     _________________________________________________________________________
    |                                                                         |
    |                      RitoOS - ALPHA BUILD -  ^.^                        |
    |                                                                         |
    | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - |
    |                                                                         |
    |                      Recovery Version Alpha 2.0                         |
    |                                                                         |
    |  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  |
    |                                                                         |
    |   Thank you for looking at RitoOS, (or downloading it), it means alot.  |
    |    If you would like to learn more, head on over to the Github page:    |
    |              https://www.github.com/Watsuprico/RitoOS/                  |
    |                                                                         |
    |- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -|
   _|                                                                         |
  |             Some extended info on copying and using RitoOS                |______________________________________________________ 
  |                                                                                                                                 |
  | Permission is hereby granted, free of charge, to any person obtaining a copy of this software and                               |
  | associated documentation files (the "Software"), to deal in the Software without restriction,                                   |
  | including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,                           |
  | copies of the Software, and to permit persons to whom the Software is furnished to do so,                                       |
  | subject to the following conditions:                                                                                            |
  |                                                                                                                                 |
  | -The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. |
  | -Visible credit is given to the original author.                                                                                |
  | -The software is distributed in a non-profit way.                                                                               |
  |                                                                                                                                 |
  | THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE            |
  | WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR           |
  | COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,     |
  | ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                           |
  |                                                                                                                                 |
  |_________________________________________________________________________________________________________________________________|


]]

local devMode = false --Does nothing... for now.


local ver = "RitoOS RitoOS Alpha 2.0.1; build 002"
_G.RitoOS_CC_Version = os.version() -- Computercraft version

local function getTable(path)
    if fs.exists(path) then
        local file = io.open(path, "r")
        local lines = {}
        local i = 1
        local line = file:read("*l")
        while line ~= nil do
            lines[i] = line
            line = file:read("*l")
            i = i + 1
        end
        file:close()
        return lines
    end
    return {}
end

-- Services
local function startConfigService()
    System.logInfo("System","Starting config service.")
    local ok, err = pcall(function() dofile('/System/Services/Config/Config.serv') end)
    if ok then
        System.logInfo("System","Started config service.")
    else
        System.logAlert("System","Error: config serivce either couldn't load, or crashed. Error code: "..err)
    end
end
local function startMonitorService()
    System.logInfo("System","Starting monitor service.")
    local ok, err = pcall(function() dofile('/System/Services/Monitor/Monitor.serv') end)
    if ok then
        System.logInfo("System","Started monitor service.")
    else
        System.logAlert("System","Error: monitor serivce either couldn't load, or crashed. Error code: "..err)
    end
end
local function startUpdateService()
    System.logInfo("System","Starting update service.")
    dofile('/System/Services/Update/Update.serv')
    local ok, err = pcall(function() dofile('/System/Services/Update/Update.serv') end)
    if ok then
        System.logInfo("System","Started config service.")
    else
        System.logAlert("System","Error: config serivce either couldn't load, or crashed. Error code: "..err)
    end
end
local function startRitLock()
    System.logInfo("System","Starting RitLock.")
    dofile('/System/Services/RitLock/RitLock.serv')
end
-- End services

-- Main
local function main()
    sleep(0)
    term.setBackgroundColor(colors.gray)
    term.clear()
    sleep(0)
    term.setBackgroundColor(colors.lightGray)
    term.clear()
    sleep(0)
    term.setBackgroundColor(colors.white)
    term.clear()
    _G.shell = shell -- Make shell.run() usable
    _G.RitoOS = true -- We're booting
    _G.RitoOS_Version = ver -- Our version

    -- Load a few APIs
    if os.loadAPI("/System/APIs/System/System") then
        _G.system = System
        System.reloadLog()
        System.logInfo("System","Core API loaded.")
    else
        error("Failed to load system API.")
    end

    System.logInfo("System","Checking last shutdown state.")
    if not LastShutdownSuccessful then
        System.logAlert("System","Failed to shutdown correctly.")
        if fs.exists("/System/.Boot/BN") then
            BN =  getTable("/System/.Boot/BN")
            BNi = tonumber(string.sub(BN[1],string.find(BN[1],"!")+1))
            if BNi >= 3 then
                System.logWarn("System","Possibly damaged, booting into recovery")
                RitoOS_Enter_Recovery = true
            else
                BNi = BNi + 1
                local file = assert(io.open("/System/.Boot/BN", "w"))
                file:write("!"..BNi)
                 file:close()
            end
        else
            local file = assert(io.open("/System/.Boot/BN", "w"))
            file:write("!1")
            file:close()
        end
    end
    
    if RitoOS_Enter_Recovery == true then
        System.logAlert("System","Enterying recovery mode.")
        dofile("/System/.Recovery/.Recover")
    end

    -- Load APIs
    System.logInfo("System","Loading APIs.")

    System.logInfo("System","Loading monitor API.")
    if os.loadAPI("/System/APIs/Monitor/Monitor") then
        _G.monitor = Monitor
        System.logInfo("System","Monitor API loaded.")
    else
        System.logAlert("System","Error: Monitor API failed to load or crashed.")
    end
    System.logInfo("System","Loading update API")
    if os.loadAPI("/System/APIs/Update/Update") then
        System.logInfo("System","Update API loaded.")
    else
        System.logAlert("System","Error: Update API failed to load or crashed.")
    end

    System.logInfo("System","Loading StrUtils API.")
    if os.loadAPI("/System/APIs/StrUtils/StrUtils") then
        System.logInfo("System","StrUtils API loaded.")
    else
        System.logAlert("System","StrUtils API failed to load.")
    end

    local function finishBoot()
        --Set a few more vars
        System.logInfo("System","Setting computer label")
        os.setComputerLabel(RitoOS_Computer_Label)
        System.logInfo("System","Loading CodeX")
        local ok, err = pcall(function() term.setBackgroundColor(colors.black) term.clear() dofile("/System/OLD_CodeX.rxf") end)
        if not ok then
            if not err then
                err = "No error code! Oh noes! The crash point, however, branched off of line 177 in the boot file."
            end
            System.logAlert("System PANIC","Oh noes! We crashed! D:")
            System.logAlert("System PANIC","What caused this? Well, I don't know... but this does relate to the system crashing: ' "..err.." '.")
            System.logAlert("System PANIC","Please, send that error message to Watsuprico via PM. He'll tell you how to fix it, when it'll be patched, or at least what it means.")
            System.logAlert("System PANIC","Showing the BSOD message, nothing much I can do.")
            configfiledata = "Sorry, I couldn't retrieve that data ): "
            local crash = assert(io.open("/System/Latest.log", "a"))
            crash:write("\n^ System log file ^\n\nRitoOS crashed.\nHere's some of that juicy debugging info.\n\nCrash info: \nError: "..err.." \n\nGeneral system info: \nCC version: "..RitoOS_CC_Version.."\nRitoOS version: "..RitoOS_Version.."\nConfig file: "..configfiledata.."\n\n\nEnd of the crash log.\n\n")
            crash:close()
            if fs.exists("/System/crash.log") then
                fs.delete("/System/crash.log")
            end
                fs.copy("/System/Latest.log","/System/crash.log")
            local x,Y = term.getSize()
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.white)
            term.clear()
            sleep(0)
            term.setBackgroundColor(colors.lightGray)
            term.clear()
            sleep(0)
            term.setBackgroundColor(colors.gray)
            term.clear()
            sleep(0)
            term.setBackgroundColor(colors.black)
            term.clear()
            term.setCursorPos(math.floor(x-string.len("This isn't too good..."))/2, math.floor(Y/2))
            print("That isn't too good...")
            sleep(0.1)
            term.setBackgroundColor(colors.gray)
            term.clear()
            sleep(0)
            term.setBackgroundColor(colors.lightGray)
            term.setTextColor(colors.brown)
            term.clear()
            term.setBackgroundColor(colors.white)
            term.clear()
            sleep(0)
            term.setCursorPos(math.floor(x-string.len('Sorry about that :('))/2, 2)
            write("Sorry about that. ): ")
            term.setTextColor(colors.black)
            term.setCursorPos(math.floor(x-string.len('RicoOS has crashed.'))/2, 5)
            print("RitoOS has crashed.")
            term.setCursorPos(3, 7)
            print("Please, report this error to Watsuprico via PM:")
            term.setTextColor(colors.red)
            term.setCursorPos(3, 8)
            print(err)
            print()
            print()
            term.setTextColor(colors.gray)
            term.setCursorPos(math.floor(x-string.len('Please remember, when sending the bug report"'))/2, 11)
            print("Please remember, when sending the bug report")
            term.setCursorPos(math.floor(x-string.len('.include the log file at "/System/Latest.log"'))/2, 12)
            print("include the log file at: '/System/Latest.log'")
            print()
            print("Press enter to try and save the system.")
            print("Press R to go into recovery.")
            print("Press S to use Computercraft's shell.")
            print("Press any other key to shutdown.")
            sleep(1)
            local e,s = os.pullEvent("key")
            while true do
                sleep(0)
                if s == 28 then
                    if not attemptToSave then
                        attemptToSave = true
                        System.logAlert("System PANIC","Attempting to save myself.")
                        finishBoot()
                    else
                        System.logAlert("System PANIC","Crashed! Error: ' Attempted to save the system, it failed. Shutting down. ' ")
                        os.shutdown()
                    end
                elseif s == 19 then
                    System.logAlert("System PANIC","Starting recovery program.")
                    shell.run("/System/.Recovery/.Recover")
                    System.logAlert("System PANIC","Attempted to start recovery, it failed, crashed, or was closed. Shutting down.")
                    os.shutdown()
                elseif s == 31 then
                    System.logAlert("System PANIC","Starting Computercraft's shell.")
                    shell.run("/rom/programs/shell")
                    System.logAlert("System PANIC","Attempted to start Computercraft's shell, it failed, crashed, or was closed. Shutting down.")
                    os.shutdown()
                else
                    System.logAlert("System PANIC","Shutting down. D:")
                    os.shutdown()
                end
            end
        end
    end
    --Start services
    System.logInfo("System","Starting services.")
    parallel.waitForAll(startConfigService,startMonitorService,startUpdateService,startRitLock,finishBoot)
end


local function TimeKeeper()
    RitoOS_Time = 0
    while true do
        function os.uptime()
            return RitoOS_Time
        end
        sleep(0)
        RitoOS_Time = RitoOS_Time + 0.05
    end
end

local function VersionInfo()
    function os.version()
        return ver
    end
end

if not RitoOS then
    parallel.waitForAll(TimeKeeper,main,VersionInfo)
else
    error("RitoOS already running.")
end