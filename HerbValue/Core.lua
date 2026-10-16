local addonName, HV = ...
local events = CreateFrame("Frame")
-- Skill-line names, not the differently named Herb Gathering cast spell.
local herbalismNames = {
    enUS = "Herbalism", enGB = "Herbalism", deDE = "Kräuterkunde",
    frFR = "Herboristerie", esES = "Herboristería", esMX = "Herboristería",
    itIT = "Erbalismo", ptBR = "Herborismo", ruRU = "Травничество",
    koKR = "약초채집", zhCN = "草药学", zhTW = "草藥學",
}

function HV:UpdateSkill()
    if self.readingSkill then return end
    self.readingSkill = true
    local wanted = herbalismNames[GetLocale()] or "Herbalism"
    local collapsed = {}
    -- Classic hides children of collapsed skill headers. Preserve the user's
    -- header state; expansion/collapse events are synchronous and guarded below.
    for i = GetNumSkillLines(), 1, -1 do
        local name, header, expanded = GetSkillLineInfo(i)
        if header and not expanded then
            collapsed[name] = true
            ExpandSkillHeader(i)
        end
    end
    self.skill = 0
    for i = 1, GetNumSkillLines() do
        local name, header, _, rank, temporary, modifier = GetSkillLineInfo(i)
        if not header and name == wanted then
            self.skill = math.max(0, (rank or 0) + (temporary or 0) + (modifier or 0))
            break
        end
    end
    for i = GetNumSkillLines(), 1, -1 do
        local name, header = GetSkillLineInfo(i)
        if header and collapsed[name] then CollapseSkillHeader(i) end
    end
    self.readingSkill = false
end

function HV:LoadItem(herb)
    local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(herb.id)
    if name then herb.displayName = name end
    herb.icon = icon or C_Item.GetItemIconByID(herb.id) or herb.icon
    if not name and not herb.requested then
        herb.requested = true
        C_Item.RequestLoadItemDataByID(herb.id)
    end
end

function HV:QueueRefresh()
    if self.pendingRefresh then return end
    self.pendingRefresh = true
    C_Timer.After(0, function()
        self.pendingRefresh = false
        self:Refresh()
    end)
end

function HV:Refresh()
    if not self.started then return end
    self:UpdateSkill()
    for _, herb in ipairs(self.herbs) do self:LoadItem(herb) end
    self.Prices:Subscribe(function() self:QueueRefresh() end)
    self.Prices:Refresh()
    self.UI:Render()
end

events:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == addonName then
        HerbValueDB = HV.Model.Preferences(HerbValueDB)
        HV.db = HerbValueDB
    elseif event == "PLAYER_LOGIN" then
        HV.started = true
        HV:Refresh()
        HV.UI:Create()
    elseif event == "ADDON_LOADED" and arg1 == "Auctionator" and HV.started then
        HV:QueueRefresh()
    elseif event == "SKILL_LINES_CHANGED" and HV.started and not HV.readingSkill then
        HV:UpdateSkill()
        HV.UI:Render()
    elseif event == "ITEM_DATA_LOAD_RESULT" and HV.started and arg2 and HV.byID[arg1] then
        HV:LoadItem(HV.byID[arg1])
        HV.UI:Render()
    end
end)
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:RegisterEvent("ITEM_DATA_LOAD_RESULT")

SLASH_HERBVALUE1 = "/herbvalue"
SLASH_HERBVALUE2 = "/hv"
SlashCmdList.HERBVALUE = function(message)
    if not HV.UI.frame then return end
    if string.lower(message or ""):match("^%s*reset%s*$") then
        HV.UI:ResetPosition()
        HV.UI.frame:Show()
    else
        HV.UI.frame:SetShown(not HV.UI.frame:IsShown())
    end
end
