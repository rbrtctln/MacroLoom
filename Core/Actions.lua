local API = MacroLoom
local units = { 'mouseover', 'target', 'targettarget' }
local function Clause(unit, spell, extra, ignoreTiming)
  return '[@' .. unit .. ',harm,alive,known:"' .. spell .. '",inrange:"' .. spell ..
    '",insight' .. (ignoreTiming and '' or ',nogcd,nocooldown:"' .. spell .. '"') .. (extra or '') .. '] ' .. spell
end
function API.Hostile(unit)
  return UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAttack('player', unit)
end

function API.HostileTarget()
  for i = 1, 3 do if API.Hostile(units[i]) then return units[i] end end
end

function API.HealTarget()
  for i = 1, 3 do
    local u = units[i]
    if UnitExists(u) and UnitIsFriend('player', u) and not UnitIsDeadOrGhost(u)
      and UnitCreatureType(u) ~= 'Totem' then return u end
  end
  if not UnitIsDeadOrGhost('player') then return 'player' end
end

function API.Busy()
  if not API.ExecutionReady() then return true end
  return not not CleveRoids.TestAction('/cast', '[selfcasting] Attack')
end

function API.PrepareHeal(spell)
  if not API.ExecutionReady() then return false end
  if API.Busy() or not API.HealTarget() or not CleveRoids.GetSpell(spell) then return false end
  if CleveRoids.ValidateCooldown(spell, false) then return false end
  -- Check the cheapest learned rank, because the preserved ladder chooses later.
  local _, _, base = string.find(spell, '^(.-)%(Rank')
  local low = CleveRoids.GetSpell((base or spell) .. '(Rank 1)') or CleveRoids.GetSpell(spell)
  if low and UnitMana('player') < CleveRoids.GetSpellCost(low.spellSlot, low.bookType, low.id) then return false end
  API.LeaveTravel()
  return true
end

function API.Ready(unit, spell, extra, ignoreTiming)
  if not API.ExecutionReady() then return false end
  if not unit or not API.Hostile(unit) then return false end
  local sp = CleveRoids.GetSpell(spell)
  if not sp or not sp.spellSlot then return false end
  if UnitMana('player') < CleveRoids.GetSpellCost(sp.spellSlot, sp.bookType, sp.id) then return false end
  return not not CleveRoids.TestAction('/cast', Clause(unit, spell, extra, ignoreTiming))
end

function API.OffensiveTarget(acquire)
  if not API.ExecutionReady() then return nil end
  local unit = API.HostileTarget()
  if unit or not acquire then return unit end
  RunBody('/retarget')
  if API.Hostile('target') then return 'target' end
end

function API.ScanMelee(spell, filters, scan, ignoreTiming)
  if not API.ExecutionReady() then return nil end
  local selected = API.Hostile('target') and CleveRoids.GetGUID('target')
  return API.SelectHostile(spell, function(u)
    if u == selected or API.Engaged(u) then
      return CleveRoids.hasUnitXP and (UnitXP('distanceBetween', 'player', u) or 9999) or 1
    end
  end, scan ~= false, ',meleerange' .. (filters or ''), ignoreTiming)
end

function API.CastOffensive(unit, spell, maintenance, extra, interrupt)
  if not API.ExecutionReady() then return nil end
  if maintenance and not interrupt and API.Maintain() then return end
  if not spell or not API.Ready(unit, spell, extra) then return end

  if API.OffensiveBlocked and API.OffensiveBlocked(spell) then return end
  local clause = Clause(unit, spell, extra)
  local body = '/firstaction\n'
  if interrupt then body = body .. '/stopcasting ' .. clause .. '\n' end
  RunBody(body .. '/cast ' .. clause .. '\n/nofirstaction')
end

function API.PartyAttention(unit)
  for i = 1, 4 do
    if UnitExists('party' .. i) and UnitIsUnit(unit .. 'target', 'party' .. i) then return true end
  end
  return false
end

function API.Engaged(unit)
  if not API.Hostile(unit) or not UnitAffectingCombat(unit) then return false end
  if UnitIsUnit(unit .. 'target', 'player') or API.PartyAttention(unit) then return true end
  for i = 1, 4 do
    if UnitExists('party' .. i) and UnitAffectingCombat('party' .. i)
      and UnitIsUnit('party' .. i .. 'target', unit) then return true end
  end
  return false
end

function API.Interrupting(unit)
  if not API.ExecutionReady() then return nil end
  local _, guid = UnitExists(unit)
  local C = CleveRoids
  local key = guid and C.NormalizeGUID and C.NormalizeGUID(guid)
  local cast = key and C.castTracking and C.castTracking[key]
  return cast and cast.endTime and cast.endTime > GetTime()
end

function API.SelectHostile(spell, score, scan, extra, ignoreTiming)
  if not API.ExecutionReady() then return nil end
  if not spell or not CleveRoids.GetSpell(spell) then return end
  local best, bestScore
  local seen = {}
  local function consider(unit)
    if not API.Hostile(unit) then return end
    local guid = CleveRoids.GetGUID(unit)
    if not guid or seen[guid] then return end
    seen[guid] = true
    local value = score(guid)
    if value and (not bestScore or value < bestScore) and API.Ready(guid, spell, extra, ignoreTiming) then
      best, bestScore = guid, value
    end
  end
  for i = 1, 3 do consider(units[i]) end
  if scan and CleveRoids.hasUnitXP then
    local original = UnitExists('target') and CleveRoids.GetGUID('target')
    for i = 1, 8 do consider('mark' .. i) end
    local first
    for i = 1, 50 do
      if not UnitXP('target', 'nextEnemyConsideringDistance') or not UnitExists('target') then break end
      local guid = CleveRoids.GetGUID('target')
      if not guid or guid == first then break end
      first = first or guid
      consider('target')
    end
    if original then TargetUnit(original) else ClearTarget() end
  end
  return best
end

function API.StartSelectedAttack(unit)
  if unit and API.Hostile('target') and UnitIsUnit(unit, 'target') and not API.Busy() then
    RunBody('/startattack [@target,harm,alive,noselfcasting]')
  end
end
