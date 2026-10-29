# Changelog

## [0.1.2] — 2026-10-29

- Restore interrupt detection using SCR’s current cast/channel API, retaining compatibility with its older tracking table.
- Expand defensive recovery to engaged party/raid members and pets, with SCR-recognized tank exclusions and group-target discovery.
- Active main-hand Rockbiter enables tank threat recovery without requiring an equipped shield.
- Update empowered ES display defaults and Lightning Strike timing reference to Rank 5.
- Add sanitized reference macros: Ctrl Lightning Strike, Shift Earthshaker Slam; ESS excludes mobs targeting the player and otherwise supports deliberate selected-target fallback.
- Reference melee policy retains urgent no-mod kicks/threat recovery and moves ordinary empowered R5 ES to Alt across all shield types, with Lightning Strike ready/soon priority. Unpowered kicks remain R1.

**Validation:** 286 checks passed in the local development suite, including installed SCR cast/channel detection, display behavior and main-hand enchant validation. Mocks do not establish live compatibility with every client/addon combination. Personal macros are not automatically migrated by an addon update.

## [0.1.0] — 2026-10-27

Initial public-release candidate:

- Portable shared namespace (`MacroLoom`) with `SoakedMacroBridge` compatibility alias.
- Shaman-gated mechanics, shield/imbue helpers, and display integration.
- Shared targeting, spell dispatch, and consumable utilities.
- Native SCR, Extended Lua rotation-preview, and registered provider display support.
- Optional pfUI icon/tooltip and SuperMacro editor integration.
- MIT licensing and portable installation documentation.

**Verification status:** The previous migration reported 142 automated checks and preliminary live acceptance. Those test sources were not included in this distribution archive, and broad third-party compatibility remains unverified.
