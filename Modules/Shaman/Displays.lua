local API = MacroLoom
if API.playerClass ~= 'SHAMAN' then return end
API.DisplayOptions.SoakedShield = {
  neutralTexture = 'Interface\\Icons\\SPELL_SHAMAN_IMPROVEDEARTHSHIELD',
  refreshHover = true,
}
API.DisplayBlocked = API.OffensiveBlocked
local function SpellDisplay(spell)
  local sp = spell and CleveRoids and CleveRoids.GetSpell and CleveRoids.GetSpell(spell)
  if sp then return 'spell', spell, sp.texture, sp.bookType, sp.spellSlot end
end
API.Register('SoakedMB', function()
  local spell = SoakedMBSpell and SoakedMBSpell() or 'Molten Blast(Rank 1)'
  return SpellDisplay(spell)
end)
API.Register('SoakedES', function()
  local unit, spell
  if SoakedESChoice then unit, spell = SoakedESChoice(false) end
  return SpellDisplay(spell or (IsAltKeyDown() and 'Earth Shock' or 'Earth Shock(Rank 4)'))
end)
API.Register('SoakedMelee', function()
  local spell = SoakedMeleeDisplaySpell and SoakedMeleeDisplaySpell() or 'Lightning Strike'
  return SpellDisplay(spell)
end)
-- Shared read-only offensive preview for SCR's native display/cooldown path.
function API.RotationDisplay(name)
  if name == 'SoakedMB' and SoakedMBDisplaySpell then return SoakedMBDisplaySpell() end
  if name == 'SoakedShield' and API.ShieldDisplaySpell then return API.ShieldDisplaySpell() end
  if name == 'SoakedMelee' and SoakedMeleeDisplaySpell then return SoakedMeleeDisplaySpell() end
  if name == 'SoakedES' and SoakedESChoice then
    local unit, spell = SoakedESChoice(false)
    return spell or (IsAltKeyDown() and 'Earth Shock' or 'Earth Shock(Rank 4)'), unit
  end
end
