# HerbValue

A movable Vanilla herb price list for **official WoW Classic Era / Hardcore 1.15.9, build 70003, interface 11509**, using **Auctionator 341**. These versions come from the supplied client screenshot and Auctionator archive; this is not an original 1.12 addon or a claim of compatibility with every Auctionator release.

## Install

1. Exit WoW, or return to character selection.
2. Extract `HerbValue-1.0.0.zip` into the `Interface/AddOns` directory of the WoW installation you actually use for Hardcore. For the usual Era installation this is `_classic_era_/Interface/AddOns/`.
3. Confirm the resulting path is `Interface/AddOns/HerbValue/HerbValue.toc` (no extra nested `HerbValue` folder).
4. Install/enable Auctionator 341 separately. It is not bundled. Enable HerbValue on the character-selection AddOns screen, then log in.

When installing from this repository, copy only the inner **`HerbValue/`** directory into `Interface/AddOns`, not the entire repository. No libraries or additional runtime dependencies are required beyond Auctionator for prices. Without Auctionator, the list still opens with an explanatory message.

## Use

- `/hv` or `/herbvalue`: toggle the window. Escape or the close button also closes it.
- Drag the title bar to move it; `/hv reset` centers and opens it if needed.
- Default sorting is **price, highest first**, with missing prices last. Choose **Name: A–Z** or **Skill: low first** for other orders. Ties sort by name, then item ID.
- Search by herb name. Localized item names load from the client, with English fallback names and English search also supported. The interface labels are English.
- **Within my Herbalism skill** filters by effective Herbalism rank, including reported temporary points and skill modifiers. A character without Herbalism sees no entries with this filter enabled.
- **Refresh** rereads Auctionator's local cache; it does **not** perform an auction scan. Scan or search at an auction house with Auctionator to obtain fresh prices. HerbValue also updates when Auctionator reports processed search prices or a completed scan.
- Hover a row for details. `*` marks Swiftthistle, Wildvine, and Bloodvine, which are secondary drops rather than independent herb nodes. Bloodvine additionally requires a Blood Scythe in the bags and access to Zul'Gurub. The skill filter only checks skill, not these extra conditions.
- Position, search, sort, filter, and window visibility are saved **per character** by WoW on normal logout or `/reload`.

Each of the 31 rows includes an item icon, name, gathering skill, unit price in `gold / silver / copper` notation (`12g 34s 56c`), and cached price age. Uncached item metadata temporarily uses its English name/question-mark icon and updates when item data arrives. Missing market data is **No price data**, never substituted with zero. Missing age is **Unknown**; **Today** means Auctionator reports zero days, not a real-time quote.

These are unit-price rankings, **not gold/hour estimates**. They do not model node density, travel, risk, sales volume, auction deposits/cuts, or demand. Prices can be stale or manipulated, and high prices do not guarantee sales. Self-Found Hardcore characters cannot use the auction house while Self-Found restrictions apply; the addon does not bypass that restriction.

## Integration and verification

See [Auctionator integration](docs/INTEGRATION.md), [herb sources and full data table](docs/DATA-SOURCES.md), and the [in-game testing checklist](docs/TESTING.md).

The standalone Lua 5.1 suite verifies sorting/filtering, missing/error states, formatting, saved preferences, mocked UI lifecycle, skill changes, item loading, slash commands, and event coalescing. An optional integration check loads the real supplied Auctionator API and database functions. **19 checks passed with that integration enabled.** All source files load under Lua 5.1. No WoW client is available in the development environment: visual rendering, actual client event delivery, gathering thresholds on the live server, and SavedVariables persistence across real sessions still require the in-game checklist.

## Develop and package

Files load in TOC order. `Data.lua` holds the herb catalogue; `Model.lua` handles formatting/filtering/sorting; `Auctionator.lua` is the replaceable price adapter; `UI.lua` renders the window; `Core.lua` handles client events, item metadata, skill detection, and lifecycle. Prices are never copied into HerbValue's SavedVariables.

Run from the repository root:

```sh
lua5.1 tests/run.lua
# Optional: verify against an extracted, trusted Auctionator 341 source tree:
lua5.1 tests/run.lua /path/to/Auctionator
```

If Lua 5.1 is unavailable, the optional developer-only Python runner uses Lupa's Lua 5.1 runtime:

```sh
python -m pip install lupa
python tests/run.py /path/to/Auctionator
```

Build the installable ZIP using Python's standard library:

```sh
python tools/package.py
```

Tests and packaging tools are not loaded by WoW or required by players.
