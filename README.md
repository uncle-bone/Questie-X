# Questie-X — Quest Helper & Community Quest Learning for Conquest of Azeroth

> **[⬇ Download v1.6.9](https://github.com/downingwow/Questie-X/releases/download/v1.6.9/Questie-X-CoA-v1.6.9-Bounded-Cache-Test.zip)**

**Current release: v1.6.9 — bounded-cache test build.**


**Questie-X helps you find quests, understand where to go, and learn about custom quests that aren't in a normal World of Warcraft database.** It is an adapted version of the Questie-X quest helper for **Ascension: Conquest of Azeroth**, especially **Conquest Reborn**.

## What you see in game

- **Quest icons on your world map and minimap.** Find where quest-givers, objectives, creatures, and interactive objects are believed to be.
- **Quest tracking and progress.** Keep track of active quests and their objectives without constantly reopening the quest log.
- **Quest guidance and navigation.** Map pins, tooltips, and arrow/navigation features help you reach an objective.
- **Quest information and search.** Questie-X uses quest, creature, object, and item databases to explain where quests begin and what they require.
- **Quest history.** The Questie Journey system retains information about your questing progress.

Locations depend on the database and on what players have discovered; custom CoA content may initially be missing or inaccurate.

## Questie Learner: discovering custom content

Normal quest addons know about official WoW quests, but Conquest of Azeroth includes custom content. **Questie Learner** is designed to fill those gaps as you play.

- Observes supported quest, NPC, objective, and related game events to build up a local record.
- Saves learned information between sessions, so you don't have to rediscover it every login.
- Can use imported learner information to start with a larger pool of discoveries.
- Displays learned location information through the quest-helper map interface.
- Shares compatible discovery data with other players running supported addon builds, helping the community gradually improve coverage.
- Includes deduplication and throttling work intended to reduce repeated map-pin updates and performance impact.

**What learning does not mean:** the addon does not automatically know every custom quest or guarantee a perfect location the first time someone encounters an NPC. Discoveries improve through observation and data sharing.

## How community sharing works

Questie-X cooperates with LootCollector and DBM-CoA using LootCollector's existing public sharing channel **`BBLC25C`**. Each addon uses its own message format so their traffic can be distinguished. The current CoA patch delays channel setup during login to reduce channel conflicts. Sharing depends on other compatible players being online and connected; it is not a central always-on database.

## Performance and compatibility

The CoA patches include work on older-client API compatibility, map zoom/pin behavior, reducing stutter, and safer chat-channel startup. The underlying Questie-X project includes advanced performance settings and further refactor work; **not every upstream experimental optimization is guaranteed to be in this CoA package**. This is built for the older **Interface 30300** client and should not be assumed compatible with modern retail WoW.

## Important: database plugins are required

**Questie-X is a quest-helper engine, not a complete bundled quest database.** Its upstream installation documentation says it requires **Questie-X-WotLKDB** plus **Questie-X-AscensionDB** for Ascension. The maintainer's GitHub upload now includes additional Questie-X database folders alongside the main addon. Install the database addon folders included with the GitHub source or release alongside the `Questie-X` folder. Without a loaded database, quest pins and quest information will be incomplete or unavailable.

See the upstream [Questie-X project](https://github.com/Xurkon/Questie-X) and its database-plugin documentation for those components. Do not install an old Questie variant simultaneously.

## Install / update

1. Back up your `WTF/Account/.../SavedVariables` files before replacing a test build. These include your learned quest data.
2. Install the Questie-X addon folder in `World of Warcraft/Interface/AddOns/Questie-X`.
3. Install the matching WotLK and Ascension database plugin folders **beside** Questie-X, not inside it.
4. Restart WoW and enable the addon in the character-selection AddOns menu.

If you are updating from an older incompatible Questie fork, remove the old addon folder first. **Do not delete SavedVariables casually**: that can erase locally learned data.

## Current build and downloads

**Current source build: v1.0.0.** CoA baseline with HBD map-data fix. Installable ZIPs and version history are published through [GitHub Releases](https://github.com/downingwow/Questie-X/releases).

## Known limits / status

- Custom quest coverage depends on plugin data, learning, and community reports.
- Performance changes still require real in-game testing, especially in busy areas.
- Channel and addon compatibility may differ across older builds.
- The latest ZIP contains an upstream Questie-X version string as well as CoA-specific patch numbering; these identify different layers of the project.

## Credits and feedback

Based on [Questie](https://github.com/Questie/Questie) and [Questie-X](https://github.com/Xurkon/Questie-X), with their original authors and contributors retaining credit. CoA adaptation and distribution by **Uncle Bone**. Community project; not an official Ascension addon.

[Report a bug / suggest a feature](https://github.com/downingwow/Questie-X/issues) · [Changelog](CHANGELOG.md)


## CoA v1.0.0

CoA release numbering is separate from the upstream Questie-X version. Includes the Patch 12 HBD map-data compatibility fix and existing learner/sharing work. The release includes database plugin folders already maintained in this repository.
