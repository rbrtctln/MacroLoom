# MacroLoom

**Portable macro services for Vanilla/Turtle/Octo-style World of Warcraft clients.**

**Version:** 0.1.0 (initial public-release candidate)

MacroLoom is a modular Lua 5.1 addon built around existing SuperMacro and SuperCleveRoidMacros (SCR) workflows. It supplies shared macro utilities and class-specific modules without replacing the game's macro editor or SCR's execution system.

## Features

- Common helpers for unit eligibility, combat/engagement checks, hostile-target selection, and spell dispatch through SCR.
- Inventory-aware health/mana consumable selection helpers (the calling macro determines whether to use them).
- Three compatible presentation paths: regular SCR macro display, read-only Extended Lua rotation previews, and opt-in registered display providers.
- Integration with pfUI action bars for provider icons and tooltip presentation when pfUI is installed.
- Integration with the SuperMacro editor's icon selection using the pfUI picker when those addons and APIs are available.
- A class-gated Shaman module with shield, imbue, maintenance, Stormstrike, and associated display utilities. The Shaman implementation retains the `SoakedMacroBridge` API alias for existing Soaked macros.

**Not included:** Other class rotation modules, automatic tank-assist selection, character macro exports, a spellbook-style UI, or copies of dependency addons. Shaman display providers currently reference Soaked-specific macro names/functions; they are not generic ready-made rotations for every Shaman.

## Requirements and integrations

- A compatible WoW 1.12-derived client (the TOC declares `## Interface: 11200`).
- **SuperCleveRoidMacros (SCR)** for the action-validation and spell-dispatch APIs used by the Shaman functionality.
- **SuperMacro** for the Extended Lua/`RunBody` macro workflows.
- **pfUI**, optional, for pfUI-specific action-bar display, tooltip, and macro-editor enhancements.

The TOC lists pfUI, SuperMacro, and SCR variants under `OptionalDeps` to improve load ordering where present. That does **not** mean all execution features function without SCR or SuperMacro. Do not install multiple conflicting versions of the same dependency.

MacroLoom does not include or license pfUI, SuperMacro, SCR, game client software, or World of Warcraft assets. Obtain each dependency separately and follow its own licensing terms.

## Installation

1. Close the game.
2. Extract this ZIP so the addon files are located at `Interface/AddOns/MacroLoom/MacroLoom.toc` under the chosen game installation. Avoid a double `MacroLoom/MacroLoom` directory.
3. Ensure the appropriate existing SCR and SuperMacro installations are available. Install pfUI if you want its specific UI integrations.
4. Enable MacroLoom in the game's addon list and launch normally.
5. For an existing Soaked setup, preserve your current macros and SavedVariables and test the installation before removing any older compatibility addon. **Do not load multiple copies of the Bridge/Core simultaneously without verifying their interactions.**

MacroLoom by itself does **not** create, import, or install user macros. Players must supply their own macro definitions and appropriate class-specific scripts.

## Display and class architecture

- **Native SCR presentation:** standard `/cast` or `/use` macro syntax and SCR's own display selection.
- **Extended Lua preview:** a class module can provide `MacroLoom.RotationDisplay(name)` for SCR's active-action display path. These previews must be side-effect free.
- **Provider display:** call `MacroLoom.Register(macroName, provider)` to register a read-only provider returning a spell or item reference and display information. `MacroLoom.Unregister(macroName)` removes the provider.

Providers and preview functions must not cast, consume, change targets, or mutate game state while resolving a display. The Bridge is deliberately opt-in: ordinary macros may continue to use native SCR rendering.

The shared `MacroLoom` namespace is also exposed as `SoakedMacroBridge` for backwards compatibility. Shaman-specific Lua files early-return for non-Shaman characters. Adding future class modules should not place class-specific spell decisions into the shared Core.

## Known limitations / testing

- The project was migrated and tested in the author's client environment; **compatibility with every Turtle/Octo version and combination of addons is not established**.
- `Core/Display.lua` hooks SCR's `TestForActiveAction` method. SCR updates may require an integration review.
- pfUI integration depends on specific pfUI structures and may not work with every fork/version.
- The spellbook-style user interface, cross-class modules, and automatic tank-assist behaviors are roadmap ideas, **not v0.1.0 features**.
- This distributable does not contain the original migration's test suite or Git history. The previous developer reported 142 checks passing, but the tests cannot be re-run from this ZIP alone. In-game verification remains necessary.

## License

MacroLoom's original code and documentation are released under the **MIT License**. See [LICENSE](LICENSE). External dependencies and Warcraft intellectual property remain under their respective owners' terms; no licenses for them are granted here.

## Release notes

See [CHANGELOG.md](CHANGELOG.md). Please report reproducible issues with the game variant, addon versions, relevant macro text, and minimal steps to reproduce; exclude account identifiers and private SavedVariables.
