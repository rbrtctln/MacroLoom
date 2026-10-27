local API = MacroLoom
if API.playerClass ~= 'SHAMAN' then return end
API.HealBaseCosts = {
  [331] = 25,
  [332] = 45,
  [547] = 80,
  [913] = 155,
  [939] = 200,
  [959] = 265,
  [8004] = 105,
  [8005] = 340,
  [8008] = 145,
  [8010] = 185,
  [10395] = 440,
  [10396] = 560,
  [10466] = 235,
  [10467] = 305,
  [10468] = 380,
  [11986] = 145,
  [12491] = 145,
  [12492] = 145,
  [15982] = 145,
  [25357] = 620,
  [26097] = 145,
  [27624] = 380,
}
-- Experimental DPME only; button permission/modifier policy stays in Extended Lua.
-- Base records: installed patch-O Spell.dbc (same affected records in patch-5).
-- Rows keyed by learned spell ID: rank, learn level, undiscounted mana, low, high.
-- Provisional base ranges at learn level; no unverified AP/proc/crit contribution.
local efficiencyData = {
  ["Molten Blast"] = {school=3, coefficient=0.5714, ranks={
    [315]={1,6,30,18,26},
    [36916]={1,20,65,61,73},
    [545]={2,14,45,32,44},
    [36917]={2,28,95,96,120},
    [899]={3,22,70,59,77},
    [36918]={3,36,120,136,155},
    [923]={4,30,110,103,133},
    [36919]={4,44,145,185,204},
    [951]={5,38,145,148,188},
    [36920]={5,52,175,238,268},
    [10419]={6,46,180,198,250},
    [36921]={6,60,210,290,331},
    [10420]={7,54,220,260,326},
  }},
  ["Lightning Bolt"] = {school=4, coefficient=0.8571, ranks={
    [403]={1,1,15,13,15},
    [529]={2,8,25,26,30},
    [548]={3,14,40,45,53},
    [915]={4,20,70,83,95},
    [943]={5,26,95,125,143},
    [6041]={6,32,125,172,194},
    [10391]={7,38,150,227,255},
    [10392]={8,44,175,282,316},
    [15207]={9,50,210,347,389},
    [33457]={9,50,210,347,389},
    [15208]={10,56,240,419,467},
  }},
  ["Chain Lightning"] = {school=4, coefficient=0.7142, ranks={
    [421]={1,32,280,191,217},
    [930]={2,40,380,277,311},
    [2860]={3,48,490,378,424},
    [10605]={4,56,605,493,551},
  }},
  ["Earth Shock"] = {school=4, coefficient=0.4071, ranks={
    [8042]={1,4,30,17,19},
    [8044]={2,8,50,32,34},
    [8045]={3,14,85,60,64},
    [8046]={4,24,145,119,127},
    [10412]={5,36,240,225,239},
    [10413]={6,48,345,359,381},
    [10414]={7,60,450,492,520},
  }},
  ["Frost Shock"] = {school=5, coefficient=0.4071, ranks={
    [8056]={1,20,115,89,95},
    [8058]={2,34,225,206,220},
    [10472]={3,46,325,333,353},
    [10473]={4,58,430,436,464},
  }},
}
API.EfficiencyBlockers = {}
function API.EfficiencyRank(name, reserve, fallback)
  local data = efficiencyData[name]
  local function blocked(reason)
    API.EfficiencyBlockers[name] = reason
    return fallback, false
  end
  if not data or type(GetSpellBonusDamage) ~= 'function' then return blocked('school SP API unavailable') end
  local highest = CleveRoids.GetSpell(name)
  if not highest or not highest.spellSlot then return blocked('learned spell unavailable') end
  local _, rankText = GetSpellName(highest.spellSlot, highest.bookType)
  local _, _, rankNumber = string.find(rankText or '', '(%d+)')
  local count = tonumber(rankNumber)
  if not count or not data.ranks[highest.id] then return blocked('unmodeled highest learned ID/rank') end
  local ok, sp = pcall(GetSpellBonusDamage, data.school)
  if not ok or type(sp) ~= 'number' or sp ~= sp then return blocked('school SP read failed') end
  local budget = UnitMana('player') - (reserve or 0)
  local best, bestScore, bestRank
  for rank = 1, count do
    local spell = name .. '(Rank ' .. rank .. ')'
    local learned = CleveRoids.GetSpell(spell)
    if learned and learned.spellSlot then
      local row = data.ranks[learned.id]
      if not row or row[1] ~= rank then return blocked('unmodeled learned ID/rank: ' .. tostring(learned.id)) end
      if row[3] <= budget then
        local coefficient = data.coefficient
        if row[2] < 20 then coefficient = coefficient * (row[2] + 6) / 26 end
        local score = ((row[4] + row[5]) / 2 + coefficient * sp) / row[3]
        if not bestScore or score > bestScore or (score == bestScore and rank > bestRank) then
          best, bestScore, bestRank = spell, score, rank
        end
      end
    end
  end
  API.EfficiencyBlockers[name] = nil
  return best, true
end
