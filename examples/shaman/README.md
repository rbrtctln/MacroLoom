# Shaman reference macros

These sanitized exports illustrate the Soaked setup; they contain no SavedVariables, account mappings or character data. They are not standalone rotations and are not loaded by the addon TOC.

The Extended Lua files depend on MacroLoom, SCR, SuperMacro and the existing shield/imbue maintenance setup. Install both SoakedES and SoakedMelee functions together when adapting the melee example. Review their named helpers before use. The regular JSON files describe macro name, icon, scope and body; they are reference data, not automatic imports. Back up your macros and exit the client before editing SavedVariables.

- No-mod melee: urgent kicks and Rockbiter-enabled threat recovery, then existing Stormstrike/Lightning Strike policy. Ordinary empowered ES does not weave here.
- Ctrl: Lightning Strike.
- Shift: Earthshaker Slam lost-threat recovery, then deliberate selected-hostile fallback. Mobs already targeting the player are excluded.
- Alt: with SS charges, prefer ready/soon Lightning Strike, otherwise empowered Rank 5 ES with any shield or no shield; without charges, retain forced Stormstrike behavior.
- Unpowered kicks use R1. Powered kicks require R5 and sufficient mana; they do not silently downrank.
- Dedicated Earth Shock Alt uses maximum rank on mouseover then target. Its no-mod policy can spend existing SS charges across shield types.

Automatic recovery scans remain engagement-restricted and respect SCR-recognized tanks. Selected fallback allows deliberate rescues outside the group. Display previews do not acquire targets or cast.
