# Herb data and client API sources

## Scope and audit

The catalogue contains the 28 standard Vanilla herb-node products plus three marketable secondary herb drops (Swiftthistle, Wildvine, Bloodvine). Expansion herbs and quest-only plants are excluded. Required skill means minimum effective Herbalism skill for a source node, not the character level, a guarantee of success, or a gold/hour estimate.

All 31 item ID/name pairs and the 30 directly tabulated gathering thresholds were compared programmatically with the sources below. Bloodvine's 210 threshold is derived from its lowest-skill source, the Zul'Gurub Purple Lotus; the source also requires a Blood Scythe in inventory. These are community-maintained Vanilla records, cross-checked with a gathering catalogue, not a live Blizzard server database. The exact build's in-game gathering behavior still needs the checklist; no 1.12 executable API is used in the addon.

1. [CMaNGOS Classic DB](https://github.com/cmangos/classic-db/tree/ec4f596146be6467ea93c57397858e329e2db852), `Full_DB/ClassicDB_1_12_1_z2815.sql.gz`: `item_template` verifies IDs and English item names. `gameobject_loot_template` verifies secondary herb drops. Zul'Gurub loot entries 17200–17204 contain Bloodvine (19726), condition 241 requires item 19727 (Blood Scythe), and object 180165 is Purple Lotus using loot entry 17200. The other eligible nodes are Sungrass, Golden Sansam, Dreamfoil and Mountain Silversage.
2. [Vanilla Gatherer, GatherIcons.lua](https://github.com/laytya/Gatherer/blob/5a4948e56d98537d1b0bc1351e86532fabd52e90/GatherIcons.lua), `Gather_SkillLevel`: minimum Herbalism requirements, including Swiftthistle 50 and Wildvine 210. Used as factual data reference only; no addon code or assets copied.
3. [GatherMate2 catalogue](https://github.com/Nevcairiel/GatherMate2/blob/bff600d728764b0d89a904d4f0d36d931d58e85b/Constants.lua), `Herb Gathering`, Vanilla entries 401–431: corroborates the 28 node products and identifies the three secondary drops separately from nodes. The source's unrelated expansion entries are excluded.
4. [Blizzard UI source mirror, Classic Era](https://github.com/Gethe/wow-ui-source/tree/8165d4cd6e48d606369336cc3a7977902310e81e): `Blizzard_APIDocumentationGenerated/ItemDocumentation.lua` confirms `C_Item.GetItemInfo`, `C_Item.GetItemIconByID`, `C_Item.RequestLoadItemDataByID` and `ITEM_DATA_LOAD_RESULT`; `Blizzard_UIPanels_Game/Classic/SkillFrame.lua` confirms `GetSkillLineInfo`, skill header handling and `SKILL_LINES_CHANGED`. This is an Era source snapshot, not a claim that the mirror is exactly build 70003. Client version and TOC interface are taken from the user's screenshot.
5. The supplied Auctionator 341 source verifies the pricing interface independently of the above data. See [INTEGRATION.md](INTEGRATION.md) for paths, semantics and checksums.

Item names and icons are resolved from the running client by item ID. The addon does not distribute Blizzard art or depend on the research repositories at runtime.

## Catalogue

| Herb | Item ID | Minimum Herbalism |
| --- | --- | --- |
| Peacebloom | 2447 | 1 |
| Silverleaf | 765 | 1 |
| Earthroot | 2449 | 15 |
| Mageroyal | 785 | 50 |
| Swiftthistle | 2452 | 50 |
| Briarthorn | 2450 | 75 |
| Stranglekelp | 3820 | 85 |
| Bruiseweed | 2453 | 100 |
| Wild Steelbloom | 3355 | 115 |
| Grave Moss | 3369 | 120 |
| Kingsblood | 3356 | 125 |
| Liferoot | 3357 | 150 |
| Fadeleaf | 3818 | 160 |
| Goldthorn | 3821 | 175 |
| Khadgar's Whisker | 3358 | 185 |
| Wintersbite | 3819 | 195 |
| Firebloom | 4625 | 205 |
| Purple Lotus | 8831 | 210 |
| Wildvine | 8153 | 210 |
| Bloodvine | 19726 | 210 |
| Arthas' Tears | 8836 | 220 |
| Sungrass | 8838 | 230 |
| Blindweed | 8839 | 235 |
| Ghost Mushroom | 8845 | 245 |
| Gromsblood | 8846 | 250 |
| Golden Sansam | 13464 | 260 |
| Dreamfoil | 13463 | 270 |
| Mountain Silversage | 13465 | 280 |
| Plaguebloom | 13466 | 285 |
| Icecap | 13467 | 290 |
| Black Lotus | 13468 | 300 |

Swiftthistle: Mageroyal (50) / Briarthorn (75). Wildvine: Purple Lotus (210). Bloodvine: Zul'Gurub herbs, minimum Purple Lotus (210), plus Blood Scythe. For secondary herbs the skill column describes the minimum source; it must not be interpreted as a standalone node.
