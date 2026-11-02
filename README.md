# Questie-X CoA

> **[Download](https://github.com/uncle-bone/Questie-X/releases/latest)**

**Quest tracking, map guidance, and community quest learning for Ascension: Conquest of Azeroth / Conquest Reborn (WoW 3.3.5a, Interface 30300).**

> **Support notice:** Questie-X development and support are temporarily paused. v1.6.32 is the highest build currently published here. Bug reports may be left in [Issues](https://github.com/uncle-bone/Questie-X/issues), but responses and fixes are not currently promised.

[Releases](https://github.com/uncle-bone/Questie-X/releases) · [Issues](https://github.com/uncle-bone/Questie-X/issues)

## Features

- World-map and minimap markers for quest givers, turn-ins, objectives, creatures, and objects where data is available.
- Quest-log tracking, searchable quest information, tooltips, navigation and Journey history.
- WotLK, Ascension and CoA database plugins, including custom quest overrides.
- Questie Learner for collecting and retaining supported custom quest discoveries.
- Community discovery sharing via **BBLC25C** alongside LootCollector and DBM-CoA, using distinct message formats.
- Legacy-client map, startup, cache and communication compatibility adaptations.

**Accuracy notice:** Stock WotLK quests are not automatically available on Conquest Reborn. Custom quest locations and learned records can be incomplete. Map compatibility with every UI addon, and reliable learning across mixed client versions, have not been verified universally.

## Version / repository status

- **Latest available build:** v1.6.32 — [Download](https://github.com/uncle-bone/Questie-X/releases/download/v1.6.32/Questie-X-v1.6.32.zip).
- Packages the five addon folders from the repository main branch.
- This package does not include the separately generated v1.6.25 map-syntax fix. Confirm Pale Reach map behavior in game.
- Earlier startup FPS degradation has not been confirmed resolved. Existing SavedVariables are preserved.
- **Support is temporarily paused; no newer build is being promoted as a stable release during this pause.**

## Install

1. Back up relevant `WTF/Account/.../SavedVariables`, especially learner data.
2. Download the [latest available release](https://github.com/uncle-bone/Questie-X/releases).
3. Extract the included addon folders **side by side** into `Interface/AddOns/`: `Questie-X`, `Questie-X-AscensionDB`, `Questie-X-CoADB`, `Questie-X-WotLKDB`, and `Questie-X-WotLK-Locale` where provided.
4. Restart the client and enable the modules. Avoid installing a second Questie fork simultaneously.

If quest pins are missing, verify that all required database plugins are enabled. Never delete SavedVariables to troubleshoot without a backup.

## Compatibility and limitations

Designed for Conquest Reborn's older WoW client. The project targets the default Blizzard map as well as Mapster/Magnify, ConquestWorldMapImprovement, DragonUI, ElvUI-CoA and Leatrix map setups; these combinations require direct in-game validation. Large quest databases can cause memory use and startup pauses.

## Maintenance and credits

CoA adaptation maintained by **Uncle Bone** ([GitHub](https://github.com/uncle-bone)). Based on the work of [Questie](https://github.com/Questie/Questie), [Questie-X](https://github.com/Xurkon/Questie-X), and their contributors. Preserve upstream licenses and credits. Not an official Ascension project.

