local ESX = exports['es_extended']:getSharedObject()

-- Reference cache (blips/colors from docs)
local CachedRefs = { blips = {}, colors = {}, ready = false }

local function HttpGet(url)
  local p = promise.new()
  PerformHttpRequest(url, function(status, body)
    if status ~= 200 or not body then
      p:resolve(nil)
      return
    end
    p:resolve(body)
  end, 'GET')
  return Citizen.Await(p)
end

local function ParseBlips(html)
  local out = {}

  local s = html:find('id="blips"') or html:find('>Blips<') or 1
  local chunk = html:sub(s, math.min(#html, s + 600000))
  local h = chunk:gsub('\r', ' '):gsub('\n', ' ')

  local function normUrl(icon)
    if not icon or icon == '' then return nil end
    icon = icon:gsub('&amp;', '&')
    if icon:sub(1, 2) == '//' then icon = 'https:' .. icon end
    if icon:sub(1, 1) == '/' then icon = 'https://docs.fivem.net' .. icon end
    if not icon:match('^https?://') then icon = 'https://docs.fivem.net/' .. icon end
    return icon
  end

  for icon, id, name in h:gmatch('<img[^>]-src="([^"]+)"[^>]->.-<strong>%s*(%d+)%s*</strong>%s*<br%s*/?>%s*([^<]+)') do
    id = tonumber(id)
    if id and name then
      name = name:gsub('%s+', ' '):gsub('^%s+',''):gsub('%s+$','')
      out[#out+1] = { id = id, name = name, icon = normUrl(icon) }
    end
  end

  local seen, clean = {}, {}
  for _, b in ipairs(out) do
    if b.id and not seen[b.id] then
      seen[b.id] = true
      clean[#clean+1] = b
    end
  end

  table.sort(clean, function(a,b) return a.id < b.id end)
  return clean
end

local function ParseColors(html)
  local out = {}

  local s = html:find('id="blip%-colors"') or html:find('blip%-colors') or 1
  local chunk = html:sub(s, math.min(#html, s + 250000))
  local h = chunk:gsub('\r', ' '):gsub('\n', ' ')

  local function cleanText(t)
    return (t or '')
      :gsub('&amp;', '&')
      :gsub('&#39;', "'")
      :gsub('&quot;', '"')
      :gsub('%s+', ' ')
      :gsub('^%s+','')
      :gsub('%s+$','')
  end

  for hex, id, name in h:gmatch('class="blip bcolor".-background%-color:%s*(#[0-9a-fA-F]+).-<strong>%s*(%d+)%s*</strong>%s*<br%s*/?>%s*([^<]+)') do
    id = tonumber(id)
    name = cleanText(name)
    if id and name ~= '' then
      out[#out+1] = { id = id, name = name, hex = hex }
    end
  end

  local seen, clean = {}, {}
  for _, c in ipairs(out) do
    if c.id and not seen[c.id] then
      seen[c.id] = true
      clean[#clean+1] = c
    end
  end

  table.sort(clean, function(a,b) return a.id < b.id end)
  return clean
end

CreateThread(function()
  local blipsHtml = HttpGet('https://docs.fivem.net/docs/game-references/blips/#blips')
  local colorsHtml = HttpGet('https://docs.fivem.net/docs/game-references/blips/#blip-colors')

  if blipsHtml then CachedRefs.blips = ParseBlips(blipsHtml) end
  if colorsHtml then CachedRefs.colors = ParseColors(colorsHtml) end

  CachedRefs.ready = true

  -- (Optional) Keep logs minimal:
  print(('[ben_blipcreator] refs loaded: blips=%d colors=%d'):format(#CachedRefs.blips, #CachedRefs.colors))
end)

lib.callback.register('ben_blips:getReferenceData', function(source)
  return { ok = true, ready = CachedRefs.ready, blips = CachedRefs.blips, colors = CachedRefs.colors }
end)

local function IsAdmin(src)
  local xPlayer = ESX.GetPlayerFromId(src)
  if not xPlayer then return false end

  local group = xPlayer.getGroup()
  if Config.AdminGroups[group] then return true end

  if Config.AllowAce and IsPlayerAceAllowed(src, Config.AcePerm) then
    return true
  end

  return false
end

-- player: enabled blips only
lib.callback.register('ben_blips:getEnabled', function(source)
  local rows = MySQL.query.await('SELECT * FROM ben_blips WHERE enabled = 1', {})
  return { ok = true, data = rows }
end)

-- admin: all blips
lib.callback.register('ben_blips:getAllAdmin', function(source)
  if not IsAdmin(source) then return { ok=false, error='no_permission' } end
  local rows = MySQL.query.await('SELECT * FROM ben_blips', {})
  return { ok=true, data=rows }
end)

lib.callback.register('ben_blips:create', function(source, payload)
  if not IsAdmin(source) then return { ok=false, error='no_permission' } end

  local xPlayer = ESX.GetPlayerFromId(source)
  local createdBy = xPlayer and xPlayer.identifier or nil

  if not payload.name or payload.name == '' then return { ok=false, error='missing_name' } end
  if not payload.label or payload.label == '' then return { ok=false, error='missing_label' } end

  local ok, id = pcall(function()
    return MySQL.insert.await([[
      INSERT INTO ben_blips
      (name, label, sprite, color, scale, display, short_range, enabled, x, y, z, visibility, job, job_grade, created_by)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]],
    {
      payload.name,
      payload.label,
      tonumber(payload.sprite) or 1,
      tonumber(payload.color) or 0,
      tonumber(payload.scale) or 0.9,
      tonumber(payload.display) or 4,
      payload.short_range and 1 or 0,
      payload.enabled and 1 or 0,
      tonumber(payload.x) or 0.0,
      tonumber(payload.y) or 0.0,
      tonumber(payload.z) or 0.0,
      payload.visibility or 'all',
      payload.job,
      payload.job_grade and tonumber(payload.job_grade) or nil,
      createdBy
    })
  end)

  if not ok or not id then
    return { ok=false, error='db_insert_failed_or_duplicate_name' }
  end

  local row = MySQL.single.await('SELECT * FROM ben_blips WHERE id = ?', { id })
  TriggerClientEvent('ben_blips:syncCreate', -1, row)
  return { ok=true, data=row }
end)

lib.callback.register('ben_blips:update', function(source, payload)
  if not IsAdmin(source) then return { ok=false, error='no_permission' } end
  if not payload.id then return { ok=false, error='missing_id' } end

  local okUpdate = MySQL.update.await([[
    UPDATE ben_blips SET
      name = ?,
      label = ?,
      sprite = ?,
      color = ?,
      scale = ?,
      display = ?,
      short_range = ?,
      enabled = ?,
      x = ?, y = ?, z = ?,
      visibility = ?,
      job = ?,
      job_grade = ?
    WHERE id = ?
  ]],
  {
    payload.name,
    payload.label,
    tonumber(payload.sprite) or 1,
    tonumber(payload.color) or 0,
    tonumber(payload.scale) or 0.9,
    tonumber(payload.display) or 4,
    payload.short_range and 1 or 0,
    payload.enabled and 1 or 0,
    tonumber(payload.x) or 0.0,
    tonumber(payload.y) or 0.0,
    tonumber(payload.z) or 0.0,
    payload.visibility or 'all',
    payload.job,
    payload.job_grade and tonumber(payload.job_grade) or nil,
    tonumber(payload.id)
  })

  if not okUpdate then return { ok=false, error='db_update_failed' } end

  local row = MySQL.single.await('SELECT * FROM ben_blips WHERE id = ?', { payload.id })
  TriggerClientEvent('ben_blips:syncUpdate', -1, row)
  return { ok=true, data=row }
end)

lib.callback.register('ben_blips:delete', function(source, id)
  if not IsAdmin(source) then return { ok=false, error='no_permission' } end
  if not id then return { ok=false, error='missing_id' } end

  MySQL.query.await('DELETE FROM ben_blips WHERE id = ?', { tonumber(id) })
  TriggerClientEvent('ben_blips:syncDelete', -1, tonumber(id))
  return { ok=true }
end)

lib.callback.register('ben_blips:toggle', function(source, id, enabled)
  if not IsAdmin(source) then return { ok=false, error='no_permission' } end
  if not id then return { ok=false, error='missing_id' } end

  MySQL.update.await('UPDATE ben_blips SET enabled = ? WHERE id = ?', { enabled and 1 or 0, tonumber(id) })
  local row = MySQL.single.await('SELECT * FROM ben_blips WHERE id = ?', { tonumber(id) })

  TriggerClientEvent('ben_blips:syncUpdate', -1, row)
  return { ok=true, data=row }
end)

local function PrintBanner()
  local resName = GetCurrentResourceName()
  local version = GetResourceMetadata(resName, 'version', 0) or '1.1.0'

  print('^5================================================================================^7')
  print(('^5[ ^7%s ^5]^7  ^7Ingame Blip Creator (ESX Legacy)'):format('BenBlipCreator'))
  print(('^5[Author]^7   : ^5benjustme^7'))
  print(('^5[Version]^7  : ^3%s^7'):format(version))
  print(('^5[License]^7  : ^2GPL-3.0-or-later^7'))
  print(('^5[Free]^7     : ^2Free for all^7 (always)'))
  print(('^5[Source]^7   : ^2Open Source^7 (fork/modify allowed)'))
  print(('^5[Command]^7  : ^7/%s^7'):format(Config.Command or 'blips'))
  print('^5================================================================================^7')
end

CreateThread(function()
  Wait(500)
  PrintBanner()
end)

local FORCE_DENY_OPEN = false -- nur zum testen, danach wieder false

RegisterCommand(Config.Command, function(source)
  if source == 0 then
    print('[BenBlipCreator] This command can only be used ingame.')
    return
  end
 
if FORCE_DENY_OPEN then
  TriggerClientEvent('ox_lib:notify', source, {
    title = 'BenBlipCreator',
    description = 'TEST: blocked (simulate non-admin)',
    type = 'error'
  })
  return
end

  if not IsAdmin(source) then
    -- optional: notify (ox_lib)
    TriggerClientEvent('ox_lib:notify', source, {
      title = 'BenBlipCreator',
      description = 'No permission.',
      type = 'error'
    })
    return
  end

  TriggerClientEvent('ben_blips:openUI', source)
end, false)
