local menuOpened = false
hudOpened = false
local hudSetting = true
local Squads = {}
mySquad = {}

local mpGamerTags = {}
local mpGamerTagSettings = {}

local gtComponent = {
    GAMER_NAME = 0,
    CREW_TAG = 1,
    healthArmour = 2,
    BIG_TEXT = 3,
    AUDIO_ICON = 4,
    MP_USING_MENU = 5,
    MP_PASSIVE_MODE = 6,
    WANTED_STARS = 7,
    MP_DRIVER = 8,
    MP_CO_DRIVER = 9,
    MP_TAGGED = 10,
    GAMER_NAME_NEARBY = 11,
    ARROW = 12,
    MP_PACKAGES = 13,
    INV_IF_PED_FOLLOWING = 14,
    RANK_TEXT = 15,
    MP_TYPING = 16
}

Citizen.CreateThread(function()
    TriggerServerEvent("gfx-squad:GetSquads")
end)

local _in = Citizen.InvokeNative

local function FormatStackTrace()
	return _in(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())
end

RegisterNetEvent("gfx-squad:UpdateSquads")
AddEventHandler("gfx-squad:UpdateSquads", function(src, squadid, key, value, index, left)
    if not squadid then return end
    if left then
        if squadid == mySquad.id then
            RemoveGamerTags()
            RemoveSquadBlips(index)    
        end

        if src == GetPlayerServerId(PlayerId()) then
            RemoveGamerTags()
            RemoveSquadBlips()
            LoadSquad(true)
            DisplayHud(false)
            mySquad = {}
        end
    end
    
    
    if squadid == mySquad.id or src == GetPlayerServerId(PlayerId()) then
        UpdateMySquad(key, value, index, squadid)
        Citizen.Wait(150)
        UpdateMembersInfo(mySquad.members)
        AddSquadBlip()
        LoadSquad(true)
        DisplayHud(true)
        StartPedLoop(mySquad.members)
    end 

    UpdateSquads(squadid, key, value, index)
    LoadSquad(true)
end)

RegisterNetEvent("gfx-squad:client:GetSquads", function(s)
    Squads = s
end)

function UpdateSquads(squadid, key, value, index)
    -- print(FormatStackTrace())
    if key then
        if index then
            Squads[squadid][key][index] = value
        else
            Squads[squadid][key] = value
        end
    else
        Squads[squadid] = value
    end

    if menuOpened and not HasSquad() then
        LoadSquad(true)
    end
end

function UpdateMySquad(key, value, index, squadid)
    if key then
        if index then
            if value == nil then
                RemoveGamerTags()
                RemoveSquadBlips()
            end
            if mySquad[key] then
                mySquad[key][index] = value
            end
        else
            mySquad[key] = value
        end
    else
        if value == nil then
            RemoveSquadBlips()
            DisplayHud(false)
        end
        value = value == nil and {} or value
        mySquad = value
    end
    if mySquad and next(mySquad) ~= nil and mySquad.id == nil then
        mySquad.id = squadid
        DisplayHud(true)
        StartPedLoop(mySquad.members)
        StartNameLoop()
    end
end

RegisterNUICallback("closeUI", function()
    SetNuiFocus(false, false)
    LoadSquad(false)
end)

RegisterKeyMapping(Config.MenuCommand, "Squad", "keyboard", "J")
RegisterCommand(Config.MenuCommand, function()
    SetNuiFocus(true, true)
    LoadSquad(true, true)
end)

function LoadSquad(bool, force)
    DisplayRadar(true)    
    menuOpened = force and bool
    SendNUIMessage({
        type = "displayMenu",
        bool = bool,
        force = force,
        menu = not HasSquad() and "public" or "mysquad",
        squad = not HasSquad() and Squads or mySquad,
        source = GetPlayerServerId(PlayerId())
    })
end

function DisplayHud(bool)
    hudOpened = bool and hudSetting
    SendNUIMessage({
        type = "displayHud",
        bool = bool and hudSetting,
        members = mySquad.members
    })
end

function HasSquad()
    return not (mySquad and next(mySquad) == nil and mySquad.id == nil)
end

RegisterNUICallback("CreateNew", function(data, cb)
    if not HasSquad() then
        TriggerServerEvent("gfx-squad:Create")
    end
end)

RegisterNUICallback("Leave", function(data, cb)
    if HasSquad() then
        TriggerServerEvent("gfx-squad:Leave")
    end
end)

RegisterNUICallback("Kick", function(data, cb)
    if HasSquad() then
        TriggerServerEvent("gfx-squad:Kick", tonumber(data.id))
    end
end)

RegisterNUICallback("DeleteSquad", function(data, cb)
    if HasSquad() then
        TriggerServerEvent("gfx-squad:Delete")
    end
end)

RegisterNUICallback("HudStatus", function(data, cb)
    hudSetting = data.hud
    DisplayHud(data.hud)
    if data.hud then
        StartPedLoop(mySquad.members)
    end
end)

RegisterNUICallback("PrivateStatus", function(data, cb)
    TriggerServerEvent("gfx-squad:PrivateStatus", data.bool)
end)

RegisterNUICallback("Join", function(data, cb)
    if not HasSquad() then
        TriggerServerEvent("gfx-squad:JoinSquad", data.id)
    end
end)

function AddSquadBlip()
    if not Config.MemberBlips then return end
    if mySquad.id then
        for i = 1, #mySquad.members do
            local v = mySquad.members[i]
            if v then
                if not v.blip then
                    if v.source ~= GetPlayerServerId(PlayerId()) then
                        local blip = AddBlipForEntity(GetPlayerPed(GetPlayerFromServerId(v.source)))
                        SetBlipSprite(blip, 1)
                        ShowFriendIndicatorOnBlip(blip, true)
                        SetBlipColour(blip, 37)
                        SetBlipScale(blip, 0.75)
                        ShowHeadingIndicatorOnBlip(blip, true)
                        SetBlipShowCone(blip, true)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString(v.name)
                        EndTextCommandSetBlipName(blip)
                        mySquad.members[i].blip = blip
                    end
                end
            end
        end
    end
end

function RemoveSquadBlips(index)
    if not mySquad.members then return print("no sq") end
    print("rem", index, json.encode(mySquad.members))
    if index then
        RemoveBlip(mySquad.members[index].blip)
        mySquad.members[index].blip = nil
    else
        for i = 1, #mySquad.members do
            local v = mySquad.members[i]
            if v then
                if v.blip then
                    RemoveBlip(v.blip)
                    mySquad.members[i].blip = nil
                end
            end   
        end
    end
end

local pi = math.pi
function RotationToDirection(rotation)
	local adjustedRotation = { 
		x = (pi / 180) * rotation.x, 
		y = (pi / 180) * rotation.y, 
		z = (pi / 180) * rotation.z 
	}
	local direction = {
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

function RayCastGamePlayCamera(distance)
	local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination = { 
		x = cameraCoord.x + direction.x * distance, 
		y = cameraCoord.y + direction.y * distance, 
		z = cameraCoord.z + direction.z * distance 
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, -1, 1))
	return b, c, e
end

local markerCounter = 0
RegisterKeyMapping("mark", "Mark the enemy", "keyboard", "Z")
-- exports["dz_base"]:registerKeyMapping("", "Game", "Mark the enemy", "mark", "", "Z")
RegisterCommand("mark", function()
    local hit, coords, entity = RayCastGamePlayCamera(500.0)
    -- if #mySquad.members > 0 and markerCounter < 5 then
        if hit ~= 0 then
            markerCounter = markerCounter + 1
            TriggerServerEvent("dz_crews:server:SquadMark", coords)
        end
    -- end
end)

RegisterNetEvent("dz_crews:client:SquadMark")
AddEventHandler("dz_crews:client:SquadMark", function(mark)
    local counter = Config.MarkerTimer * 100
    Citizen.CreateThread(function()
        while counter > 0 do
            DrawMarker(Config.MarkerType, mark.coords.x, mark.coords.y, mark.coords.z + 0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, 255, 0, 0, 255, true, true, 2, false, nil, nil, false)
            counter = counter - 1
            Citizen.Wait(1)
        end
        if mark.source == GetPlayerServerId(PlayerId()) then
            markerCounter = markerCounter - 1
        end
    end)
end)

local threadStarted = false
function StartPedLoop(members)
    if threadStarted then return end
    Citizen.CreateThread(function()
        print(mySquad, next(mySquad), hudOpened)
        threadStarted = true
        while mySquad ~= nil and next(mySquad) ~= nil and hudOpened do
            UpdateMembersInfo(mySquad.members)
            Citizen.Wait(100)
        end
        threadStarted = false
    end)
end

function UpdateMembersInfo(members)
    if members then
        for i = 1, #members do
            local v = members[i]
            if v then
                local ped = GetPlayerPed(GetPlayerFromServerId(v.source))
                local health = GetEntityHealth(ped)
                local armor = GetPedArmour(ped)
                local maxHealth = GetEntityMaxHealth(ped)
                mySquad.members[i].hudData = {
                    armor = armor,
                    health = health,
                    maxHealth = maxHealth
                }
            end
            DisplayHud(true)
        end
    end
end

local mySquadHash

function SetRelationDamage(id)
    if id and (mySquadHash == nil or not DoesRelationshipGroupExist(mySquadHash)) then
        local retval, hash = AddRelationshipGroup(("squad_%s"):format(id))
        SetPedRelationshipGroupHash(PlayerPedId(), hash)
        SetEntityCanBeDamagedByRelationshipGroup(PlayerPedId(), false,  hash)
        mySquadHash = hash
    else
        SetPedRelationshipGroupHash(PlayerPedId(), mySquadHash)
        SetEntityCanBeDamagedByRelationshipGroup(PlayerPedId(), false,  mySquadHash)
    end
    return mySquadHash
end

function StartRelationLoop(id)
    Citizen.CreateThread(function()
        local hash = SetRelationDamage(id)
        while mySquadHash ~= nil do
            Citizen.Wait(2000)
            SetRelationDamage()
        end
        if DoesRelationshipGroupExist(mySquadHash) then
            SetPedRelationshipGroupHash(PlayerPedId(), 0x6F0783F5)
            SetEntityCanBeDamagedByRelationshipGroup(PlayerPedId(), true,  mySquadHash)
            RemoveRelationshipGroup(mySquadHash)
            mySquadHash = nil
        end
    end)
end

RegisterNetEvent("gfx-squad:AddRelationShip")
AddEventHandler("gfx-squad:AddRelationShip", function(id)
    if Config.FriendlyFire then return end
    StartRelationLoop(id)
end)

RegisterNetEvent("gfx-squad:RemoveRelationShip")
AddEventHandler("gfx-squad:RemoveRelationShip", function()
    if Config.FriendlyFire then return end
    if DoesRelationshipGroupExist(mySquadHash) then
        SetPedRelationshipGroupHash(PlayerPedId(), 0x6F0783F5)
        SetEntityCanBeDamagedByRelationshipGroup(PlayerPedId(), true,  mySquadHash)
        RemoveRelationshipGroup(mySquadHash)
        mySquadHash = nil
    end
    RemoveGamerTags()
end)


local function makeSettings()
    return {
        alphas = {},
        colors = {},
        healthColor = false,
        toggles = {},
        wantedLevel = false
    }
end

function StartNameLoop()
    if not Config.GamerTags then return end
    Citizen.CreateThread(function()
        while mySquad and mySquad.members do
            Citizen.Wait(50)
            if mySquad.members then
                for _, v in pairs(mySquad.members) do
                    local data = {
                        id = v.source,
                        name = v.name
                    }
                    RenderNames(data, true)
                end
            end
        end
        RemoveGamerTags()
    end)
end

function RenderNames(v, isSquad)
    local i = GetPlayerFromServerId(v.id)
    if NetworkIsPlayerActive(i) and i ~= PlayerId() then
        if i ~= -1 then
            -- get their ped
            local ped = GetPlayerPed(i)
            local pedCoords = GetEntityCoords(ped)
            local health = GetEntityHealth(ped) - 100
            health = health >= 0 and health or GetEntityHealth(ped)
            if not mpGamerTagSettings[i] then
                mpGamerTagSettings[i] = makeSettings()
            end
            if not mpGamerTags[i] or mpGamerTags[i].ped ~= ped or not IsMpGamerTagActive(mpGamerTags[i].tag) then
                local nameTag = v.name
                if mpGamerTags[i] then
                    RemoveMpGamerTag(mpGamerTags[i].tag)
                end
                mpGamerTags[i] = {
                    tag = CreateMpGamerTag(GetPlayerPed(i), nameTag, false, false, '', 0),
                    ped = ped
                }
            end
            local tag = mpGamerTags[i].tag
            if mpGamerTagSettings[i].rename then
                SetMpGamerTagName(tag, v.name)
                mpGamerTagSettings[i].rename = nil
            end

            local distance = #(pedCoords - GetEntityCoords(ped))
            if distance < 100 then
                SetMpGamerTagVisibility(tag, gtComponent.GAMER_NAME, true)
                SetMpGamerTagVisibility(tag, gtComponent.healthArmour, true)
                -- SetMpGamerTagVisibility(tag, gtComponent.AUDIO_ICON, NetworkIsPlayerTalking(i))
                -- SetMpGamerTagAlpha(tag, gtComponent.AUDIO_ICON, 255)
                SetMpGamerTagAlpha(tag, gtComponent.healthArmour, 255)

                local settings = mpGamerTagSettings[i]
                for k, v in pairs(settings.toggles) do
                    SetMpGamerTagVisibility(tag, gtComponent[k], v)
                end

                for k, v in pairs(settings.alphas) do
                    SetMpGamerTagAlpha(tag, gtComponent[k], v)
                end

                if health > 66 then
                    SetMpGamerTagHealthBarColour(tag, 18)
                elseif health > 33 then
                    SetMpGamerTagHealthBarColour(tag, 12)
                elseif health > 0 then -- 6 - kırmızı, 8 - bordo, 12 - sarı, 18 - yeşil
                    SetMpGamerTagHealthBarColour(tag, 6)
                end
                if isSquad then
                    SetMpGamerTagColour(tag, 0, 9)
                end
            else
                SetMpGamerTagVisibility(tag, gtComponent.GAMER_NAME, false)
                SetMpGamerTagVisibility(tag, gtComponent.healthArmour, false)
            end
        end
    end
end

function RemoveGamerTags()
    for k,v in pairs(mpGamerTags) do
        RemoveMpGamerTag(v.tag)
    end
    mpGamerTags = {}
end

AddEventHandler("onResourceStop", function(name)
    if name == GetCurrentResourceName() then
        RemoveGamerTags()

        if DoesRelationshipGroupExist(mySquadHash) then
            SetPedRelationshipGroupHash(PlayerPedId(), 0x6F0783F5)
            SetEntityCanBeDamagedByRelationshipGroup(PlayerPedId(), true,  mySquadHash)
            RemoveRelationshipGroup(mySquadHash)
            mySquadHash = nil
        end
    end
end)


RegisterCommand("removehp", function(source, args)
    local ped = PlayerPedId()
    SetEntityHealth(ped, math.random(101, 200))
end)