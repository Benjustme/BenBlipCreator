local ESX = exports['es_extended']:getSharedObject()

local PlayerData = {}
local cache = {}          -- [id] = row
local created = {}        -- [id] = blipHandle
local previewBlip = nil

local function GetJob()
  if PlayerData and PlayerData.job then return PlayerData.job end
  return nil
end

local function CanSee(row)
  if not row then return false end
  if row.enabled == 0 or row.enabled == false then return false end

  local vis = row.visibility or 'all'
  if vis == 'all' then return true end

  local job = GetJob()
  if not job or not row.job then return false end

  if vis == 'job' then
    return job.name == row.job
  end

  if vis == 'job_grade' then
    if job.name ~= row.job then return false end
    local grade = job.grade or 0
    local req = row.job_grade or 0
    if Config.JobGradeMode == 'exact' then
      return grade == req
    end
    return grade >= req
  end

  return false
end

local function RemoveOne(id)
  local h = created[id]
  if h then
    RemoveBlip(h)
    created[id] = nil
  end
end

local function CreateOrUpdateOne(row)
  local id = row.id
  if not id then return end

  if not CanSee(row) then
    RemoveOne(id)
    return
  end

  local h = created[id]
  if not h then
    h = AddBlipForCoord(row.x + 0.0, row.y + 0.0, row.z + 0.0)
    created[id] = h
  else
    SetBlipCoords(h, row.x + 0.0, row.y + 0.0, row.z + 0.0)
  end

  SetBlipSprite(h, tonumber(row.sprite) or 1)
  SetBlipColour(h, tonumber(row.color) or 0)
  SetBlipScale(h, (tonumber(row.scale) or 0.9) + 0.0)
  SetBlipDisplay(h, tonumber(row.display) or 4)
  SetBlipAsShortRange(h, row.short_range == 1 or row.short_range == true)

  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString(row.label or 'Blip')
  EndTextCommandSetBlipName(h)
end

local function RebuildAll()
  for _, h in pairs(created) do
    RemoveBlip(h)
  end
  created = {}

  for _, row in pairs(cache) do
    CreateOrUpdateOne(row)
  end
end

local function LoadEnabledFromServer()
  local res = lib.callback.await('ben_blips:getEnabled', false)
  if not res or not res.ok then
    return
  end

  cache = {}
  for _, row in ipairs(res.data or {}) do
    cache[row.id] = row
  end

  RebuildAll()
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
  LoadEnabledFromServer()
end)

RegisterNetEvent('esx:setJob', function(job)
  PlayerData.job = job
  RebuildAll()
end)

AddEventHandler('onClientResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  PlayerData = ESX.GetPlayerData()
  LoadEnabledFromServer()
end)

RegisterNetEvent('ben_blips:syncCreate', function(row)
  cache[row.id] = row
  CreateOrUpdateOne(row)
end)

RegisterNetEvent('ben_blips:syncUpdate', function(row)
  cache[row.id] = row
  CreateOrUpdateOne(row)
end)

RegisterNetEvent('ben_blips:syncDelete', function(id)
  cache[id] = nil
  RemoveOne(id)
end)

-- NUI
RegisterNUICallback('close', function(_, cb)
  SetNuiFocus(false, false)
  if previewBlip then
    RemoveBlip(previewBlip)
    previewBlip = nil
  end
  cb(true)
end)

RegisterNUICallback('adminGetAll', function(_, cb)
  cb(lib.callback.await('ben_blips:getAllAdmin', false))
end)

RegisterNUICallback('create', function(data, cb)
  cb(lib.callback.await('ben_blips:create', false, data))
end)

RegisterNUICallback('update', function(data, cb)
  cb(lib.callback.await('ben_blips:update', false, data))
end)

RegisterNUICallback('delete', function(data, cb)
  cb(lib.callback.await('ben_blips:delete', false, data.id))
end)

RegisterNUICallback('toggle', function(data, cb)
  cb(lib.callback.await('ben_blips:toggle', false, data.id, data.enabled))
end)

RegisterNUICallback('useMyPos', function(_, cb)
  local coords = GetEntityCoords(PlayerPedId())
  cb({ x = coords.x, y = coords.y, z = coords.z })
end)

RegisterNUICallback('preview', function(data, cb)
  local coords = GetEntityCoords(PlayerPedId())
  if not previewBlip then
    previewBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
  else
    SetBlipCoords(previewBlip, coords.x, coords.y, coords.z)
  end

  SetBlipSprite(previewBlip, tonumber(data.sprite) or 1)
  SetBlipColour(previewBlip, tonumber(data.color) or 0)
  SetBlipScale(previewBlip, (tonumber(data.scale) or 0.9) + 0.0)
  SetBlipDisplay(previewBlip, tonumber(data.display) or 4)
  SetBlipAsShortRange(previewBlip, data.short_range == true)

  BeginTextCommandSetBlipName('STRING')
  AddTextComponentString(data.label or 'Preview')
  EndTextCommandSetBlipName(previewBlip)

  cb(true)
end)

RegisterNUICallback('getReferenceData', function(_, cb)
  cb(lib.callback.await('ben_blips:getReferenceData', false))
end)

RegisterNUICallback('getLocale', function(_, cb)
  local lang = Config.Locale or 'en'
  cb({ ok = true, locale = lang, dict = Locales[lang] or Locales['en'] })
end)

RegisterNetEvent('ben_blips:openUI', function()
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'open' })
end)
