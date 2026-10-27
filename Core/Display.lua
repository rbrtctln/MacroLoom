-- Generic, opt-in, read-only displays for custom SuperMacro Lua.
-- No macro executes here. Providers MUST NOT cast, target, consume, or alter state.
local API = MacroLoom
local providers = {}
local watch = CreateFrame('Frame', 'SoakedMacroBridgeDisplayFrame', UIParent)
local elapsed = 0

function API.Register(name, provider)
  if type(name) ~= 'string' or name == '' or type(provider) ~= 'function' then return false end
  providers[name] = provider
  return true
end
function API.Unregister(name) providers[name] = nil end

local function NameForButton(button)
  if not button or not button.id then return nil end
  if type(SM_ACTION) == 'table' and SM_ACTION[button.id] then
    return SM_ACTION[button.id]
  end
  -- GetActionText is SuperMacro-hooked and resolves normal macros as well.
  return GetActionText(button.id)
end

local function Resolve(name)
  local provider = providers[name]
  if not provider then return nil end
  local ok, kind, reference, texture, bag, slot = pcall(provider)
  if not ok then
    if not API.errors then API.errors = {} end
    if not API.errors[name] then
      API.errors[name] = true
      DEFAULT_CHAT_FRAME:AddMessage('SoakedMacroBridge: display provider failed for ' .. name .. ': ' .. tostring(kind))
    end
    return nil
  end
  -- Shield-only neutral icon: nil would restore SCR's question-mark texture.
  -- Keep native macro tooltip handling; this is not a generic tooltip type.
  local options = API.DisplayOptions[name]
  if options and options.neutralTexture and kind == nil then
    return { shieldNeutral = true, texture = options.neutralTexture }
  end
  if kind ~= 'item' and kind ~= 'spell' then return nil end
  if type(reference) ~= 'string' and type(reference) ~= 'number' then return nil end
  if not texture and kind == 'item' and type(GetItemIcon) == 'function' then
    texture = GetItemIcon(reference)
  end
  if type(texture) ~= 'string' and type(texture) ~= 'number' then return nil end
  return { kind = kind, reference = reference, texture = texture, bag = bag, slot = slot }
end

function API.ShowTooltip(button, resolved)
  local name = NameForButton(button)
  local r = resolved or (name and Resolve(name))
  if not r then return false end
  -- Let the game's tooltip engine generate complete item/spell text.
  GameTooltip:ClearLines()
  GameTooltip_SetDefaultAnchor(GameTooltip, button)
  if r.shieldNeutral then
    GameTooltip:SetAction(button.id)
  elseif r.kind == 'item' then
    local set = false
    -- Prefer the actual inventory item for exact tooltip text and random suffixes.
    if type(r.bag) == 'number' and type(r.slot) == 'number' then
      local link = GetContainerItemLink(r.bag, r.slot)
      if link then
        GameTooltip:SetBagItem(r.bag, r.slot)
        set = true
      end
    end
    if not set then
      local ref = r.reference
      if type(ref) == 'string' then
        -- Full clickable links include color and display markup. Extract the
        -- item: payload accepted by GameTooltip:SetHyperlink.
        ref = string.match(ref, '|H(item:[^|]+)|h') or ref
      elseif type(ref) == 'number' then
        ref = 'item:' .. ref .. ':0:0:0'
      end
      if type(ref) == 'string' and string.sub(ref, 1, 5) == 'item:' then
        GameTooltip:SetHyperlink(ref)
      else
        GameTooltip:SetText(tostring(r.reference))
      end
    end
  elseif type(r.slot) == 'number' and type(r.bag) == 'string' then
    -- Spell providers may supply the actual spellbook type and slot.
    GameTooltip:SetSpell(r.slot, r.bag)
  else
    -- Unknown spells have no spellbook tooltip; retain the honest name fallback.
    GameTooltip:SetText(tostring(r.reference))
  end
  GameTooltip:Show()
  return true
end

watch:SetScript('OnUpdate', function()
  elapsed = elapsed + arg1
  if elapsed < .20 then return end
  elapsed = 0
  if not pfUI or not pfUI.bars or not pfUI.bars.buttons then return end
  -- One provider evaluation per macro per pass, including a cached nil result.
  -- Keep the lightweight poll for paging and arbitrary third-party providers.
  local resolved, seen = {}, {}
  for id = 1, 120 do
    local button = pfUI.bars.buttons[id]
    if button and button.icon then
      local name = NameForButton(button)
      if name and not seen[name] then
        seen[name] = true
        resolved[name] = Resolve(name)
      end
      local r = name and resolved[name]
      if r then
        if button.SoakedDisplayTexture ~= r.texture or button.icon:GetTexture() ~= r.texture then
          button.icon:SetTexture(r.texture)
          button.texture = r.texture
          button.SoakedDisplayTexture = r.texture
          if API.DisplayOptions[name] and API.DisplayOptions[name].refreshHover and GetMouseFocus() == button then
            API.ShowTooltip(button, r)
          end
        end
      elseif button.SoakedDisplayTexture then
        button.SoakedDisplayTexture = nil
        if pfUI.bars.ButtonFullUpdate then pfUI.bars.ButtonFullUpdate(button) end
      end
    end
  end
end)

-- Native and pfUI displays share the Extended policy, including the chosen rank.
local displayHook = CreateFrame('Frame')
displayHook:SetScript('OnUpdate', function()
  local C = CleveRoids
  if not C or not C.TestForActiveAction or not C.CreateActionInfo then return end
  local original = C.TestForActiveAction
  C.TestForActiveAction = function(actions)
    local name = actions and actions.macroID and GetMacroInfo(actions.macroID)
    if name and API.RotationDisplay then
      local spell, unit = API.RotationDisplay(name)
      if spell then
        local previous = actions.active
        local oldUsable = previous and previous.usable
        local oldOom = previous and previous.oom
        local oldRange = previous and previous.inRange
        local info = actions.soakedDisplayInfo
        local target = unit or 'target'
        local targetChanged = not info or info.conditionals.target ~= target
        if not info or info.action ~= spell then
          info = C.CreateActionInfo(spell, {target = target})
          actions.soakedDisplayInfo = info
        else
          info.conditionals.target = target
        end
        local proxy = {list = {}, tooltip = info, explicitTooltip = true,
          active = actions.active, macroID = actions.macroID}
        local changed = original(proxy)
        if API.DisplayBlocked and API.DisplayBlocked(spell) and proxy.active then
          proxy.active.usable = nil
        end
        actions.active = proxy.active
        actions.sequence = nil
        return previous ~= proxy.active or targetChanged
          or (proxy.active and (oldUsable ~= proxy.active.usable
            or oldOom ~= proxy.active.oom or oldRange ~= proxy.active.inRange)) or false
      end
    end
    return original(actions)
  end
  displayHook:SetScript('OnUpdate', nil)
end)
