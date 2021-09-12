-- Velociraptor Mod
-- by dinoman
-- 2021

local playerDataTable = {}

local G = 9.8
local activeIcon = "☒"
local inactiveIcon = "☐"
local meters = {
    "position",
    "altitude",
    "heading",
    "distance",
    "speed",
    "velocity",
    "vSpeed",
    "gForce",
    "timer",
}

function addPlayerToDataTable(playerId)
    playerDataTable[playerId] = {
        name = tm.players.GetPlayerName(playerId),
        speed = 0,
        lastSpeed = 0,
        vSpeed = 0,
        hdg = 0,
        gForce = 0,
        alt = 0,
        altOffset = 300,
        pos = 0,
        lastPos = tm.vector3.Create(),
        v = 0,
        dist = 0,
        totalDist = 0,
        fastest = 0,
        time = {
            globalTime = 0,
            localTime = 0,
            localLastTime = 0,
        },
        timer = {
            currentTime = 0,
            lastTime = 0,
            startTime = 0,
            stopTime = 0,
            isRunning = false,
        },
        ui = {
            hidden = false,
            states = {
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
            }
        },
    }
end

function onPlayerJoined(player)
    local playerId = player.playerId
    Log(playerId .. " joined.")
    addPlayerToDataTable(playerId)
    addUiAndHotkeysForPlayer(playerId)
end

function onPlayerLeft(player)
    local playerData = playerDataTable[player.playerId]
    playerData.totalDist = playerData.totalDist + playerData.dist
end

tm.players.OnPlayerJoined.add(onPlayerJoined)
tm.players.OnPlayerLeft.add(onPlayerLeft)

function update()
    local playerList = tm.players.CurrentPlayers()
    for k, player in pairs(playerList) do
        local playerId = player.playerId
        local playerData = playerDataTable[playerId]
        
        runCalculations(playerId)
        
        if playerData.time.globalTime > 10 then
            updateTimers(playerId)
        end

        playerData.time.localTime = playerData.time.localTime + 1
        playerData.time.globalTime = playerData.time.globalTime + 1
        tm.playerUI.SetUIValue(playerId, "_delta", "delta: " .. fmat(tm.os.GetModDeltaTime()))
    end
end

function updateTimers(playerId)
    local playerData = playerDataTable[playerId]
    tm.playerUI.SetUIValue(playerId, "_global", "uptime: " .. math.floor(playerData.time.globalTime/10) .. "s")
    if playerData.timer.isRunning then
        tm.playerUI.SetUIValue(playerId, "_timer", "timer: " .. playerData.time.localTime .. " last: " .. playerData.timer.lastTime)
    end
    if not playerData.timer.isRunning then
        playerData.time.localTime = 0
    end
end

function onReturnToMainMenu(callbackData)
    mainPage(callbackData.playerId)
end

function toggleTimer(callbackData)
    local playerId = callbackData.playerId
    local playerData = playerDataTable[callbackData.playerId]
    if not playerData.timer.isRunning then
        playerData.timer.startTime = playerData.time.globalTime
        tm.playerUI.SetUIValue(playerId, "toggleTimer", "STOP")
        tm.playerUI.SetUIValue(playerId, "dashboard_timer_time", "timer: " .. playerData.timer.currentTime .. " last: " .. playerData.timer.lastTime)
    end
    if playerData.timer.isRunning then
        playerData.timer.stopTime = playerData.time.globalTime
        playerData.timer.currentTime = playerData.timer.stopTime - playerData.timer.startTime
        playerData.timer.lastTime = playerData.timer.currentTime
        tm.playerUI.SetUIValue(playerId, "toggleTimer", "START")
        tm.playerUI.SetUIValue(playerId, "dashboard_timer_time", "timer: " .. playerData.timer.currentTime .. " last: " .. playerData.timer.lastTime)
        playerData.timer.currentTime = 0
        playerData.time.localLastTime = playerData.time.localTime
    end
    playerData.timer.isRunning = not playerData.timer.isRunning
end

function addUiAndHotkeysForPlayer(playerId)
    mainPage(playerId)
    --tm.input.RegisterFunctionToKeyDownCallback(playerId, "toggleTimer", "t")
end

function mainPage(id)
    local playerData = playerDataTable[id]
    local states = playerData.ui.states
    local hidden = playerData.ui.hidden
    tm.playerUI.ClearUI(id)
    if states[1] then tm.playerUI.AddUILabel(id, "_position", 0) end
    if states[2] then tm.playerUI.AddUILabel(id, "_altitude", 0) end
    if states[3] then tm.playerUI.AddUILabel(id, "_heading", 0) end
    if states[4] then tm.playerUI.AddUILabel(id, "_distance", 0) end
    if states[5] then tm.playerUI.AddUILabel(id, "_speed", 0) end
    if states[6] then tm.playerUI.AddUILabel(id, "_velocity", 0) end
    if states[7] then tm.playerUI.AddUILabel(id, "_vSpeed", 0) end
    if states[8] then tm.playerUI.AddUILabel(id, "_gForce", 0) end
    if states[9] then tm.playerUI.AddUILabel(id, "_timer", "start timer") end
    if states[9] then tm.playerUI.AddUIButton(id, "toggleTimer", "START", onButtonToggleTimer) end
    if not hidden then tm.playerUI.AddUIButton(id, "help", "Help", helpPage) end
    if not hidden then tm.playerUI.AddUIButton(id, "settings", "settings", settingsPage) end
    if not hidden then tm.playerUI.AddUIButton(id, "_rest_distance", "reset distance", onResetOdometer) end
    if not hidden then tm.playerUI.AddUILabel(id, "_global", "uptime: " .. 0 .. "s") end
    if not hidden then tm.playerUI.AddUILabel(id, "_delta", "delta: " .. 0) end
    if not hidden then tm.playerUI.AddUILabel(id, "credits", "developed by dinoman") end

    tm.playerUI.AddUIButton(id, "hide", "Hide", onHideUI)
end

function helpPage(callbackData)
    local id = callbackData.playerId
    tm.playerUI.ClearUI(id)
    tm.playerUI.AddUILabel(id, "help_title", "Help")
    tm.playerUI.AddUIButton(id, "help_back", " << Back", onReturnToMainMenu, nil)
    tm.playerUI.AddUILabel(id, "help_1", " -- position")
    tm.playerUI.AddUILabel(id, "help_1", " current world position coordinates")
    tm.playerUI.AddUILabel(id, "help_1", " -- altitude")
    tm.playerUI.AddUILabel(id, "help_1a", "current height above ground")
    tm.playerUI.AddUILabel(id, "help_2", " -- heading")
    tm.playerUI.AddUILabel(id, "help_2a", "current direction angle")
    tm.playerUI.AddUILabel(id, "help_3", " -- distance")
    tm.playerUI.AddUILabel(id, "help_3a", "current distance travelled")
    tm.playerUI.AddUILabel(id, "help_4", " -- speed")
    tm.playerUI.AddUILabel(id, "help_4a", "current speed")
    tm.playerUI.AddUILabel(id, "help_5", " -- velocity")
    tm.playerUI.AddUILabel(id, "help_5a", "current velocity vector")
    tm.playerUI.AddUILabel(id, "help_6", " -- vSpeed")
    tm.playerUI.AddUILabel(id, "help_6a", "current speed up and down")
    tm.playerUI.AddUILabel(id, "help_7", " -- gForce")
    tm.playerUI.AddUILabel(id, "help_7a", "current linear acceleration g force")
    tm.playerUI.AddUILabel(id, "help_8", " -- timer")
    tm.playerUI.AddUILabel(id, "help_8a", "start/stop timer")
end

function settingsPage(callbackData)
    local id = callbackData.playerId
    local playerData = playerDataTable[id]
    tm.playerUI.ClearUI(id)
    tm.playerUI.AddUILabel(id, "settings_title", "Settings")
    tm.playerUI.AddUIButton(id, "settings_back", " << Back", onReturnToMainMenu)
    tm.playerUI.AddUILabel(id, "spacer", "")
    local states = playerData.ui.states
    for i = 1, #meters do
        local state = states[i]
        local icon = ""
        if state then
            icon = activeIcon
        else
            icon = inactiveIcon
        end
        tm.playerUI.AddUIButton(id, meters[i], icon .. "    " .. meters[i], onToggleMeter)
    end
    tm.playerUI.AddUILabel(id, "settings_title", "altitude offset")
    tm.playerUI.AddUIText(id, "altitude_offset", playerData.altOffset, altitudeOffset)
end

function altitudeOffset(callbackData)
    local playerData = playerDataTable[callbackData.playerId]
    playerData.altOffset = tonumber(callbackData.value)
end

function onHideUI(callbackData)
    local id = callbackData.playerId
    local playerData = playerDataTable[id]
    playerData.ui.hidden = not playerData.ui.hidden
    if playerData.ui.hidden then
        tm.playerUI.SetUIValue(id, "hide", "Show")
    else
        tm.playerUI.SetUIValue(id, "hide", "Show")
    end
    onReturnToMainMenu(callbackData)
end

function onToggleMeter(callbackData)
    local playerId = callbackData.playerId
    local playerData = playerDataTable[playerId]
    local indicies = {}
    for k, v in pairs(meters) do 
        indicies[v] = k
    end
    local states = playerData.ui.states
    local index = indicies[callbackData.id]
    local state = states[index]
    playerData.ui.states[index] = not state
    if not state then
        toggle = activeIcon
    else
        toggle = inactiveIcon
    end
    tm.playerUI.SetUIValue(playerId, callbackData.id, toggle .. "    " .. callbackData.id) 
end

function onResetOdometer(callbackData)
    local playerData = playerDataTable[callbackData.playerId]
    playerData.totalDist = playerData.totalDist + playerData.dist
    playerData.dist = 0
end

function onButtonToggleTimer(callbackData)
    toggleTimer(callbackData)
end

function runCalculations(playerId)
    local playerData = playerDataTable[playerId]
    local transform = tm.players.GetPlayerTransform(playerId)
    local hdg = transform.GetRotation().y
    playerData.hdg = hdg

    local pos = transform.GetPosition()
    playerData.pos = pos
    
    local d = math.abs(tm.vector3.op_Subtraction(playerData.lastPos, pos).Magnitude())
    local distance = playerData.dist + d
    playerData.dist = distance

    local speed = d * 10
    local deltaSpeed = speed - playerData.lastSpeed
    playerData.lastSpeed = speed

    local g = fmat(deltaSpeed) / G * 10
    playerData.gForce = g

    local velocity = calculateVelocity(speed, pos, playerData.lastPos)
    playerData.v = velocity

    playerData.lastPos = pos
    playerData.alt = pos.y

    if speed > playerData.fastest then
        playerData.fastest = speed
    end

    local mph = mpsToMph(speed)
    local kph = mpsToKph(speed)
    local mi = mToMi(distance)
    local km = mToKm(distance)

    local alt = playerData.alt - playerData.altOffset
    playerData.alt = alt

    tm.playerUI.SetUIValue(playerId, "_position", "pos: " .. formatVector(pos))
    tm.playerUI.SetUIValue(playerId, "_altitude", "alt: " .. math.floor(alt))
    tm.playerUI.SetUIValue(playerId, "_heading", "heading: " .. math.floor(hdg))
    tm.playerUI.SetUIValue(playerId, "_distance", "dist: " .. fmat(mi) .. "mi / " .. fmat(km) .. "km / " .. fmat(distance) .. "m")
    tm.playerUI.SetUIValue(playerId, "_speed", "speed: " .. math.ceil(mph) .. " mph / " .. math.ceil(kph) .. " kph / " .. fmat(speed) .. "m/s")
    tm.playerUI.SetUIValue(playerId, "_velocity", "velocity: " .. formatVector(velocity) .. " m/s")
    tm.playerUI.SetUIValue(playerId, "_vSpeed", "vSpeed: " .. fmat(mpsToMph(velocity.y)) .. " mph / " .. fmat(mpsToKph(velocity.y)) .. " kph")
    tm.playerUI.SetUIValue(playerId, "_gForce", "gForce: " .. fmat(g))
end

function calculateVelocity(speed, v1, v2)
    local d = ((v2.x - v1.x)^2 + (v2.z - v1.z)^2 + (v2.y - v1.y)^2)^0.5
    local x = speed/d*(v2.x - v1.x)
    local y = speed/d*(v2.y - v1.y) * -1
    local z = speed/d*(v2.z - v1.z)
    return tm.vector3.Create(x, y, z)
end

function Log(message)
    tm.os.Log(message)
end

function mToMi(meters)
    return meters / 1609.3444
end

function mToKm(meters)
    return meters / 1000
end

function mpsToMph(mps)
    return mps * 2.23693629
end

function mpsToKph(mps)
    return mps * 3.6
end

function formatVector(v)
    return fmat(v.x) .. ", " .. fmat(v.y) .. ", " .. fmat(v.z)
end

function fmat(number)
    return string.format("%0.2f", number)
end
