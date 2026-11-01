# Questie-X CoA

**Quest tracking, map guidance, and community quest learning for Ascension: Conquest of Azeroth / Conquest Reborn (WoW 3.3.5a, Interface 30300).**

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

- **Repository release manifest:** v1.6.8 (prerelease). This is the source currently configured for automated release packaging; see `.release.json`.
- **More recent test packages:** v1.6.10 map-canvas compatibility, v1.6.11–v1.6.12 CoADB dependency recovery, and v1.6.13 responsive-startup test have been distributed separately in development. **Do not assume these test ZIPs have been pushed into this repository or published as GitHub Releases.**
- v1.6.13 aims to spread post-load initialization across frames, avoid duplicate login initialization, and reduce freezes; **actual in-game performance still needs testing.**
- Existing quest DB content, map behavior, memory caching and BBLC25C sharing should be regression-tested whenever updating.

## Install

1. Back up relevant `WTF/Account/.../SavedVariables`, especially learner data.
2. Download a matching package from [GitHub Releases](https://github.com/uncle-bone/Questie-X/releases).
3. Extract the included addon folders **side by side** into `Interface/AddOns/`: `Questie-X`, `Questie-X-AscensionDB`, `Questie-X-CoADB`, `Questie-X-WotLKDB`, and `Questie-X-WotLK-Locale` where provided.
4. Restart the client and enable the modules. Avoid installing a second Questie fork simultaneously.

If quest pins are missing, verify that all required database plugins are enabled. Never delete SavedVariables to troubleshoot without a backup.

## Compatibility and limitations

Designed for Conquest Reborn's older WoW client. The project targets the default Blizzard map as well as Mapster/Magnify, ConquestWorldMapImprovement, DragonUI, ElvUI-CoA and Leatrix map setups; these combinations require direct in-game validation. Large quest databases can cause memory use and startup pauses; do not interpret test-build optimization notes as benchmark results.

## Maintenance and credits

CoA adaptation maintained by **Uncle Bone** ([GitHub](https://github.com/uncle-bone)). Based on the work of [Questie](https://github.com/Questie/Questie), [Questie-X](https://github.com/Xurkon/Questie-X), and their contributors. Preserve upstream licenses and credits. Not an official Ascension project.

**Report issues:** [Questie-X issues](https://github.com/uncle-bone/Questie-X/issues). Include build, enabled map/UI addons, error text and reproduction steps.
