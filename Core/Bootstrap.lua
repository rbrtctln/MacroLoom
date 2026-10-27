-- Shared namespace; old Extended macros retain the exact same table.
MacroLoom = MacroLoom or SoakedMacroBridge or {}
SoakedMacroBridge = MacroLoom
local API = MacroLoom
API.version = '0.1.0'
local _, class = UnitClass('player')
API.playerClass = class
API.DisplayOptions = {}
function API.ExecutionReady()
  local C = CleveRoids
  return C and type(C.TestAction) == 'function' and type(C.GetSpell) == 'function'
    and type(C.GetSpellCost) == 'function' and type(RunBody) == 'function'
end
-- Class modules may supply maintenance and read-only presentation policy.
function API.Maintain() return false end
function API.RotationDisplay(name) end
function API.LeaveTravel()
  if IsMounted and IsMounted() then Dismount() end
end
