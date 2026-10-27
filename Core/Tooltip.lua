-- Soaked Macro Bridge 1.1.0
-- Turtle WoW / Vanilla 1.12: pfUI + SuperMacro Super-tab tooltips.
-- Based on the two in-game commands tested successfully by the player.

local addon = CreateFrame("Frame", "SoakedMacroBridgeTooltipFrame", UIParent)
local installed = false
local count = 0

local function Ready()
  return pfUI and pfUI.bars and pfUI.bars.ButtonEnter
    and type(SM_ActionButton_SetTooltip) == "function"
    and type(GameTooltip_SetDefaultAnchor) == "function"
end

local function FixSuperMacroTooltip(button)
  -- This is the working in-game hover sequence. Using button.id matters:
  -- pfUI changes it for the active Shift / Ctrl / Alt action-bar page.
  pfUI.bars.ButtonEnter(button)
  GameTooltip:ClearLines()
  GameTooltip_SetDefaultAnchor(GameTooltip, button)
  GameTooltip:SetText("Init")
  SM_ActionButton_SetTooltip(button.id)
  GameTooltip:Show()
end

local function Install()
  if not Ready() then return false end

  local patched = 0
  for bar = 1, 10 do
    if pfUI.bars[bar] then
      for slot = 1, 12 do
        local button = pfUI.bars[bar][slot]
        if button then
          if not button.SoakedTipHandler then
            -- Preserve the original hover handler for regular spells/items.
            local original = button:GetScript("OnEnter")
            button.SoakedTipHandler = function()
              local b = this  -- WoW 1.12 event-handler convention
              if SoakedMacroBridge and SoakedMacroBridge.ShowTooltip and SoakedMacroBridge.ShowTooltip(b) then
                -- Explicit custom display has priority.
              elseif type(SM_ACTION) == "table" and SM_ACTION[b.id] then
                FixSuperMacroTooltip(b)
              elseif original then
                original()
              else
                pfUI.bars.ButtonEnter(b)
              end
            end
          end

          button:SetScript("OnEnter", button.SoakedTipHandler)
          patched = patched + 1
        end
      end
    end
  end

  if patched == 0 then return false end
  installed = true
  count = patched
  return true
end

-- pfUI may create its action buttons after addons finish loading.
-- Wait until the buttons actually exist rather than assuming event ordering.
addon:SetScript("OnUpdate", function()
  if installed then
    this:SetScript("OnUpdate", nil)
    return
  end
  if Install() then
    this:SetScript("OnUpdate", nil)
  end
end)

-- Optional manual reapply if another addon replaces OnEnter scripts later.
SLASH_SOAKEDTIP1 = "/soakedtip"
SLASH_SOAKEDTIP2 = "/macroloomtip"
SlashCmdList["SOAKEDTIP"] = function()
  if Install() then
    DEFAULT_CHAT_FRAME:AddMessage("SoakedMacroBridge: active on " .. count .. " pfUI buttons")
  else
    DEFAULT_CHAT_FRAME:AddMessage("SoakedMacroBridge: waiting for pfUI and SuperMacro")
  end
end
