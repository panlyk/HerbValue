local _, HV = ...
HV.Model = {}
local M = HV.Model

function M.IsNumber(value)
    return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

function M.Money(copper)
    if not M.IsNumber(copper) then return "No price data" end
    copper = math.floor(copper)
    return string.format("%dg %02ds %02dc", math.floor(copper / 10000),
        math.floor(copper / 100) % 100, copper % 100)
end

function M.Age(days, price)
    if price == nil then return "--" end
    if not M.IsNumber(days) then return "Unknown" end
    if days == 0 then return "Today" end
    return string.format("%dd ago", math.floor(days))
end

function M.Preferences(saved)
    local db = type(saved) == "table" and saved or {}
    if db.sort ~= "name" and db.sort ~= "skill" then db.sort = "price" end
    if type(db.search) ~= "string" then db.search = "" end
    db.search = db.search:sub(1, 100)
    db.onlyGatherable = db.onlyGatherable == true
    if type(db.visible) ~= "boolean" then db.visible = true end
    local p = db.position
    if type(p) ~= "table" or type(p.x) ~= "number" or type(p.y) ~= "number"
        or p.x ~= p.x or p.y ~= p.y or math.abs(p.x) > 10000 or math.abs(p.y) > 10000 then
        db.position = nil
    end
    return db
end

function M.Rows(herbs, prices, prefs, skill)
    local rows = {}
    local query = string.lower(prefs.search):match("^%s*(.-)%s*$")
    for _, herb in ipairs(herbs) do
        local name = herb.displayName or herb.name
        local matches = query == "" or string.find(string.lower(name), query, 1, true)
            or string.find(string.lower(herb.name), query, 1, true)
        if matches and (not prefs.onlyGatherable or herb.skill <= skill) then
            local data = prices[herb.id] or {}
            rows[#rows + 1] = {herb = herb, name = name, price = data.price, age = data.age}
        end
    end
    table.sort(rows, function(a, b)
        if prefs.sort == "price" and a.price ~= b.price then
            if a.price == nil then return false end
            if b.price == nil then return true end
            return a.price > b.price
        elseif prefs.sort == "skill" and a.herb.skill ~= b.herb.skill then
            return a.herb.skill < b.herb.skill
        end
        local an, bn = string.lower(a.name), string.lower(b.name)
        if an ~= bn then return an < bn end
        return a.herb.id < b.herb.id
    end)
    return rows
end
