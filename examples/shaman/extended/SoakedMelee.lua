-- Spender policy lives in Extended Lua; display only previews without scanning.
function SoakedSpenderMode()
  return not SoakedMacroBridge.RegenMana()
    and not CleveRoids.ValidatePlayerBuff('Water Shield')
    and CleveRoids.ValidatePlayerBuff('Lightning Shield') and true or false
end
function SoakedMeleeOptions()
  local A = SoakedMacroBridge
  if IsShiftKeyDown() then return {'Earthshaker Slam'}, false end
  if IsAltKeyDown() then
    if A.StormstrikeBuff() then
      return {'Lightning Strike'}, false
    end
    return {'Stormstrike'}, false
  end
  if IsControlKeyDown() then return {'Lightning Strike'}, false end
  if SoakedSpenderMode() and not A.StormstrikeBuff() then
    return {'Stormstrike', 'Lightning Strike'}, true
  end
  return {'Lightning Strike'}, true
end
function SoakedMeleeChoice(scan)
  local A = SoakedMacroBridge
  local spells = SoakedMeleeOptions()
  local weave = IsAltKeyDown() and A.StormstrikeBuff()
  if not IsShiftKeyDown() and (weave or (not IsControlKeyDown() and not IsAltKeyDown())) then
    local unit, spell, interrupt = SoakedESEconomyChoice(scan, true)
    if unit then return unit, spell, interrupt end
    if weave then
      -- Do not spend an ES GCD that would delay the stronger melee strike.
      if A.LightningStrikeSoon() then
        unit = A.ScanMelee('Lightning Strike', '', scan, true)
        if unit then return unit, 'Lightning Strike', false, true end
      end
      unit, spell, interrupt = SoakedESEconomyChoice(scan)
      if unit then return unit, spell, interrupt end
    end
  end
  if A.Busy() then return end
  for i = 1, table.getn(spells) do
    local spell, unit = spells[i]
    if IsShiftKeyDown() then
      unit = A.SelectHostile(spell, function(u)
        if A.LostThreat(u) then
          return CleveRoids.hasUnitXP and (UnitXP('distanceBetween', 'player', u) or 9999) or 1
        end
      end, scan, ',meleerange')
      -- Explicit Shift press: recover a loose mob first, then the selected hostile.
      -- This fallback never acquires an unrelated enemy from a scan.
      if not unit and not UnitIsUnit('targettarget', 'player')
        and A.Ready('target', spell, ',meleerange') then unit = 'target' end
    else
      unit = A.ScanMelee(spell, '', scan)
    end
    if unit then return unit, spell, false end
  end
end
function SoakedMeleeExec()
  local A = SoakedMacroBridge
  local unit, spell, interrupt, strikePriority = SoakedMeleeChoice(true)
  if A.Busy() and not interrupt then return end
  if strikePriority then
    -- Reservation is not dispatch: Ready still enforces the real cooldown/GCD.
    A.CastOffensive(unit, spell, false, ',meleerange')
    return
  end
  -- Kicks, threat recovery and empowerment spending win over routine maintenance.
  if spell and string.find(spell, '^Earth Shock') then
    A.CastOffensive(unit, spell, false, interrupt and ',casting' or nil, interrupt)
    return
  end
  local spells, maintenance = SoakedMeleeOptions()
  if maintenance and A.Maintain() then return end
  if not unit then return end
  if spell == 'Stormstrike' then
    if A.StormstrikeBuff() then return end
    if not IsAltKeyDown() and not SoakedSpenderMode() then return end
  end
  if IsAltKeyDown() and not IsShiftKeyDown() then A.LeaveTravel() end
  -- Threat can change after selection; never Slam a mob already targeting us.
  if spell == 'Earthshaker Slam' and UnitIsUnit(unit .. 'target', 'player') then return end
  A.CastOffensive(unit, spell, false, ',meleerange')
end
function SoakedMeleeDisplaySpell()
  local unit, spell = SoakedMeleeChoice(false)
  if spell then return spell, unit end
  if IsShiftKeyDown() then return 'Earthshaker Slam' end
  if IsAltKeyDown() then
    if SoakedMacroBridge.StormstrikeBuff() then return 'Earth Shock(Rank 5)' end
    return 'Stormstrike'
  end
  local spells = SoakedMeleeOptions()
  return spells[1] or 'Lightning Strike'
end
