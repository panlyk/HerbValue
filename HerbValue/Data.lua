local _, HV = ...

-- Vanilla / Classic Era herbs. Source audit and secondary-drop semantics:
-- docs/DATA-SOURCES.md. Skill is the minimum source-node gathering skill.
HV.herbs = {
    {id = 2447, name = "Peacebloom", skill = 1},
    {id = 765, name = "Silverleaf", skill = 1},
    {id = 2449, name = "Earthroot", skill = 15},
    {id = 785, name = "Mageroyal", skill = 50},
    {id = 2452, name = "Swiftthistle", skill = 50,
        note = "Secondary drop from Mageroyal (50) and Briarthorn (75)."},
    {id = 2450, name = "Briarthorn", skill = 75},
    {id = 3820, name = "Stranglekelp", skill = 85},
    {id = 2453, name = "Bruiseweed", skill = 100},
    {id = 3355, name = "Wild Steelbloom", skill = 115},
    {id = 3369, name = "Grave Moss", skill = 120},
    {id = 3356, name = "Kingsblood", skill = 125},
    {id = 3357, name = "Liferoot", skill = 150},
    {id = 3818, name = "Fadeleaf", skill = 160},
    {id = 3821, name = "Goldthorn", skill = 175},
    {id = 3358, name = "Khadgar's Whisker", skill = 185},
    {id = 3819, name = "Wintersbite", skill = 195},
    {id = 4625, name = "Firebloom", skill = 205},
    {id = 8831, name = "Purple Lotus", skill = 210},
    {id = 8153, name = "Wildvine", skill = 210,
        note = "Secondary drop from Purple Lotus (210); also obtainable from enemies."},
    {id = 19726, name = "Bloodvine", skill = 210,
        note = "Secondary drop from herbs in Zul'Gurub; requires a Blood Scythe in your bags. Minimum source: Purple Lotus (210). The skill filter does not check the scythe or raid access."},
    {id = 8836, name = "Arthas' Tears", skill = 220},
    {id = 8838, name = "Sungrass", skill = 230},
    {id = 8839, name = "Blindweed", skill = 235},
    {id = 8845, name = "Ghost Mushroom", skill = 245},
    {id = 8846, name = "Gromsblood", skill = 250},
    {id = 13464, name = "Golden Sansam", skill = 260},
    {id = 13463, name = "Dreamfoil", skill = 270},
    {id = 13465, name = "Mountain Silversage", skill = 280},
    {id = 13466, name = "Plaguebloom", skill = 285},
    {id = 13467, name = "Icecap", skill = 290},
    {id = 13468, name = "Black Lotus", skill = 300},
}
HV.byID = {}
for _, herb in ipairs(HV.herbs) do HV.byID[herb.id] = herb end
