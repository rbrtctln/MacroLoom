-- Session-only shield controller. Display functions below are read-only.
local API = MacroLoom
if API.playerClass ~= 'SHAMAN' then return end
local preferred
local waterRecovery = false
local lightningCycle = false
local names = { "Lightning Shield", "Water Shield", "Earth Shield" }
local icons = { "Spell_Nature_LightningShield", "Ability_Shaman_WaterShield",
  "Spell_Nature_SkinofEarth" }
-- Original subShield priority, including its talent and equipment conditions.
local priority = {
  { 2, 'known:"Undertow"' },
  { 2, 'known:"Improved Water Shield"' },
  { 2, 'equipped:"Totem of Tides"' },
  { 3, 'known:"Call of Earth"' },
  { 3, 'known:"Spirit Armor"' },
  { 1, 'known:"Lightning Strike"' },
  { 3 }, { 2 }, { 1 },
}

local function Selection()
  -- One shared modifier precedence for execution and presentation.
  if IsAltKeyDown() then return 1 end
  if IsShiftKeyDown() then return 2 end
  if IsControlKeyDown() then return 3 end
end

local function Spell(index)
  if not CleveRoids or not CleveRoids.GetSpell then return nil end
  return CleveRoids.GetSpell(names[index])
end

local function Reserve()
  local heal = CleveRoids.GetSpell("Lesser Healing Wave") or CleveRoids.GetSpell("Healing Wave")
  local cost = heal and CleveRoids.GetSpellCost(heal.spellSlot, heal.bookType, heal.id) or 0
  if heal and API.HealBaseCosts then cost = math.max(cost, API.HealBaseCosts[heal.id] or 0) end
  return 30 + cost -- Rank 1 Earth Shock plus one emergency heal
end

local function Affordable(index, reserve)
  local sp = Spell(index)
  if not sp or not sp.spellSlot then return false end
  -- Installed SCR reads the effective talent-modified ClassicAPI power cost.
  local cost = CleveRoids.GetSpellCost(sp.spellSlot, sp.bookType, sp.id)
  if index == 2 then cost = 0 end -- Octo Water Shield is FREE
  return UnitMana("player") >= cost + (reserve and index ~= 2 and Reserve() or 0)
end

local function Attempt(index, condition)
  local clause = '[nogcd,nocooldown:"' .. names[index] .. '",known:"' .. names[index] .. '",@player'
  if condition then clause = clause .. ',' .. condition end
  return CleveRoids.DoCast(clause .. '] ' .. names[index])
end

-- Read-only hysteresis query. Only execution/login commits the recovery latch.
local function HoldWater()
  local maximum = UnitManaMax('player')
  if maximum and maximum > 0 and UnitMana('player') > maximum * .60 then return false end
  return API.LowMana() or waterRecovery or CleveRoids.ValidatePlayerBuff('Water Shield')
end
-- Read-only next-refresh selection, shared with the display.
local function NormalSelection()
  if preferred and Affordable(preferred, true) then return preferred end
  if preferred then
    if Affordable(2) then return 2 end
    return
  end
  local inferred
  if CleveRoids.TestAction('/cast', '[mhenchant:Rockbiter] Earth Shield') then inferred = 3
  elseif CleveRoids.TestAction('/cast', '[mhenchant:Windfury] Lightning Shield') then inferred = 1
  elseif CleveRoids.TestAction('/cast', '[mhenchant:Flametongue] Water Shield') then inferred = 2 end
  if inferred and Spell(inferred) then
    if Affordable(inferred, true) then return inferred
    elseif Affordable(2) then return 2 end
    return
  end
  for i = 1, table.getn(priority) do
    local rule = priority[i]
    if Spell(rule[1]) and (not rule[2] or CleveRoids.TestAction('/cast', '[' .. rule[2] .. '] ' .. names[rule[1]])) then
      if Affordable(rule[1], true) then return rule[1], rule[2]
      elseif Affordable(2) then return 2 end
      return
    end
  end
end
-- Only resume a Lightning cycle, never impose it on caster/healer preferences.
local function WantsLightning()
  if preferred then return preferred == 1 end
  return lightningCycle or NormalSelection() == 1
end
local function AutoSelection()
  if HoldWater() then
    if Spell(2) then return 2 end
    return
  end
  if WantsLightning() and Affordable(1, true) then return 1 end
  return NormalSelection()
end
local function CutoverLightning()
  local maximum = UnitManaMax('player')
  return maximum and maximum > 0 and UnitMana('player') >= maximum * .80
    and CleveRoids.ValidatePlayerBuff('Water Shield')
    and WantsLightning() and Affordable(1, true)
end
local function ObserveCycle()
  if not API.ExecutionReady() then return end
  if not preferred and CleveRoids.ValidatePlayerBuff('Lightning Shield') then lightningCycle = true end
  waterRecovery = HoldWater() and true or false
end
function API.ShieldMaintain()
  local crm = CleveRoids
  if not crm or not crm.DoCast or crm.stopMacroFlag or crm.skipMacroFlag then return end
  ObserveCycle()
  UIErrorsFrame:Clear()
  if CutoverLightning() then crm.DoFirstAction(''); Attempt(1); return end
  for i = 1, 3 do
    if crm.ValidatePlayerBuff(names[i]) then return end
  end
  local index, condition = AutoSelection()
  if index then crm.DoFirstAction(''); Attempt(index, condition) end
end
function API.ShieldDisplaySpell()
  if not API.ExecutionReady() then return end
  local index = Selection()
  if not index and CutoverLightning() then index = 1 end
  if not index then
    for i = 1, 3 do
      if CleveRoids.ValidatePlayerBuff(names[i]) then index = i; break end
    end
  end
  if not index then index = AutoSelection() end
  return index and names[index], 'player'
end

function API.ShieldManual()
  local index = Selection()
  local crm = CleveRoids
  if not crm or not crm.DoCast or crm.stopMacroFlag or crm.skipMacroFlag then return end
  if not index and CutoverLightning() then index = 1 end
  if not index then
    -- An explicit button press refreshes the active shield at any charge count.
    for i = 1, 3 do
      if crm.ValidatePlayerBuff(names[i]) then index = i; break end
    end
    if not index then API.ShieldMaintain(); return end
  end
  UIErrorsFrame:Clear()
  -- Always attempt the selected shield. Preflight only controls remembering it.
  local remember = Affordable(index) and not UnitIsDeadOrGhost("player")
  local sp = Spell(index)
  if remember and sp then
    local start, duration = GetSpellCooldown(sp.spellSlot, sp.bookType)
    if start and duration and duration > 0 and start + duration > GetTime() then
      remember = false
    end
  end
  if remember and IsSpellUsable then
    local ok, usable, oom = pcall(IsSpellUsable, names[index])
    if ok and (not usable or usable == 0 or oom == 1 or oom == true) then remember = false end
  end
  -- SCR's return means accepted attempt, not server-confirmed success.
  -- No global cast hooks, aura-intent inference, or asynchronous pending state.
  if Attempt(index) and remember then
    preferred = index
    lightningCycle = index == 1
    waterRecovery = index == 2 -- explicit non-Water choice leaves recovery mode
  end
end

local function Display()
  local name = API.ShieldDisplaySpell()
  if not name then return nil end
  local sp = CleveRoids.GetSpell(name)
  return 'spell', name, sp and sp.texture, sp and sp.bookType, sp and sp.spellSlot
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
  ObserveCycle()
  -- Register after addon initialization on every login / UI reload.
  API.Register("SoakedShield", Display)
end)

-- Session-only explicit button intent; no spellbook/cast observers.
local imbuePreferred = {}
local function WeaponKey()
  -- Link identity, not a guaranteed persistent item GUID. Identical links share intent.
  local link = GetInventoryItemLink('player', 16)
  local _, _, id, enchant, suffix, unique = string.find(link or '', 'item:(%d+):(%-?%d+):(%-?%d+):(%-?%d+)')
  if id then return id .. ':' .. suffix .. ':' .. unique end
  return link -- conservative session-only fallback; never cross weapon links
end
local function ImbueReady(spell)
  local c = CleveRoids
  if not c or c.stopMacroFlag or c.skipMacroFlag or API.Busy() or UnitIsDeadOrGhost('player') then return false end
  if not GetInventoryItemLink('player', 16) then return false end
  local sp = c.GetSpell(spell)
  return sp and UnitMana('player') >= c.GetSpellCost(sp.spellSlot, sp.bookType, sp.id)
    and not c.ValidateCooldown(spell, false)
end
function API.ImbueManual(spell)
  -- Preserve the existing Brilliant Wizard Oil guard on explicit replacement.
  if not ImbueReady(spell) then return end
  if CleveRoids.DoCast('[nogcd,nomhimbue:"Brilliant Wizard Oil"] ' .. spell) then
    local key = WeaponKey()
    if key then imbuePreferred[key] = spell end -- accepted attempt, not server-confirmed success
  end
end
function API.ImbueMaintain(defaults)
  local key = WeaponKey() -- inspect current equipment on EVERY evaluation, including combat
  if not key then return end
  local present = GetWeaponEnchantInfo()
  if present and present ~= 0 then return end -- ALL temporary enchants, including oils
  local spell = imbuePreferred[key]
  if not spell then
    for i = 1, table.getn(defaults) do
      if CleveRoids.GetSpell(defaults[i]) then spell = defaults[i]; break end
    end
  end
  if spell and ImbueReady(spell) and UnitMana('player') >= Reserve() + CleveRoids.GetSpellCost(CleveRoids.GetSpell(spell).spellSlot, CleveRoids.GetSpell(spell).bookType, CleveRoids.GetSpell(spell).id) then
    CleveRoids.DoFirstAction('')
    CleveRoids.DoCast('[nogcd] ' .. spell)
  end
end
