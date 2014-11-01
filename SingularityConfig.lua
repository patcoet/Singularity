-- local panel = CreateFrame("Frame", "SingularityPanel", UIParent)
-- panel.name = "Singularity"
-- InterfaceOptions_AddCategory(panel)

-- -- local childpanel = CreateFrame("Frame", "SingularityChild", panel)
-- -- childpanel.name = "Child"
-- -- childpanel.parent = panel.name
-- -- InterfaceOptions_AddCategory(childpanel)

-- -- local options = CreateFrame("Frame", SingularityOptions, UIParent)
-- -- options.name = "Singularity"
-- -- InterfaceOptions_AddCategory(options)

-- -- local function createOptions()
-- local a = SingularityDB or {}
--   for k, v in pairs(SingularityDB) do
--     if type(k) == "table" then
--       local f = CreateFrame("Frame", "SingularityChild", panel)
--       f.name = k
--       f.parent = panel.name
--       InterfaceOptions_AddCategory(f)
--   end
--   print(panel:GetNumChildren())
-- -- end

-- -- C_Timer.After(5, createOptions)