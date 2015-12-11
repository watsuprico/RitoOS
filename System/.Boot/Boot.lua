--[[ 

     _________________________________________________________________________
    |                                                                         |
    |                      RitoOS - ALPHA BUILD -  ^.^                        |
    |                                                                         |
    | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - |
    |                                                                         |
    |                 Boot File Version Alpha 2.0.1 (B008)                    |
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


local bootScreen = true -- False allows for an instant boot, and removes the boot animation

shutdownAnimation = true -- False speeds up shutdowns by 0.3 seconds, and removes the animation. (Similar to shutting down via recovery) (Also effects reboots)
shutdownWaitTime = 0.05 -- !SETTING THIS INCORRECTLY CAN F*%k YOUR SYSTEM! The time the system will wait in between messages on the shutdown / reboot screen(s). (Set this number to 0 and turn off shutdown animations for instant reboots and shutdowns)

bw = false -- Run in black and white mode?

local _tasks = {}

local ver = "RitoOS Alpha 2.0.1; build 008"
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
    local ok, err = pcall(function() dofile("/System/Services/Config/Config.serv") end)
    if ok then
        System.logInfo("System","Started Config service.")
    else
        System.logAlert("System","Error: Config service either couldn't load, or crashed. Error code: "..err)
    end
end
local function startMonitorService()
    System.logInfo("System","Starting monitor service.")
    local ok, err = pcall(function() dofile('/System/Services/Monitor/Monitor.serv') end)
    if ok then
        System.logInfo("System","Started Monitor service.")
    else
        System.logAlert("System","Error: Monitor service either couldn't load, or crashed. Error code: "..err)
    end
end
local function startUpdateService()
    System.logInfo("System","Starting update service.")
    local ok, err = pcall(function() dofile('/System/Services/Update/Update.serv') end)
    if ok then
        System.logInfo("System","Started Update service.")
    else
        System.logAlert("System","Error: Update service either couldn't load, or crashed. Error code: "..err)
    end
end
local function startRitLock()
    System.logInfo("System","Starting RitLock.")
    local ok, err = pcall(function() dofile('/System/Services/RitLock/RitLock.serv') end)
    if ok then
        System.logInfo("System","Started RitLock service.")
    else
        System.logAlert("System","Error: RitLock service either couldn't load, or crashed. Error code: "..err)
    end
end
local function startOsFunction()
    System.logInfo("System","Starting os function list.")
    local ok, err = pcall(function() dofile('/System/Services/OS/OS.serv') end)
    if ok then
        System.logInfo("System","Started OS Function service.")
    else
        System.logAlert("System","Error: OS Function service either couldn't load, or crashed. Error code: "..err)
    end
end
local function startBackupService()
    System.logInfo("System","Starting Backup service.")
    local ok, err = pcall(function() dofile('/System/Services/Backup/Backup.serv') end)
    if ok then
        System.logInfo("System","Started Backup service.")
    else
        System.logInfo("System","Error: Backup service either couldn't load, or crashed. Error code: "..err)
    end
end
-- End services

-- Main
local function main()
    _G.shell = shell -- Make shell.run() usable
    _G.fs = fs --Make fs usable
    _G.RitoOS = true -- We're booting
    _G.RitoOS_Version = ver -- Our version
    RitoOS = true -- We're running!

    -- Load a few APIs
    if os.loadAPI("/System/APIs/System/System") then
        _G.system = System
        System.reloadLog()
        System.logInfo("System","Core API loaded.")
    else
        error("Failed to load system API.")
    end

    System.logInfo("System","Checking last shutdown state.")
    if not RitoOS_shutdownGood then
        System.logAlert("System","Failed to shutdown correctly.")
        if fs.exists("/System/.Boot/BN") then
            BN =  getTable("/System/.Boot/BN")
            BNi = tonumber(string.sub(BN[1],string.find(BN[1],"!")+1))
            if BNi >= 3 then
                System.logWarn("System","Possibly damaged, booting into recovery")
                _RitoOS_bootIntoRecovery = true
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
    else
        local UpdateStartupFile = assert(io.open("/Startup", "w"))
        UpdateStartupFile:write(System.startupFile())
        UpdateStartupFile:close()
    end
    
    if _RitoOS_bootIntoRecovery == true then
        System.logAlert("System","Entering recovery mode.")
        os.setComputerLabel("[Recovery] - RitoOS")
        SystemBootIntoRecovery = true
        dofile("/System/.Recovery/.Recover")
    end

    if Update_Service_completeOnBoot then
        Complete_Update = true
        os.setComputerLabel("[Updating] - RitoOS")
        dofile("/System/Services/Update/Update.serv")
    end
    
    --Setup the main window
    OldTerm = term.current()
    local maxX, maxY = term.getSize()
    Windows_Main = window.create(term.current(),1,1,maxX,maxY,true)
    term.redirect(Windows_Main)

    os.setComputerLabel("[BOOTING] - RitoOS")

    System.logInfo("System","Showing boot logo")

    if bootScreen then
        parallel.waitForAll(function() -- Boot screen
            System.aniT(colors.gray,0)
        end, function()
            System.aniB(colors.gray,0)
        end, function()
            System.aniT(colors.lightGray,0.043)
        end, function()
            System.aniB(colors.lightGray,0.038)
        end, function()
            sleep(0.083)
            local _,Y = term.getSize()
            local Y = Y/2
            while Y >= 0 do
                term.setCursorPos(1,Y)
                term.setBackgroundColor(colors.white)
                term.clearLine()
                term.setTextColor(colors.black)
                local X3,Y3 = term.getSize()
                term.setCursorPos(math.floor(X3-string.len("RitoOS"))/2, Y3/2-1)
                print("RitoOS")
                term.setCursorPos(math.floor(X3-string.len("Hold R for recovery"))/2, Y3/2+1)
                term.setTextColor(colors.gray)
                print("Hold R for recovery")
                Y = Y-1
                sleep(0)
            end
        end, function()
            System.aniB(colors.white,0.078)
        end)
    else
        term.setBackgroundColor(colors.white)
        term.clear()
    end

    parallel.waitForAny(function()
        local X3,Y3 = term.getSize()
        term.setCursorPos(math.floor(X3-string.len("Hold R for recovery"))/2, Y3/2+1)
        term.setTextColor(colors.orange)
        term.setBackgroundColor(colors.white)
        print("Hold R for recovery")
        local event, key = os.pullEvent("key")
        while true do
            if key == keys.r then
                local X3,Y3 = term.getSize()
                term.setCursorPos(math.floor(X3-string.len("Please wait..."))/2, Y3/2-1)
                term.setTextColor(colors.black)
                term.setBackgroundColor(colors.white)
                term.clear()
                print("Please wait...")
                Reboot_To_Recovery = true
                break
            end
        end
    end,function()
        sleep(0.2)
        local X3,Y3 = term.getSize()
        term.setCursorPos(math.floor(X3-string.len("Hold R for recovery"))/2, Y3/2+1)
        term.setTextColor(colors.gray)
        term.setBackgroundColor(colors.white)
        print("Hold R for recovery")
        end)

    if Reboot_To_Recovery == true then
        local X3,Y3 = term.getSize()
        term.setCursorPos(math.floor(X3-string.len("Rebooting..."))/2, Y3/2)
        term.setTextColor(colors.black)
        term.setBackgroundColor(colors.white)
        term.clearLine()
        print("Rebooting...")
        RitoOS_bootIntoRecovery = true
        sleep(0.5)
        os.reboot(0, true)
    end


    -- Load APIs
    System.logInfo("System","Loading APIs.")

    System.logInfo("System","Loading multitask API.")
    if os.loadAPI("/System/APIs/Multitask/Multitask") then
        _G.monitor = Monitor
        System.logInfo("System","Multitask API loaded.")
    else
        if not err then
            err = "No error code ):"
        end
        System.logAlert("System","Error: Multitask API failed to load or crashed. Error: "..err)
    end
    
    System.logInfo("System","Loading Bedrock API.")
    if os.loadAPI("/System/APIs/Bedrock/Bedrock") then
        System.logInfo("System","Bedrock API loaded.")
    else
        if not err then
            err = "No error code ):"
        end
        System.logAlert("System","Error: Bedrock API failed to load or crashed. Error: "..err)
    end

    System.logInfo("System","Loading monitor API.")
    if os.loadAPI("/System/APIs/Monitor/Monitor") then
        _G.monitor = Monitor
        System.logInfo("System","Monitor API loaded.")
    else
        if not err then
            err = "No error code ):"
        end
        System.logAlert("System","Error: Monitor API failed to load or crashed. Error: "..err)
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
        os.setComputerLabel(RitoOS_Name)
        System.logInfo("System","Loading CodeX")
        local ok, err = pcall(function() dofile("/System/CodeX.rxf") end)
        if not ok then
            if not err then
                err = "No error code! Oh noes! The crash point, however, branched off of line 251 in the boot file. (dofile('/System/CodeX.rxf'))."
            end
            System.logAlert("System PANIC","Oh noes! We crashed! D:")
            System.logAlert("System PANIC","What caused this? Well, I don't know... but this does relate to the system crashing: ' "..err.." '.")
            System.logAlert("System PANIC","Please, send that error message to Watsuprico via PM. He'll tell you how to fix it, when it'll be patched, or at least what it means.")
            System.logAlert("System PANIC","Showing the BSOD message, nothing much I can do.")
            if RitoOS_Config_service_started then
                configfileran = "Yes"
            else
                configfileran = "Unknown, but probably not."
            end
            local crash = assert(io.open("/System/Latest.log", "a"))
            crash:write("\n^ System log file ^\n\nRitoOS crashed.\nHere's some of that juicy debugging info.\n\nCrash info: \nError: "..err.." \n\nGeneral system info: \nCC version: "..RitoOS_CC_Version.."\nRitoOS version: "..RitoOS_Version.."\nConfig file ran: "..configfileran.."\n\n\nEnd of the crash log.\n\n")
            crash:close()
            if fs.exists("/System/crash.log") then
                fs.delete("/System/crash.log")
            end
                fs.copy("/System/Latest.log","/System/crash.log")
            local x,Y = term.getSize()
            term.setBackgroundColor(colors.black)
            term.clear()
            term.setBackgroundColor(colors.gray)
            term.clear()
            sleep(0)
            term.setBackgroundColor(colors.lightGray)
            term.setTextColor(colors.red)
            term.clear()
            sleep(0)
            term.setBackgroundColor(colors.white)
            term.clear()
            sleep(0)
            term.setTextColor(colors.red)
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
            if not attemptToSave then
                print("Press enter to try and save the system.")
            end
            print("Press R to go into recovery.")
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
                else
                    System.logAlert("System PANIC","Shutting down. D:")
                    os.shutdown()
                end
            end
        end
    end
    --Start services
    System.logInfo("System","Starting services.")
    parallel.waitForAll(startConfigService,startBackupService,startMonitorService,startUpdateService,startRitLock,finishBoot)
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
    while true do
        sleep(0)
        function os.version()
            return ver
        end
    end
end

if not RitoOS then
    if term.isColor == nil then
        error("I'm sorry, RitoOS does not support computer versions 1.7 or less! Please upgrade!")
    end
    parallel.waitForAll(TimeKeeper,main,startOsFunction,VersionInfo)
else
    error("RitoOS already running.")
end
