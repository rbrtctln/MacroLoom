local API = MacroLoom
if API.playerClass ~= 'SHAMAN' then return end
function API.LeaveTravel()
  if not API.ExecutionReady() then return nil end
  if IsMounted and IsMounted() then Dismount() end
  if CleveRoids.ValidatePlayerBuff('Ghost Wolf') then CancelShapeshiftForm() end
end

function API.RegenMana()
  local maximum = UnitManaMax('player')
  return not maximum or maximum <= 0 or UnitMana('player') <= maximum * .20
end

function API.LowMana()
  local maximum = UnitManaMax('player')
  return not maximum or maximum <= 0 or UnitMana('player') < maximum * .40
end

function API.StormstrikeBuff()
  if not API.ExecutionReady() then return false end
  if CleveRoids.ValidatePlayerBuff('52412') then return true end
  for i = 1, 64 do
    local texture, stacks, id = UnitBuff('player', i)
    if not texture then break end
    if id == 52412 then return true end
  end
  return false
end

function API.LightningStrikeSoon()
  if not API.ExecutionReady() then return false end
  local C = CleveRoids
  local sp = C.GetSpell('Lightning Strike')
  if not sp or not sp.spellSlot then return false end
  local start, duration, enabled = GetSpellCooldown(sp.spellSlot, sp.bookType)
  if not start or not duration or enabled == 0 then return false end
  local remaining = math.max(0, start + duration - GetTime())
  local N = C.NampowerAPI
  local gcd = N and N.GetGCDRemainingMs and N.GetGCDRemainingMs() or 0
  local horizon = gcd > 0 and gcd / 1000 or 1.5
  if gcd <= 0 and N and N.GetSpellCooldownInfo then
    local shock = C.GetSpell('Earth Shock(Rank 4)') or C.GetSpell('Earth Shock')
    local info = shock and N.GetSpellCooldownInfo(shock.id)
    if info and info.gcdCategoryDurationMs and info.gcdCategoryDurationMs > 0 then
      horizon = info.gcdCategoryDurationMs / 1000
    end
  end
  return remaining <= horizon
end

function API.Maintain()
  if not API.ExecutionReady() then return false end
  local c = CleveRoids
  if c.stopMacroFlag or c.skipMacroFlag then return true end
  if API.Busy() or UnitIsDeadOrGhost('player') then return false end
  -- /runmacro resets firstaction in the installed SuperMacro compatibility hook.
  -- /run reuses the same helpers without crossing that reset boundary.
  local imbue = type(SoakedSubImbueExec) == 'function' and '/run SoakedSubImbueExec()\n' or ''
  RunBody('/firstaction\n' .. imbue .. '/run SoakedMacroBridge.ShieldMaintain()')
  local dispatched = c.stopMacroFlag
  RunBody('/nofirstaction')
  return dispatched and true or false -- accepted attempt, never server confirmation
end

function API.TankState()
  if not API.ExecutionReady() then return false end
  return CleveRoids.TestAction('/cast', '[equipped:Shields,mhenchant:Rockbiter] Earth Shock') and true or false
end

function API.OffensiveBlocked(spell)
  return spell == 'Stormstrike' and API.StormstrikeBuff()
end
