-- Soaked editor bridge: pfUI icon picker for SuperMacro's editor.
-- Does not alter spell resolution, action execution, or action-bar rendering.
local bridge = CreateFrame("Frame", "SoakedMacroBridgeEditorLoader", UIParent)
local installed = false
local popup, selector

local function Say(message)
  DEFAULT_CHAT_FRAME:AddMessage("SoakedMacroBridge: " .. message)
end

local function Ready()
  return pfUI and pfUI.api and type(pfUI.api.CreateIconPicker) == "function"
     and type(IconDataProviderMixin) == "table"
     and type(IconDataProviderExtraType) == "table"
     and SuperMacroFrame and SuperMacroFrame_Update and SM_VARS
     and type(CreateSuperMacro) == "function"
     and type(EditSuperMacro) == "function"
     and C_Macro and type(C_Macro.EditMacro) == "function"
     and type(C_Macro.CreateMacro) == "function"
     and type(SuperMacroFrame_SaveMacro) == "function"
end

local function Close()
  if popup then popup:Hide() end
end

local function Open(mode)
  if not installed then return end
  -- Persist edits to the existing body before opening the icon picker.
  if SM_VARS.tabShown == "super" then
    SuperMacroFrame_SaveSuperMacro()
  else
    SuperMacroFrame_SaveMacro()
  end
  popup.mode = mode
  popup.oldname = nil
  local name, texture
  if mode == "edit" then
    if SM_VARS.tabShown == "super" then
      if not SuperMacroFrame.selectedSuper then return end
      name, texture = GetOrderedSuperMacroInfo(SuperMacroFrame.selectedSuper)
    else
      if not SuperMacroFrame.selectedMacro then return end
      name, texture = GetMacroInfo(SuperMacroFrame.selectedMacro)
    end
    popup.oldname = name
  end
  popup.editbox:SetText(name or "")
  -- Legacy SuperMacro icon indices are not valid texture paths.
  if type(texture) ~= "string" or string.find(texture, "^Interface\\Icons\\%d+$") then
    texture = nil
  end
  selector.SetIcon(texture)
  popup.search:SetText("")
  if not popup.userMoved then
    popup:ClearAllPoints()
    popup:SetPoint("TOPLEFT", SuperMacroFrame, "TOPRIGHT", 8, -20)
  end
  popup:Show()
  popup.editbox:SetFocus()
  selector.Refresh()
end

local function Save()
  local name = popup.editbox:GetText()
  if not name or name == "" then return end
  local icon = selector.GetIcon()
  local mode = popup.mode
  local idx
  if mode == "newsuper" then
    if SM_SUPER[name] then Say("A Super macro with that name already exists."); return end
    idx = CreateSuperMacro(name, icon, "")
    if not idx then Say("Super macro creation failed."); return end
    SuperMacroFrame_SelectSuperMacro(idx)
  elseif mode == "newaccount" or mode == "newcharacter" then
    idx = C_Macro.CreateMacro(name, icon, nil, mode == "newcharacter")
    if not idx then Say("Macro creation failed (or the macro limit was reached)."); return end
    SuperMacroFrame_SelectMacro(idx)
  elseif mode == "edit" then
    if SM_VARS.tabShown == "super" then
      local old = popup.oldname
      if name ~= old and SM_SUPER[name] then
        Say("Another Super macro already uses that name."); return
      end
      idx = EditSuperMacro(SuperMacroFrame.selectedSuper, name, icon)
      if not idx then Say("Super macro editing failed."); return end
      SuperMacroFrame_SelectSuperMacro(idx)
      if old ~= name and type(SuperMacro_UpdateAction) == "function" then
        SuperMacro_UpdateAction(old, name)
      end
    else
      local old = popup.oldname
      -- Keep SuperMacro's extended-code ownership and rename bookkeeping.
      if old ~= name and type(SuperMacroCopyExtend) == "function" then
        SuperMacroCopyExtend(old, name)
      end
      idx = C_Macro.EditMacro(SuperMacroFrame.selectedMacro, name, icon, nil)
      idx = idx or SuperMacroFrame.selectedMacro
      if old ~= name and type(SameMacroName) == "function" and
         not SameMacroName() and type(SuperMacroDeleteExtend) == "function" then
        SuperMacroDeleteExtend(old)
      end
      if type(SM_UpdateActionSpell) == "function" then
        if old ~= name and GetMacroIndexByName(old) == 0 then
          SM_UpdateActionSpell(old, "regular", "")
        end
        local _, _, body = GetMacroInfo(idx)
        SM_UpdateActionSpell(name, "regular", body or "")
      end
      SuperMacroFrame_SelectMacro(idx)
    end
  end
  if type(SuperMacroSelectExtend) == "function" then SuperMacroSelectExtend(name) end
  Close()
  SuperMacroFrame_Update()
end

local function Install()
  if not Ready() then return false end
  popup = CreateFrame("Frame", "SoakedBridgeIconPicker", UIParent)
  popup:SetFrameStrata("DIALOG")
  popup:SetWidth(472)
  popup:SetHeight(484)
  popup:SetPoint("TOPLEFT", SuperMacroFrame, "TOPRIGHT", 8, -20)
  popup:EnableMouse(true)
  popup:SetMovable(true)
  popup:RegisterForDrag("LeftButton")
  popup:SetScript("OnDragStart", function() this:StartMoving() end)
  popup:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    this.userMoved = true
  end)
  popup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = {left=4, right=4, top=4, bottom=4},
  })
  popup:SetBackdropColor(0.07, 0.07, 0.07, 0.96)
  popup:Hide()

  selector = pfUI.api.CreateIconPicker("SoakedBridgePicker", popup,
    IconDataProviderExtraType.Spellbook, MACRO_POPUP_TEXT)
  popup.editbox = selector.editbox
  popup.search = selector.search
  popup.editbox:SetScript("OnEnterPressed", Save)
  popup.editbox:SetScript("OnEscapePressed", Close)

  local ok = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
  ok:SetWidth(80); ok:SetHeight(22)
  ok:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -105, 12)
  ok:SetText(OKAY)
  ok:SetScript("OnClick", Save)
  local cancel = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
  cancel:SetWidth(80); cancel:SetHeight(22)
  cancel:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -14, 12)
  cancel:SetText(CANCEL)
  cancel:SetScript("OnClick", Close)
  SuperMacroFrame:HookScript("OnHide", Close)

  -- Replace only the SuperMacro editor's entrypoints; never hook casting.
  SuperMacroNewAccountButton_OnClick = function() Open("newaccount") end
  SuperMacroNewCharacterButton_OnClick = function() Open("newcharacter") end
  SuperMacroNewSuperButton_OnClick = function() Open("newsuper") end
  SuperMacroEditButton_OnClick = function() Open("edit") end
  installed = true
  return true
end

bridge:SetScript("OnUpdate", function()
  if Install() then
    this:SetScript("OnUpdate", nil)
    Say("pfUI icon picker connected to SuperMacro editor.")
  end
end)
