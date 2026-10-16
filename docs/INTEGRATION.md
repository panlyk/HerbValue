# Auctionator integration

## Verified target

The supplied `Auctionator.rar` contains a TOC declaring **Version: 341** and including **11509** in its Interface list. The user's screenshot reports **WoW 1.15.9 / 70003 / 11509**. We inspected the archive as source material; embedded instruction files are not part of HerbValue's requirements. No uploaded scripts were executed as installation instructions. The archive is not redistributed.

One unrelated texture (`Images_Classic/UIFrameSimpleMetal.BLP`) could not be decoded by the available archive library. The API, database, TOC, and legacy auction-house Lua files used in this audit extracted successfully. This does not validate installing Auctionator from that partial extraction; use the user's existing installation or a complete official distribution.

## Public API used

| Call | Contract verified in supplied source |
| --- | --- |
| `Auctionator.API.v1.GetAuctionPriceByItemID("HerbValue", itemID)` | Returns cached copper per item, or `nil` when the database or item is unavailable. |
| `Auctionator.API.v1.GetAuctionAgeByItemID("HerbValue", itemID)` | Returns age in scan days, or `nil` when no dated history is available. |
| `Auctionator.API.v1.RegisterForDBUpdate("HerbValue", callback)` | On the Vanilla/LegacyAH path, calls back for `Auctionator.Search.Events.PricesProcessed` and `Auctionator.FullScan.Events.ScanComplete`. |

These are dot calls with a nonempty caller ID, not object-method calls. No auction-house scan, web request, or external price service is initiated by HerbValue.

The price wrapper calls `Database:GetPrice(tostring(itemID))`, which returns field `m`, described in `Source/Database/Mixin.lua` as **last seen minimum price**. `ProcessScan` chooses the minimum from observed listings, and the legacy scan/search paths normalize buyout to unit copper (rounding up). Thus the displayed metric is **last observed minimum buyout per individual item**. It is neither a historical average nor necessarily the lowest listing currently available. HerbValue does not divide by stack size again. Auctionator selects its own active market database; HerbValue does not merge realms or factions.

The age wrapper calls `Database:GetPriceAge`, which computes the difference between the current scan day and the newest retained history day. Its API-file comment mentions a 21-day limit, but the actual implementation reads retained history without an explicit fixed 21-day cutoff. HerbValue displays the returned number unchanged as days and does not invent an exact timestamp or that cutoff. `nil` age can coexist with an available price, especially if dated history has been pruned. No price means `No price data` and age `--`.

## Failure handling and update policy

- Auctionator is an **OptionalDeps** entry so the interface can load without it; when enabled, normal dependency ordering loads Auctionator first.
- The adapter feature-checks API v1, protects external calls with `pcall`, and clears prior displayed prices on refresh before reading fresh results. Missing, invalid, or failed results are never silently zero-filled.
- A missing pricing API produces a clear incompatibility message. Missing age support still permits prices; missing/failing callback registration clearly indicates manual refresh is needed.
- Register once per API table. Update notifications in the same frame coalesce through one `C_Timer.After(0, ...)`. No OnUpdate handler, recurring timer, or polling loop is installed.
- Refresh also runs at login, on opening the window, on manual Refresh, and if Auctionator loads later. Item metadata and skill events update the relevant display without repeatedly querying prices.
- Version 341 is the verified target. Feature detection offers graceful behavior after updates; it is not a guarantee of compatibility with an untested fork/version or a 1.12 backport.

## Audit fingerprints (SHA-256)

| Uploaded path | SHA-256 |
| --- | --- |
| `Auctionator.toc` | `9ea2ac47b91451f23a7db0dbf0f8acd1b1c830ff1b0fed720f312a74008d907e` |
| `Source/API/v1/GetAuctionPrice.lua` | `ec48e4f5485d1e00851b6ea03b295324eeee2ac10fe8b534fc0a117d8682547b` |
| `Source/API/v1/GetAuctionAge.lua` | `20ffd7e57c20f777abec0b50e3b5f722f53a517ad1cd1951a742e6619c47fab9` |
| `Source_LegacyAH/API/v1/RegisterForDBUpdate.lua` | `49131cc6b53ae8cc5bcc77da7eb1aa1d7aafade3c78cb8c76b430fb052d2cc38` |
| `Source/Database/Mixin.lua` | `3bf29b46f517af275c231c925ad0b6e94454119e450b8156ab2130980c769aa9` |
