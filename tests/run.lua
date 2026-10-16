-- Run from repository root: lua5.1 tests/run.lua [path/to/Auctionator]
local HV = {}
local function load(name) assert(loadfile("HerbValue/" .. name .. ".lua"))("HerbValue", HV) end
local passed = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if not ok then error("FAIL " .. name .. ": " .. tostring(err)) end
    passed = passed + 1
    print("PASS " .. name)
end
local function eq(actual, expected)
    assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected))
end
load("Data"); load("Model"); load("Auctionator")
local M, P = HV.Model, HV.Prices

test("31 unique Vanilla herbs, IDs and boundary requirements", function()
    eq(#HV.herbs, 31)
    local seen, secondary = {}, 0
    for _, h in ipairs(HV.herbs) do
        assert(not seen[h.id]); seen[h.id] = true
        assert(h.skill >= 1 and h.skill <= 300)
        if h.note then secondary = secondary + 1 end
    end
    eq(secondary, 3); eq(HV.byID[13468].skill, 300)
    eq(HV.byID[2452].skill, 50); eq(HV.byID[19726].skill, 210)
end)
test("copper formatting preserves zero and distinguishes missing/invalid", function()
    eq(M.Money(123456), "12g 34s 56c"); eq(M.Money(10000), "1g 00s 00c")
    eq(M.Money(99), "0g 00s 99c"); eq(M.Money(0), "0g 00s 00c")
    for _, value in ipairs({false, -1, "100", math.huge, 0/0}) do eq(M.Money(value), "No price data") end
    eq(M.Money(nil), "No price data")
end)
test("age uses days and allows unknown age independently of price", function()
    eq(M.Age(0, 10), "Today"); eq(M.Age(7, 10), "7d ago")
    eq(M.Age(nil, 10), "Unknown"); eq(M.Age(0, nil), "--")
end)
test("preferences default and sanitize without losing valid position", function()
    local p = M.Preferences({sort = "invalid", search = false, position = {x = 0/0, y = 2}})
    eq(p.sort, "price"); eq(p.search, ""); eq(p.position, nil); eq(p.visible, true)
    p = M.Preferences({sort = "skill", search = "Lotus", visible = false, position = {x = 9, y = -10}})
    eq(p.sort, "skill"); eq(p.search, "Lotus"); eq(p.visible, false); eq(p.position.x, 9)
end)
test("price sort puts missing last, including after real zero", function()
    local rows = M.Rows(HV.herbs, {[2447] = {price = 0}, [765] = {price = 123}}, M.Preferences(), 0)
    eq(rows[1].herb.id, 765); eq(rows[2].herb.id, 2447); eq(rows[3].price, nil)
end)
test("name and skill sorts are deterministic", function()
    local p = M.Preferences({sort = "name"})
    local rows = M.Rows(HV.herbs, {}, p, 0)
    eq(rows[1].name, "Arthas' Tears"); eq(rows[#rows].name, "Wintersbite")
    p.sort = "skill"; rows = M.Rows(HV.herbs, {}, p, 0)
    eq(rows[1].name, "Peacebloom"); eq(rows[2].name, "Silverleaf")
    eq(rows[#rows].name, "Black Lotus")
end)
test("search is case insensitive, literal, trimmed and combined with skill filter", function()
    local p = M.Preferences({search = " LOTUS ", onlyGatherable = true})
    eq(#M.Rows(HV.herbs, {}, p, 209), 0)
    eq(#M.Rows(HV.herbs, {}, p, 210), 1)
    eq(#M.Rows(HV.herbs, {}, p, 300), 2)
    p.search = "["; eq(#M.Rows(HV.herbs, {}, p, 300), 0)
    p.search = ""; eq(#M.Rows(HV.herbs, {}, p, 0), 0)
    eq(#M.Rows(HV.herbs, {}, p, 1), 2)
    eq(#M.Rows(HV.herbs, {}, p, 300), 31)
end)
test("localized item names and English fallback both searchable", function()
    HV.byID[765].displayName = "Silberblatt"
    eq(#M.Rows(HV.herbs, {}, M.Preferences({search = "silber"}), 0), 1)
    eq(#M.Rows(HV.herbs, {}, M.Preferences({search = "silverleaf"}), 0), 1)
    HV.byID[765].displayName = nil
end)
test("missing and incompatible Auctionator leave the list usable", function()
    Auctionator = nil; P:Refresh(); assert(P.status:find("missing")); eq(next(P.values), nil)
    Auctionator = {API = {v1 = {}}}; P:Refresh(); assert(P.status:find("incompatible"))
    eq(#M.Rows(HV.herbs, P.values, M.Preferences(), 0), 31)
end)
local callbacks, reads = {}, 0
local api = {
    GetAuctionPriceByItemID = function(caller, id)
        eq(caller, "HerbValue"); reads = reads + 1
        if id == 765 then return 12345 elseif id == 2447 then return 0 end
    end,
    GetAuctionAgeByItemID = function(caller, id) eq(caller, "HerbValue"); if id == 765 then return 2 end end,
    RegisterForDBUpdate = function(caller, fn) eq(caller, "HerbValue"); callbacks[#callbacks + 1] = fn end,
}
test("API adapter reads unit copper and age, subscribes once", function()
    Auctionator = {API = {v1 = api}}
    P:Subscribe(function() end); P:Subscribe(function() end); eq(#callbacks, 1)
    P:Refresh(); eq(reads, 31); eq(P.values[765].price, 12345)
    eq(P.values[765].age, 2); eq(P.values[2447].price, 0); eq(P.values[2450], nil)
end)
test("price exceptions, missing age and callback failures degrade safely", function()
    local price, age, register = api.GetAuctionPriceByItemID, api.GetAuctionAgeByItemID, api.RegisterForDBUpdate
    api.GetAuctionAgeByItemID = function() error("age unavailable") end
    P:Refresh(); eq(P.values[765].price, 12345); eq(P.values[765].age, nil)
    api.GetAuctionPriceByItemID = function() error("not initialized") end
    P:Refresh(); eq(next(P.values), nil); assert(P.status:find("API error"))
    api.GetAuctionPriceByItemID = price; api.GetAuctionAgeByItemID = nil
    api.RegisterForDBUpdate = nil; P:Subscribe(function() end); P:Refresh()
    assert(P.status:find("Automatic updates unavailable")); eq(P.values[765].price, 12345)
    api.RegisterForDBUpdate = function() error("not ready") end; P.subscribed = nil
    P:Subscribe(function() end); eq(P.automatic, false)
    api.GetAuctionAgeByItemID = age; api.RegisterForDBUpdate = register
end)

-- Explicit WoW frame mock: catches missing methods, exercises addon lifecycle.
local frames, timers = {}, {}
local methods = {}
for _, key in ipairs({"SetWidth", "SetHeight", "SetPoint", "ClearAllPoints", "SetJustifyH", "SetJustifyV",
    "SetFrameStrata", "SetClampedToScreen", "SetMovable", "EnableMouse", "SetBackdrop", "SetBackdropColor",
    "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "SetAllPoints", "SetColorTexture", "SetTexture",
    "SetHighlightTexture", "SetAutoFocus", "SetMaxLetters", "ClearFocus", "SetTextColor", "UpdateScrollChildRect"}) do
    methods[key] = function() end
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetScript(key, fn) self.scripts[key] = fn end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:SetText(text)
    self.text = text
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
end
function methods:GetText() return self.text end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetEnabled(value) self.enabled = value end
function methods:SetScrollChild(child) self.child = child end
function methods:SetVerticalScroll(value) self.offset = value end
function methods:GetVerticalScroll() return self.offset or 0 end
function methods:GetVerticalScrollRange() return 500 end
function methods:GetCenter() return self.x or 350, self.y or 300 end
function methods:IsShown() return self.shown end
function methods:SetShown(value)
    if self.shown == value then return end
    self.shown = value
    local fn = self.scripts[value and "OnShow" or "OnHide"]
    if fn then fn(self) end
end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function CreateFrame(kind, name, parent, template)
    local f = setmetatable({scripts = {}, events = {}, shown = true}, {__index = methods})
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
function methods:CreateFontString() return CreateFrame("FontString") end
function methods:CreateTexture() return CreateFrame("Texture") end
local function fire(event, ...)
    for _, f in ipairs(frames) do if f.events[event] then f.scripts.OnEvent(f, event, ...) end end
end
local function drain()
    local pending = timers; timers = {}
    for _, fn in ipairs(pending) do fn() end
end
UIParent = CreateFrame("Frame"); UISpecialFrames = {}; SlashCmdList = {}
GameTooltip = {SetOwner = function() end, SetText = function() end, AddLine = function() end,
    Show = function() end, Hide = function() end}
C_Timer = {After = function(delay, fn) eq(delay, 0); timers[#timers + 1] = fn end}
local rank, locale, expanded, learned = 70, "enUS", false, true
function GetLocale() return locale end
function GetNumSkillLines() return expanded and learned and 2 or 1 end
function GetSkillLineInfo(index)
    if index == 1 then return "Professions", true, expanded end
    return locale == "deDE" and "Kräuterkunde" or "Herbalism", false, nil, rank, 2, 3
end
function ExpandSkillHeader() expanded = true; fire("SKILL_LINES_CHANGED") end
function CollapseSkillHeader() expanded = false; fire("SKILL_LINES_CHANGED") end
local itemReady = false
C_Item = {
    GetItemInfo = function(id)
        if itemReady then return HV.byID[id].name, nil, nil, nil, nil, nil, nil, nil, nil, 123 end
    end,
    GetItemIconByID = function() return 123 end,
    RequestLoadItemDataByID = function() end,
}
load("UI"); load("Core")
test("addon load and login create usable UI, read collapsed skills and preserve headers", function()
    HerbValueDB = nil
    fire("ADDON_LOADED", "HerbValue"); fire("PLAYER_LOGIN")
    eq(HV.skill, 75); eq(expanded, false); eq(#timers, 0)
    eq(#HV.UI.rows, 31); eq(HV.UI.rows[1].data.herb.id, 765)
    eq(HV.UI.frame:IsShown(), true); eq(HV.db.visible, true)
end)
test("live search, filter and sort controls work without rereading the price API", function()
    local before = reads
    HV.UI.search:SetText("Lotus"); assert(HV.UI.count.text:find("2 / 31"))
    HV.UI.check:SetChecked(true); HV.UI.check.scripts.OnClick(HV.UI.check)
    eq(HV.UI.empty:IsShown(), true)
    HV.UI.search:SetText(""); eq(HV.UI.rows[6].data.herb.id, 2452)
    HV.UI.sortButtons.skill.scripts.OnClick(); eq(HV.db.sort, "skill")
    eq(reads, before)
end)
test("skill changes, bonuses, localization and unlearning update filter", function()
    rank = 297; locale = "deDE"; fire("SKILL_LINES_CHANGED")
    eq(HV.skill, 302); eq(HV.UI.rows[31].data.herb.id, 13468); eq(expanded, false)
    learned = false; fire("SKILL_LINES_CHANGED"); eq(HV.skill, 0); eq(HV.UI.empty:IsShown(), true)
    learned = true; locale = "enUS"; rank = 70; fire("SKILL_LINES_CHANGED")
end)
test("uncached item arrival updates names and icons", function()
    itemReady = true; fire("ITEM_DATA_LOAD_RESULT", 765, true)
    eq(HV.byID[765].displayName, "Silverleaf"); eq(HV.byID[765].icon, 123)
end)
test("database notifications coalesce; no timers run continuously", function()
    local before = reads
    callbacks[#callbacks](); callbacks[#callbacks](); callbacks[#callbacks]()
    eq(#timers, 1); drain(); eq(reads, before + 31); eq(#timers, 0)
end)
test("slash toggle, reset, saved visibility/position and manual refresh", function()
    SlashCmdList.HERBVALUE(""); eq(HV.db.visible, false)
    SlashCmdList.HERBVALUE("reset"); eq(HV.UI.frame:IsShown(), true); eq(HV.db.position, nil)
    HV.UI.frame.x = 440; HV.UI.frame.y = 250; HV.UI:SavePosition()
    eq(HV.db.position.x, 90); eq(HV.db.position.y, -50)
    local before = reads; HV.UI.refresh.scripts.OnClick(); eq(reads, before + 31)
end)
test("UI survives missing Auctionator and later addon load", function()
    Auctionator = nil; HV:Refresh(); assert(HV.UI.status.text:find("missing"))
    HV.UI.check:SetChecked(false); HV.UI.check.scripts.OnClick(HV.UI.check)
    eq(HV.UI.rows[1].price.text, "No price data")
    Auctionator = {API = {v1 = api}}; fire("ADDON_LOADED", "Auctionator"); drain()
    eq(P.values[765].price, 12345)
end)

-- Optional integration test using the actual user-supplied Auctionator source.
if arg and arg[1] then
    test("Auctionator 341 real price/age wrappers and LegacyAH callback registration", function()
        local root = arg[1]
        Auctionator = {API = {v1 = {}}, Utilities = {}, Constants = {SCAN_DAY_0 = 0},
            Search = {Events = {PricesProcessed = "prices"}}, FullScan = {Events = {ScanComplete = "scan"}}}
        function LibStub() return {} end
        function time() return 30 * 86400 end
        Auctionator.Utilities.TableKeys = function(t) local r = {}; for k in pairs(t) do r[#r + 1] = k end; return r end
        local receiver, registeredEvents
        Auctionator.EventBus = {Register = function(_, object, names) receiver, registeredEvents = object, names end}
        for _, path in ipairs({"Source/API/Internal.lua", "Source/Database/Mixin.lua", "Source/API/v1/GetAuctionPrice.lua",
            "Source/API/v1/GetAuctionAge.lua", "Source_LegacyAH/API/v1/RegisterForDBUpdate.lua"}) do
            assert(loadfile(root .. "/" .. path))()
        end
        Auctionator.Database = setmetatable({db = {["765"] = {m = 9876, h = {["28"] = 9876}}}},
            {__index = Auctionator.DatabaseMixin})
        local updates = 0; P:Subscribe(function() updates = updates + 1 end); P:Refresh()
        eq(P.values[765].price, 9876); eq(P.values[765].age, 2); eq(P.values[2447], nil)
        eq(registeredEvents[1], "prices"); eq(registeredEvents[2], "scan")
        receiver:ReceiveEvent(); eq(updates, 1)
        Auctionator.Database = nil; P:Refresh(); eq(next(P.values), nil)
    end)
end
print(string.format("%d tests passed", passed))
