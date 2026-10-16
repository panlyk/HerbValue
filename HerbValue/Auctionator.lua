local _, HV = ...
-- Only this adapter knows about Auctionator. No saved-variable/database access.
-- Verified against the user's Auctionator 341, Source/API/v1 and Source_LegacyAH/API/v1.
HV.Prices = {values = {}}
local P = HV.Prices

function P:API()
    local addon = _G.Auctionator
    local api = type(addon) == "table" and addon.API
    api = type(api) == "table" and api.v1
    if type(api) ~= "table" or type(api.GetAuctionPriceByItemID) ~= "function" then return nil end
    return api
end

function P:Subscribe(onUpdate)
    local api = self:API()
    if not api or type(api.RegisterForDBUpdate) ~= "function" then
        self.automatic = false
        return
    end
    if self.subscribed == api then self.automatic = true; return end
    local ok = pcall(api.RegisterForDBUpdate, "HerbValue", onUpdate)
    self.automatic = ok
    if ok then self.subscribed = api end
end

function P:Refresh()
    self.values = {} -- Never leave stale displayed values after an API failure.
    local api = self:API()
    if not api then
        if _G.Auctionator then
            self.status = "Auctionator is incompatible: pricing API v1 is unavailable. Tested with version 341."
        else
            self.status = "Auctionator is missing or disabled. Enable Auctionator 341 for cached prices."
        end
        return
    end
    local failures = 0
    for _, herb in ipairs(HV.herbs) do
        local ok, price = pcall(api.GetAuctionPriceByItemID, "HerbValue", herb.id)
        if not ok then failures = failures + 1 end
        if ok and HV.Model.IsNumber(price) then
            local age
            if type(api.GetAuctionAgeByItemID) == "function" then
                local ageOK, result = pcall(api.GetAuctionAgeByItemID, "HerbValue", herb.id)
                if ageOK and HV.Model.IsNumber(result) then age = result end
            end
            self.values[herb.id] = {price = price, age = age}
        end
    end
    if failures > 0 then
        self.status = "Auctionator API error: some prices could not be read. Try Refresh or update Auctionator."
    elseif not self.automatic then
        self.status = "Cached minimum buyout / item. Automatic updates unavailable; use Refresh."
    else
        self.status = "Cached minimum buyout / item. Updates after Auctionator searches and scans."
    end
end
