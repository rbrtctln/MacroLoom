local API = MacroLoom
API.ConsumeMinimum = { health = 100, mana = 150 }
API.ConsumeData = {
  [2455] = {level=5, group=4, mana=160.0}, -- Minor Mana Potion
  [858] = {level=3, group=4, health=160.0}, -- Lesser Healing Potion
  [3928] = {level=35, group=4, health=800.0}, -- Superior Healing Potion
  [13444] = {level=49, group=4, mana=1800.0}, -- Major Mana Potion
  [118] = {level=1, group=4, health=80.0}, -- Minor Healing Potion
  [929] = {level=12, group=4, health=320.0}, -- Healing Potion
  [13446] = {level=45, group=4, health=1400.0}, -- Major Healing Potion
  [1710] = {level=21, group=4, health=520.0}, -- Greater Healing Potion
  [13443] = {level=41, group=4, mana=1200.0}, -- Superior Mana Potion
  [6149] = {level=31, group=4, mana=800.0}, -- Greater Mana Potion
  [3827] = {level=22, group=4, mana=520.0}, -- Mana Potion
  [3385] = {level=14, group=4, mana=320.0}, -- Lesser Mana Potion
}
function API.SelectConsume(kind)
  local missing
  if kind == 'health' then missing = UnitHealthMax('player') - UnitHealth('player')
  else missing = UnitManaMax('player') - UnitMana('player') end
  if (UnitIsDeadOrGhost('player') or missing < API.ConsumeMinimum[kind]) then return end
  local best, bestAmount, sufficient
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local link = GetContainerItemLink(bag, slot)
      local _, _, id = string.find(link or '', 'item:(%d+)')
      local data = id and API.ConsumeData[tonumber(id)]
      local amount = data and data[kind]
      if amount and data.group == 4 and UnitLevel('player') >= data.level then
        local texture, count, locked = GetContainerItemInfo(bag, slot)
        local start, duration, enabled = GetContainerItemCooldown(bag, slot)
        -- Bag cooldown reports item AND shared category cooldowns.
        local ready = enabled == 1 and (duration == 0 or start + duration <= GetTime())
        if count and count > 0 and (not locked and ready) then
          local enough = amount >= missing
          if not best or (enough and not sufficient) or
            (enough == sufficient and ((enough and amount < bestAmount) or (not enough and amount > bestAmount))) then
            best = {id=tonumber(id), bag=bag, slot=slot, texture=texture, group=data.group}
            bestAmount, sufficient = amount, enough
          end
        end
      end
    end
  end
  return best
end
function API.Consume(kind)
  if API.Busy() then return end
  local item = API.SelectConsume(kind)
  if item then UseContainerItem(item.bag, item.slot) end
end
