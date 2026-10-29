-- Undiscounted installed costs. Never assume Clearcasting's two 60% charges.
local esCosts = {30, 50, 85, 145, 240, 345, 450}
function SoakedESRank(interrupt, maximum)
  if maximum then return 'Earth Shock' end -- highest learned, no reserve gate
  local A = SoakedMacroBridge
  local reserve = esCosts[1]
  local heal = CleveRoids.GetSpell('Lesser Healing Wave') or CleveRoids.GetSpell('Healing Wave')
  if heal and A.HealBaseCosts[heal.id] then reserve = reserve + A.HealBaseCosts[heal.id] end
  -- Unpowered kicks conserve mana; empowerment is reserved for Rank 5.
  if A.StormstrikeBuff() then
    if CleveRoids.GetSpell('Earth Shock(Rank 5)')
      and UnitMana('player') >= esCosts[5] + (interrupt and 0 or reserve) then
      return 'Earth Shock(Rank 5)'
    end
    return -- Never silently spend empowerment on a lower rank.
  elseif interrupt then
    if CleveRoids.GetSpell('Earth Shock(Rank 1)') and UnitMana('player') >= esCosts[1] then
      return 'Earth Shock(Rank 1)'
    end
    return
  end
  -- Rank 4 is both first learned after 20 and midpoint of the seven-rank ladder.
  local ceiling = 4
  while ceiling > 1 and not CleveRoids.GetSpell('Earth Shock(Rank ' .. ceiling .. ')') do ceiling = ceiling - 1 end
  local spell = 'Earth Shock(Rank ' .. ceiling .. ')'
  if CleveRoids.GetSpell(spell) and UnitMana('player') >= esCosts[ceiling] + reserve then return spell end
  if interrupt and CleveRoids.GetSpell('Earth Shock(Rank 1)') and UnitMana('player') >= esCosts[1] then
    return 'Earth Shock(Rank 1)'
  end
end
-- Shared target rules; melee requests only kick/threat, ES may also finish.
function SoakedTankShockChoice(scan, maximum, finish)
  local A = SoakedMacroBridge
  local spell = SoakedESRank(true, maximum)
  local unit = spell and A.SelectHostile(spell, function(u)
    if A.Engaged(u) and A.Interrupting(u) then return 1 end
  end, scan)
  if unit then return unit, spell, true end
  spell = SoakedESRank(false, maximum)
  if not spell then return end
  unit = A.SelectHostile(spell, function(u)
    if not A.Engaged(u) then return end
    if A.LostThreat(u) then return 1 end
    if finish and A.StormstrikeBuff() and UnitHealthMax(u) > 0 and UnitHealth(u) / UnitHealthMax(u) <= .20 then
      return 2 + UnitHealth(u) / UnitHealthMax(u)
    end
  end, scan)
  if unit then return unit, spell, false end
end
-- Level-39 button policy; the DPME helper/tables remain dormant for level 59.
-- Keep legacy SoakedESRank/SoakedTankShockChoice intact for melee and modifiers.
function SoakedESNomodRank(interrupt, offensive)
  local A = SoakedMacroBridge
  local reserve = esCosts[1]
  local heal = CleveRoids.GetSpell('Lesser Healing Wave') or CleveRoids.GetSpell('Healing Wave')
  if heal and A.HealBaseCosts[heal.id] then reserve = reserve + A.HealBaseCosts[heal.id] end
  -- Unpowered kicks conserve mana; empowerment is reserved for Rank 5.
  if A.StormstrikeBuff() then
    if CleveRoids.GetSpell('Earth Shock(Rank 5)')
      and UnitMana('player') >= esCosts[5] + (interrupt and 0 or reserve) then
      return 'Earth Shock(Rank 5)'
    end
    return -- Never silently spend empowerment on a lower rank.
  elseif interrupt then
    if CleveRoids.GetSpell('Earth Shock(Rank 1)') and UnitMana('player') >= esCosts[1] then
      return 'Earth Shock(Rank 1)'
    end
    return
  end
  local ceiling = 4 -- No-mod never exceeds Rank 4; emergency downranks preserved.
  for rank = ceiling, 1, -1 do
    local spell = 'Earth Shock(Rank ' .. rank .. ')'
    if CleveRoids.GetSpell(spell) and UnitMana('player') >= esCosts[rank] + reserve then return spell end
  end
  -- Interrupt authorization must never be vetoed by the emergency reserve.
  if interrupt and CleveRoids.GetSpell('Earth Shock(Rank 1)') and UnitMana('player') >= esCosts[1] then
    return 'Earth Shock(Rank 1)'
  end
end
function SoakedESEconomyChoice(acquire, urgentOnly)
  local A = SoakedMacroBridge
  local spell = SoakedESNomodRank(true, false)
  local function kick(u)
    if A.Engaged(u) and A.Interrupting(u) then return 1 end
  end
  local unit = spell and A.SelectHostile(spell, kick, acquire)
  if unit then return unit, spell, true end
  spell = SoakedESNomodRank(false, false)
  if not spell then return end
  if A.TankState() then
    unit = A.SelectHostile(spell, function(u)
      if A.LostThreat(u) then return 1 end
    end, acquire)
    if unit then return unit, spell, false end
  end
  if urgentOnly or not CleveRoids.GetSpell('Stormstrike') or not A.StormstrikeBuff() then return end
  -- Explicit offensive units only; never scan unrelated enemies to spend stacks.
  if A.Ready('mouseover', spell) then return 'mouseover', spell, false end
  if A.Ready('target', spell) then return 'target', spell, false end
end
function SoakedESChoice(acquire)
  local A = SoakedMacroBridge
  if IsAltKeyDown() then
    -- Explicit max rank: mouseover, then selected target; no defensive scan override.
    if A.Ready('mouseover', 'Earth Shock') then
      return 'mouseover', 'Earth Shock', A.Interrupting('mouseover') and true or false
    end
    if A.Ready('target', 'Earth Shock') then
      return 'target', 'Earth Shock', A.Interrupting('target') and true or false
    end
    return
  end
  if not IsShiftKeyDown() and not IsControlKeyDown() then
    return SoakedESEconomyChoice(acquire)
  end
  if A.TankState() then return SoakedTankShockChoice(acquire, false, true) end
  local spell = SoakedESRank(true, false)
  local unit = spell and A.SelectHostile(spell, function(u)
    if A.Engaged(u) and A.Interrupting(u) then return 1 end
  end, acquire)
  if unit then return unit, spell, true end
  if A.StormstrikeBuff() then return A.OffensiveTarget(acquire), SoakedESRank(false, false), false end
end
function SoakedESExec()
  local A = SoakedMacroBridge
  local unit, spell, interrupt = SoakedESChoice(true)
  -- Preserve interrupt and engaged party-threat recovery priority.
  local urgent = interrupt or (unit and A.LostThreat(unit))
  local spending = unit and spell and A.StormstrikeBuff()
  if not urgent and not spending and A.Maintain() then return end
  if not spell or (A.Busy() and not interrupt) then return end
  local ready = A.Ready(unit, spell)
  if ready then A.StartSelectedAttack(unit) end
  A.CastOffensive(unit, spell, false, interrupt and ',casting' or nil, interrupt)
  if ready then A.StartSelectedAttack(unit) end
end
