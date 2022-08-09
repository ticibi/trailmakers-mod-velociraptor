-- Velociraptor Mod for Trailmakers, ticibi 2022
-- name: Velociraptor
-- author: Thomas Bresee
-- description: 

local playerDataTable = {}
local G = 9.8
local R = 10
local Icons = {
    enabled = "☒",
    disabled = "☐",
}

function AddPlayerData(playerId)
    playerDataTable[playerId] = {
        states = {
            {key="position", value=true},
            {key="altitude", value=true},
            {key="heading", value=true},
            {key="distance", value=true},
            {key="speed", value=true},
            {key="velocity", value=false},
            {key="vspeed", value=false},
            {key="gforce", value=true},
            {key="timer", value=false},
            {key="delta", value=true}
        },
        heading = 0,
        distance = 0,
        velocity = 0,
        hide = false,
        speed = 0,
        lastSpeed = 0,
        vSpeed = 0,
        gForce = 0,
        altitudeOffset = 300,
        pos = 0,
        lastPos = tm.vector3.Create(),
        totalDist = 0,
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
    }
end

function onPlayerJoined(player)
    AddPlayerData(player.playerId)
    HomePage(player.playerId)
end

function onPlayerLeft(player)
    local playerData = playerDataTable[player.playerId]
    playerData.totalDist = playerData.totalDist + playerData.dist
end

tm.players.OnPlayerJoined.add(onPlayerJoined)
tm.players.OnPlayerLeft.add(onPlayerLeft)

function update()
    local players = tm.players.CurrentPlayers()
    for i, player in ipairs(players) do
        TestRunCalculations(player.playerId)
        if playerDataTable[player.playerId].time.globalTime > 10 then
            UpdateTimers(player.playerId)
        end
        UpdateTime(player.playerId)
    end
end

function UpdateTime(playerId)
    local playerData = playerDataTable[playerId]
    playerData.time.localTime = playerData.time.localTime + 1
    playerData.time.globalTime = playerData.time.globalTime + 1
    SetValue(playerId, "delta", "delta time: " .. Format(tm.os.GetModDeltaTime()))
end

function UpdateTimers(playerId)
    local playerData = playerDataTable[playerId]
    SetValue(playerId, "globaltime", "uptime: " .. math.floor(playerData.time.globalTime/10) .. "s")
    if playerData.timer.isRunning then
        SetValue(playerId, "timer", "timer: " .. playerData.time.localTime .. " last: " .. playerData.timer.lastTime)
    end
    if not playerData.timer.isRunning then
        playerData.time.localTime = 0
    end
end

function toggleTimer(callbackData)
    local playerId = callbackData.playerId
    local playerData = playerDataTable[callbackData.playerId]
    if not playerData.timer.isRunning then
        playerData.timer.startTime = playerData.time.globalTime
        SetValue(playerId, "toggleTimer", "STOP")
        SetValue(playerId, "dashboard_timer_time", "timer: " .. playerData.timer.currentTime .. " last: " .. playerData.timer.lastTime)
    end
    if playerData.timer.isRunning then
        playerData.timer.stopTime = playerData.time.globalTime
        playerData.timer.currentTime = playerData.timer.stopTime - playerData.timer.startTime
        playerData.timer.lastTime = playerData.timer.currentTime
        SetValue(playerId, "toggleTimer", "START")
        SetValue(playerId, "dashboard_timer_time", "timer: " .. playerData.timer.currentTime .. " last: " .. playerData.timer.lastTime)
        playerData.timer.currentTime = 0
        playerData.time.localLastTime = playerData.time.localTime
    end
    playerData.timer.isRunning = not playerData.timer.isRunning
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function Clear(playerId)
    tm.playerUI.ClearUI(playerId)
end

function SetValue(playerId, key, value)
    tm.playerUI.SetUIValue(playerId, key, value)
end

function Label(playerId, key, text)
    return tm.playerUI.AddUILabel(playerId, key, text)
end

function Button(playerId, key, text, func)
    return tm.playerUI.AddUIButton(playerId, key, text, func)
end

function Text(playerId, key, text, func)
    tm.playerUI.AddUIText(playerId, key, text, func)
end

function Spacer(playerId)
    return Label(playerId, "spacer", "")
end

function HomePage(playerId)
    if type(playerId) ~= "number" then
        playerId = playerId.playerId
    end
    local playerData = playerDataTable[playerId]
    Clear(playerId)
    for i, state in ipairs(playerData.states) do
        if state.value then
            Label(playerId, state.key, 0)
        end
    end
    Button(playerId, "settings", "toggle readouts", SettingsPage)
    Button(playerId, "reset", "reset", OnReset)
    --Button(playerId, "help", "how to read", HelpPage)
end

function OnReset(callback)
    local playerData = playerDataTable[callback.playerId]
    playerData.distance = 0
end

function HelpPage(playerId)
    if type(playerId) ~= "number" then
        playerId = playerId.playerId
    end
    Clear(playerId)
    Label(playerId, "help position", " -- position")
    Label(playerId, "help_1", " current world position coordinates")
    Label(playerId, "help altitude", " -- altitude")
    Label(playerId, "help_1a", "current height above ground")
    Label(playerId, "help heading", " -- heading")
    Label(playerId, "help_2a", "current direction angle")
    Label(playerId, "help distance", " -- distance")
    Label(playerId, "help_3a", "current distance travelled")
    Label(playerId, "help speed", " -- speed")
    Label(playerId, "help_4a", "current speed")
    Label(playerId, "help velocity", " -- velocity")
    Label(playerId, "help_5a", "current velocity vector")
    Label(playerId, "help vspeed", " -- vSpeed")
    Label(playerId, "help_6a", "current speed up and down")
    Label(playerId, "help gforce", " -- gForce")
    Label(playerId, "help_7a", "current linear acceleration g force")
    Button(playerId, "back", "back", HomePage)
end

function CheckActive(state)
    if state then
        return Icons.enabled
    else
        return Icons.disabled
    end
end

function SettingsPage(playerId)
    if type(playerId) ~= "number" then
        playerId = playerId.playerId
    end
    local playerData = playerDataTable[playerId]
    Clear(playerId)
    for i, state in ipairs(playerData.states) do
        Button(playerId, "settings "..state.key, CheckActive(state.value).."  "..state.key, OnToggleState)
    end
    Label(playerId, "altitude offset label", "altitude offset")
    Text(playerId, "altitude offset", playerData.altitudeOffset, OnSetAltitudeOffset)
    Button(playerId, "back", "back", HomePage)
end

function OnSetAltitudeOffset(callback)
    local playerData = playerDataTable[callback.playerId]
    playerData.altitudeOffset = tonumber(callback.value)
end

function OnToggleState(callback)
    local playerData = playerDataTable[callback.playerId]
    local key = callback.id
    for i, state in ipairs(playerData.states) do
        if "settings "..state.key == key then
            state.value = not state.value
            SetValue(callback.playerId, key, CheckActive(state.value).."  "..state.key)
        end
    end
end

function onResetOdometer(callbackData)
    local playerData = playerDataTable[callbackData.playerId]
    playerData.totalDist = playerData.totalDist + playerData.dist
    playerData.dist = 0
end

function onButtonToggleTimer(callbackData)
    toggleTimer(callbackData)
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function GetPlayerPos(playerId)
    return tm.players.GetPlayerTransform(playerId).GetPosition()
end

function GetStateValue(playerId, key)
    local playerData = playerDataTable[playerId]
    for i, state in ipairs(playerData.states) do
        if state.key == key then
            return state.value
        end
    end
end

function TestRunCalculations(playerId)
    local playerData = playerDataTable[playerId]
    local speed = 0
    local playerPos = GetPlayerPos(playerId)
    if GetStateValue(playerId, "speed") or GetStateValue(playerId, "distance") then
        playerData.pos = playerPos
        speed = CalculateSpeed(playerData.lastPos, playerPos)
        local distance = CalculateDeltaDistance(playerPos, playerData.lastPos)
        local newDistance = playerData.distance + distance
        playerData.distance = newDistance
        playerData.lastPos = playerPos
        local mph = mpsToMph(speed)
        local kph = mpsToKph(speed)
        SetValue(playerId, "distance", "distance: "..FormatDistance(playerData.distance))
        SetValue(playerId, "speed", "speed: "..FormatSpeed(mph, kph, speed))
    end
    if GetStateValue(playerId, "gforce") then
        local gForce = CalculateGForce(speed, playerData.lastSpeed)
        playerData.lastSpeed = speed
        SetValue(playerId, "gforce", "G Force: "..Format(gForce))
    end
    if GetStateValue(playerId, "heading") then
        local heading = CalculateHeading(playerId)
        playerData.heading = heading
        SetValue(playerId, "heading", "heading: "..math.floor(heading))
    end
    if GetStateValue(playerId, "velocity") then
        local velocity = CalculateVelocity(speed, playerPos, playerData.lastPos)
        playerData.velocity = velocity
        SetValue(playerId, "velocity", "velocity: "..FormatVector(velocity))
    end
    if GetStateValue(playerId, "altitude") then
        SetValue(playerId, "altitude", "altitude: "..math.ceil(playerPos.y - playerData.altitudeOffset).."m")
    end
    if GetStateValue(playerId, "position") then
        SetValue(playerId, "position", "position: "..FormatVector(playerPos))
    end
    if GetStateValue(playerId, "vspeed") then
        SetValue(playerId, "vspeed", "vspeed: "..playerData.velocity.y.." m/s")
    end
end

function FormatSpeed(mph, kph, mps)
    return math.ceil(mph) .. "mph " .. math.ceil(kph) .. "kph " .. Format(mps) .. "m/s"
end

function FormatDistance(distance)
    local mi = mToMi(distance)
    local km = mToKm(distance)
    return Format(mi) .. "mi / " .. Format(km) .. "km / " .. Format(distance) .. "m"
end

function FormatVector(vector)
    return 'x: '.. math.floor(vector.x)..', y: '..math.floor(vector.y)..', z: '..math.floor(vector.z)
end

function Format(number)
    return string.format("%0.2f", number)
end

function CalculateDeltaDistance(pos, lastPos)
    return math.abs(tm.vector3.op_Subtraction(pos, lastPos).Magnitude())
end

function CalculateSpeed(pos, lastPos)
    local delta = CalculateDeltaDistance(pos, lastPos)
    return delta * R
end

function CalculateGForce(speed, lastSpeed)
    local delta = speed - lastSpeed
    return Format(delta) / G * R
end

function CalculateHeading(playerId)
    return tm.players.GetPlayerTransform(playerId).GetRotation().y
end

function CalculateVelocity(speed, pos, lastPos)
    local d = ((lastPos.x - pos.x)^2 + (lastPos.z - pos.z)^2 + (lastPos.y - pos.y)^2)^0.5
    local x = speed/d*(lastPos.x - pos.x)
    local y = speed/d*(lastPos.y - pos.y) * -1
    local z = speed/d*(lastPos.z - pos.z)
    return tm.vector3.Create(x, y, z)
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
