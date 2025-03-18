-- Velociraptor Mod for Trailmakers, ticibi 2022
-- name: Velociraptor
-- author: ticibi
-- version: 2.0 (2025 update)
-- description: Enhanced vehicle telemetry display

local Constants = {
    GRAVITY = 9.8,          -- m/s²
    UPDATE_RATE = 10,       -- Updates per second
    ALTITUDE_DEFAULT = 300  -- Default altitude offset in meters
}

local Icons = {
    enabled = "☒",
    disabled = "☐"
}

local playerDataTable = {}

-- Player Data Management
local function initializePlayerData(playerId)
    return {
        states = {
            position = true, altitude = true, heading = true,
            distance = true, speed = true, velocity = false,
            vspeed = false, gforce = true, timer = false,
            delta = true
        },
        metrics = {
            heading = 0, distance = 0, velocity = tm.vector3.Create(),
            speed = 0, lastSpeed = 0, vSpeed = 0, gForce = 0,
            totalDist = 0
        },
        position = {
            current = tm.vector3.Create(),
            last = tm.vector3.Create()
        },
        time = {
            global = 0,
            localTime = 0,
            localLast = 0
        },
        timer = {
            current = 0,
            last = 0,
            start = 0,
            stop = 0,
            running = false
        },
        settings = {
            altitudeOffset = Constants.ALTITUDE_DEFAULT,
            hidden = false
        }
    }
end

-- Event Handlers
tm.players.OnPlayerJoined.add(function(player)
    playerDataTable[player.playerId] = initializePlayerData(player.playerId)
    createHomePage(player.playerId)
end)

tm.players.OnPlayerLeft.add(function(player)
    local data = playerDataTable[player.playerId]
    if data then
        data.metrics.totalDist = data.metrics.totalDist + data.metrics.distance
        playerDataTable[player.playerId] = nil
    end
end)

-- Main Update Loop
function update()
    local players = tm.players.CurrentPlayers()
    for _, player in ipairs(players) do
        local playerId = player.playerId
        updateCalculations(playerId)
        if playerDataTable[playerId].time.global > Constants.UPDATE_RATE then
            updateTimers(playerId)
        end
        updateTime(playerId)
    end
end

-- Time Management
local function updateTime(playerId)
    local data = playerDataTable[playerId]
    if not data then return end
    
    data.time.localTime = data.time.localTime + 1
    data.time.global = data.time.global + 1
    setUIValue(playerId, "delta", "delta time: " .. string.format("%.3f", tm.os.GetModDeltaTime()))
end

local function updateTimers(playerId)
    local data = playerDataTable[playerId]
    if not data then return end
    
    setUIValue(playerId, "globaltime", "uptime: " .. math.floor(data.time.global/Constants.UPDATE_RATE) .. "s")
    if data.timer.running then
        setUIValue(playerId, "timer", string.format("timer: %d last: %d", data.time.localTime, data.timer.last))
    elseif not data.timer.running then
        data.time.localTime = 0
    end
end

-- UI Management
local function setUIValue(playerId, key, value)
    tm.playerUI.SetUIValue(playerId, key, value)
end

local function clearUI(playerId)
    tm.playerUI.ClearUI(playerId)
end

local function createButton(playerId, key, text, callback)
    return tm.playerUI.AddUIButton(playerId, key, text, callback)
end

local function createLabel(playerId, key, text)
    return tm.playerUI.AddUILabel(playerId, key, text)
end

-- Pages
function createHomePage(playerId)
    local data = playerDataTable[playerId]
    if not data then return end
    
    clearUI(playerId)
    for state, enabled in pairs(data.states) do
        if enabled then
            createLabel(playerId, state, "")
        end
    end
    
    createButton(playerId, "settings", "toggle readouts", createSettingsPage)
    createButton(playerId, "reset", "reset", resetMetrics)
    createButton(playerId, "toggleTimer", data.timer.running and "STOP" or "START", toggleTimer)
end

function createSettingsPage(callbackData)
    local playerId = callbackData.playerId
    local data = playerDataTable[playerId]
    if not data then return end
    
    clearUI(playerId)
    for state, enabled in pairs(data.states) do
        createButton(playerId, "settings_" .. state, 
            (enabled and Icons.enabled or Icons.disabled) .. "  " .. state, 
            toggleState)
    end
    
    createLabel(playerId, "altitude_offset_label", "altitude offset")
    tm.playerUI.AddUIText(playerId, "altitude_offset", tostring(data.settings.altitudeOffset), setAltitudeOffset)
    createButton(playerId, "back", "back", createHomePage)
end

-- Callback Handlers
function toggleState(callback)
    local data = playerDataTable[callback.playerId]
    if not data then return end
    
    local stateKey = callback.id:match("settings_(.+)")
    if stateKey and data.states[stateKey] ~= nil then
        data.states[stateKey] = not data.states[stateKey]
        setUIValue(callback.playerId, callback.id, 
            (data.states[stateKey] and Icons.enabled or Icons.disabled) .. "  " .. stateKey)
    end
end

function resetMetrics(callback)
    local data = playerDataTable[callback.playerId]
    if data then
        data.metrics.distance = 0
    end
end

function setAltitudeOffset(callback)
    local data = playerDataTable[callback.playerId]
    if data then
        local value = tonumber(callback.value)
        if value then
            data.settings.altitudeOffset = value
        end
    end
end

function toggleTimer(callback)
    local data = playerDataTable[callback.playerId]
    if not data then return end
    
    data.timer.running = not data.timer.running
    if data.timer.running then
        data.timer.start = data.time.global
        setUIValue(callback.playerId, "toggleTimer", "STOP")
    else
        data.timer.stop = data.time.global
        data.timer.current = data.timer.stop - data.timer.start
        data.timer.last = data.timer.current
        setUIValue(callback.playerId, "toggleTimer", "START")
        data.timer.current = 0
        data.time.localLast = data.time.localTime
    end
end

-- Calculations
function updateCalculations(playerId)
    local data = playerDataTable[playerId]
    if not data then return end
    
    local pos = tm.players.GetPlayerTransform(playerId).GetPosition()
    data.position.current = pos
    
    if data.states.speed or data.states.distance then
        local delta = calculateDistance(pos, data.position.last)
        data.metrics.distance = data.metrics.distance + delta
        data.metrics.speed = delta * Constants.UPDATE_RATE
        
        setUIValue(playerId, "distance", "distance: " .. formatDistance(data.metrics.distance))
        setUIValue(playerId, "speed", "speed: " .. formatSpeed(data.metrics.speed))
        data.position.last = pos
    end
    
    if data.states.gforce then
        data.metrics.gForce = (data.metrics.speed - data.metrics.lastSpeed) / Constants.GRAVITY * Constants.UPDATE_RATE
        setUIValue(playerId, "gforce", "G Force: " .. string.format("%.2f", data.metrics.gForce))
        data.metrics.lastSpeed = data.metrics.speed
    end
    
    if data.states.heading then
        data.metrics.heading = tm.players.GetPlayerTransform(playerId).GetRotation().y
        setUIValue(playerId, "heading", "heading: " .. math.floor(data.metrics.heading))
    end
    
    if data.states.altitude then
        setUIValue(playerId, "altitude", "altitude: " .. math.ceil(pos.y - data.settings.altitudeOffset) .. "m")
    end
    
    if data.states.position then
        setUIValue(playerId, "position", "position: " .. formatVector(pos))
    end
end

-- Formatting Helpers
function formatSpeed(mps)
    return string.format("%d mph %d kph %.2f m/s", 
        math.ceil(mps * 2.23693629),
        math.ceil(mps * 3.6),
        mps)
end

function formatDistance(meters)
    return string.format("%.2f mi / %.2f km / %.2f m",
        meters / 1609.3444,
        meters / 1000,
        meters)
end

function formatVector(vector)
    return string.format("x: %d, y: %d, z: %d",
        math.floor(vector.x),
        math.floor(vector.y),
        math.floor(vector.z))
end

function calculateDistance(pos1, pos2)
    return tm.vector3.op_Subtraction(pos1, pos2).Magnitude()
end
