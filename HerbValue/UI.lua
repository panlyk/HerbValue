local _, HV = ...
HV.UI = {}
local UI = HV.UI
local WIDTH, HEIGHT, ROW_HEIGHT = 700, 600, 27

local function label(parent, text, x, y, width, font)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetWidth(width)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
end

local function button(parent, text, x, y, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 24)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

function UI:SavePosition()
    local x, y = self.frame:GetCenter()
    local px, py = UIParent:GetCenter()
    if x and px then HV.db.position = {x = x - px, y = y - py} end
end

function UI:ResetPosition()
    HV.db.position = nil
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function UI:Create()
    local f = CreateFrame("Frame", "HerbValueFrame", UIParent, "BackdropTemplate")
    self.frame = f
    f:Hide()
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 32,
        edgeSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
    f:SetBackdropColor(0.06, 0.08, 0.06, 0.98)
    local p = HV.db.position or {x = 0, y = 0}
    f:SetPoint("CENTER", UIParent, "CENTER", p.x, p.y)
    table.insert(UISpecialFrames, "HerbValueFrame")

    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", 8, -5)
    drag:SetPoint("TOPRIGHT", -35, -5)
    drag:SetHeight(31)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function() f:StopMovingOrSizing(); self:SavePosition() end)
    label(drag, "HerbValue", 8, -8, 145, "GameFontNormalLarge")
    label(drag, "Classic Hardcore  |  drag to move", 165, -10, 330)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() f:Hide() end)

    label(f, "Search", 18, -48, 55)
    local search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    self.search = search
    search:SetSize(205, 23)
    search:SetPoint("TOPLEFT", 77, -42)
    search:SetAutoFocus(false)
    search:SetMaxLetters(100)
    search:SetText(HV.db.search)
    search:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    search:SetScript("OnTextChanged", function(box)
        HV.db.search = box:GetText()
        self.scroll:SetVerticalScroll(0)
        self:Render()
    end)

    local check = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    self.check = check
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", 305, -40)
    check:SetChecked(HV.db.onlyGatherable)
    label(f, "Within my Herbalism skill", 335, -48, 210)
    check:SetScript("OnClick", function(box)
        HV.db.onlyGatherable = box:GetChecked() == true
        self.scroll:SetVerticalScroll(0)
        HV:UpdateSkill()
        self:Render()
    end)
    self.refresh = button(f, "Refresh", 585, -42, 95, function() HV:Refresh() end)

    label(f, "Sort:", 18, -84, 38)
    self.sortButtons = {}
    for index, entry in ipairs({{"price", "Price: high first"}, {"name", "Name: A-Z"}, {"skill", "Skill: low first"}}) do
        local key = entry[1]
        self.sortButtons[key] = button(f, entry[2], 60 + (index - 1) * 145, -77, 139, function()
            HV.db.sort = key
            self.scroll:SetVerticalScroll(0)
            self:Render()
        end)
    end
    self.skill = label(f, "", 510, -84, 175)
    self.status = label(f, "", 18, -113, 660)
    self.status:SetHeight(36)
    self.status:SetJustifyV("TOP")
    label(f, "Herb (* secondary drop)", 50, -155, 242, "GameFontNormal")
    label(f, "Skill", 302, -155, 65, "GameFontNormal")
    label(f, "Buyout / item", 375, -155, 155, "GameFontNormal")
    label(f, "Age (days)", 548, -155, 100, "GameFontNormal")

    local scroll = CreateFrame("ScrollFrame", "HerbValueScrollFrame", f, "UIPanelScrollFrameTemplate")
    self.scroll = scroll
    scroll:SetPoint("TOPLEFT", 18, -176)
    scroll:SetPoint("BOTTOMRIGHT", -38, 80)
    local content = CreateFrame("Frame", nil, scroll)
    self.content = content
    content:SetSize(640, #HV.herbs * ROW_HEIGHT)
    scroll:SetScrollChild(content)
    self.rows = {}
    for i = 1, #HV.herbs do
        local row = CreateFrame("Button", nil, content)
        self.rows[i] = row
        row:SetSize(640, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.35, 0.45, 0.3, i % 2 == 0 and 0.12 or 0.03)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", 2, 0)
        row.name = label(row, "", 32, -7, 242)
        row.skill = label(row, "", 284, -7, 65)
        row.price = label(row, "", 357, -7, 168)
        row.age = label(row, "", 530, -7, 105)
        row:SetScript("OnEnter", function(r)
            if not r.data then return end
            local herb = r.data.herb
            GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
            GameTooltip:SetText(r.data.name)
            GameTooltip:AddLine("Item ID: " .. herb.id .. " | Herbalism: " .. herb.skill, 1, 1, 1)
            if herb.note then GameTooltip:AddLine(herb.note, 1, 0.82, 0, true) end
            GameTooltip:AddLine("Cached minimum buyout per item: " .. HV.Model.Money(r.data.price), 1, 1, 1, true)
            GameTooltip:AddLine("Age: " .. HV.Model.Age(r.data.age, r.data.price), 1, 1, 1)
            GameTooltip:AddLine("Use Auctionator at an auction house to update its cache. Refresh only rereads it.", 0.7, 0.7, 0.7, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    self.empty = label(content, "No herbs match. Clear Search or disable the skill filter.", 10, -10, 610)
    self.empty:Hide()
    self.count = label(f, "", 18, -533, 660)
    label(f, "Cached prices, not live quotes. Run an Auctionator scan to update market data.", 18, -555, 660)
    label(f, "Unit prices only; not gold/hour. Hover * herbs for additional gathering requirements.", 18, -574, 660)
    f:SetScript("OnShow", function() HV.db.visible = true; HV:Refresh() end)
    f:SetScript("OnHide", function()
        f:StopMovingOrSizing()
        HV.db.visible = false
        search:ClearFocus()
        GameTooltip:Hide()
    end)
    self:Render()
    if HV.db.visible then f:Show() end
end

function UI:Render()
    if not self.frame then return end
    local rows = HV.Model.Rows(HV.herbs, HV.Prices.values, HV.db, HV.skill or 0)
    local priced = 0
    for i, row in ipairs(self.rows) do
        local data = rows[i]
        row.data = data
        if data then
            local herb = data.herb
            row.icon:SetTexture(herb.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(data.name .. (herb.note and " *" or ""))
            row.skill:SetText(herb.skill)
            if herb.skill <= (HV.skill or 0) then row.skill:SetTextColor(0.5, 1, 0.5)
            else row.skill:SetTextColor(1, 0.4, 0.4) end
            row.price:SetText(HV.Model.Money(data.price))
            row.age:SetText(HV.Model.Age(data.age, data.price))
            if data.price ~= nil then priced = priced + 1 end
            row:Show()
        else row:Hide() end
    end
    self.empty:SetShown(#rows == 0)
    self.content:SetHeight(math.max(ROW_HEIGHT, #rows * ROW_HEIGHT))
    self.scroll:UpdateScrollChildRect()
    self.scroll:SetVerticalScroll(math.min(self.scroll:GetVerticalScroll(), self.scroll:GetVerticalScrollRange()))
    self.status:SetText(HV.Prices.status or "Reading Auctionator cache...")
    self.skill:SetText("Herbalism: " .. (HV.skill or 0))
    self.count:SetText(string.format("%d / %d herbs shown  |  %d with price data", #rows, #HV.herbs, priced))
    for key, b in pairs(self.sortButtons) do b:SetEnabled(key ~= HV.db.sort) end
end
