function StartPedLoop(members)
    Citizen.CreateThread(function()
        while mySquad ~= nil and next(mySquad) ~= nil and hudOpened do
            UpdateMembersInfo(members)
            Citizen.Wait(100)
        end
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

---- gamer tags

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