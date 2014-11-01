-- TODO: Sort functions and stuff before releasing
-- TODO: Do all TODOs
-- TODO: Probably remove a bunch of for pairs do things
-- TODO: Refactor literally everything
-- TODO: Check that we're not passing more information around than we need to


local baseDurations = { -- May have to be updated in future patches
  ["Shadow Word: Pain"] = 18,
  ["Vampiric Touch"] = 15,
  -- ["Void Entropy"] = 60, -- We probably don't care about this
}

local units = {
  ["player"] = "",
  ["target"] = "",
  -- ["focus"] = "",
  ["mouseover"] = "",
  -- ["boss1"] = "",
  -- ["boss2"] = "",
  -- ["boss3"] = "",
  -- ["boss4"] = "",
  -- ["boss5"] = "",
}

local buffs = {
  ["Shadow Word: Insanity"] = 132573, -- 2s/Orb (6s)
  ["Glyph of Mind Spike"] = 81292, -- 8s
  ["Surge of Darkness"] = 87160, -- 10s
  -- ["Shadowy Insight"] = 124430, -- 12s
}

local debuffs = {
  ["Mind Flay"] = 15407, -- 3s
  ["Insanity"] = 129197, -- 3s
  ["Mind Sear"] = 48045, -- 5s
  -- ["Devouring Plague"] = 158831, -- 6s
  ["Vampiric Touch"] = 34914, -- 15s
  ["Shadow Word: Pain"] = 589, -- 18s
  ["Void Entropy"] = 155361, -- 60s; TODO: Check this at 100
}

cooldowns = {
  ["Shadow Word: Death"] = 32379, --8s
  ["Mind Blast"] = 8092, -- 9s
  ["Divine Star"] = 122121, -- 15s
  ["Cascade"] = 127632, -- 25s
  ["Halo"] = 120644, -- 40s
  ["Mindbender"] = 123040, -- 60s
  -- ["Power Infusion"] = 10060, -- 120s
  ["Shadowfiend"] = 34433, -- 180s
}

local relevantTypes = { -- COMBAT_LOG_EVENT_UNFILTERED subtypes
  ["SPELL_CAST_SUCCESS"] = "",
  ["SPELL_AURA_APPLIED"] = "",
  -- "SPELL_PERIODIC_DAMAGE",
  ["SPELL_AURA_REFRESH"] = "",
  ["SPELL_AURA_REMOVED"] = "",
  ["SPELL_AURA_APPLIED_DOSE"] = "",
}

local targetingEvents = {
  ["PLAYER_TARGET_CHANGED"] = "",
  ["UPDATE_MOUSEOVER_UNIT"] = "",
}

local priorityList = {
  "Insanity", "Mind Flay",
  "Mind Sear",
  -- "Devouring Plague",
  "Shadow Word: Insanity",
  "Mind Blast",
  "Glyph of Mind Spike",
  "Shadow Word: Death",
  "Surge of Darkness",
  -- "Shadowy Insight",
  "Divine Star", "Vampiric Touch",
  "Shadow Word: Pain",
  "Cascade",
  "Halo",
  "Mindbender", "Void Entropy",
  -- "Power Infusion",
  "Shadowfiend",
}

activeDebuffs = {} -- A list of all DoTs we have active. {{["targetGUID"], ["targetName"], ["spellName"], ["spellID"], ["expires"]}, ...}
local targetBarContainer = CreateFrame("Frame", nil, UIParent)
targetBars = {} -- A list of bar frames for the target+player units. {["spellName"] = CreateFrame, ...}
local f = CreateFrame("Frame") -- For RegisterEvent and such

local function isInList(item, list) -- Utility function
  for k, v in pairs(list) do
    if k == item then
      return true
    end
  end
  return false
end

local function setupBar(barFrame, backdrop)
  local b = barFrame
  b.baseHeight = 30
  b.baseWidth = 200
  b.iconTexture = b:CreateTexture()
  b.iconTexture:SetPoint("RIGHT", b, "LEFT", -1, 0)
  b.iconTexture:SetSize(b.baseHeight, b.baseHeight)
  b.iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
  b.iconTexture:SetTexture(select(3, GetSpellInfo(b.spellID)))
  -- b:SetBackdrop(backdrop)
  -- b:SetBackdropBorderColor(0, 0, 0, 1)
  -- b:SetBackdropColor(0, 0, 0, 0.5)
  -- b:SetPoint("TOP", b:GetParent(), "TOP", 0, -b:GetParent():GetNumChildren() * (b.baseHeight + 1) - 2)
  b:SetSize(b.baseWidth, b.baseHeight)
  b.stackText = b:CreateFontString()
  b.stackText:SetFont("Fonts\\FRIZQT__.ttf", 16, "OUTLINE")
  b.stackText:SetPoint("CENTER", b.iconTexture, "CENTER")
  b.texture = b:CreateTexture()
  b.texture.baseWidth = b.baseWidth
  b.texture:SetPoint("LEFT", b, "LEFT", 1, 0)
  b.texture:SetHeight(b.baseHeight)
  b.timeScaleMax = 12
end

local function rearrangeTargetBars()
  local offset = -2
  for n, spellName in ipairs(priorityList) do
    if targetBars[spellName]:IsShown() then
      targetBars[spellName]:SetPoint("TOP", targetBarContainer, "TOP", targetBars[spellName].iconTexture:GetWidth() / 2, offset)
      if spellName ~= "Insanity" and spellName ~= "Mind Flay" then
        offset = offset - targetBars[spellName]:GetHeight() - 1
      end
    end
  end
  targetBarContainer:SetHeight(-offset + 1)
end

local function missingTalent(row, column)
  return not select(4, GetTalentInfo(row, column, GetActiveSpecGroup()))
end

local function shouldShowBar(spellName)
  if spellName == "Surge of Darkness" and missingTalent(3, 1) then
    return false
  elseif spellName == "Mindbender" and missingTalent(3, 2) then
    return false
  elseif spellName == "Shadow Word: Insanity" and missingTalent(3, 3) then
    return false
  elseif spellName == "Power Infusion" and missingTalent(5, 2) then
    return false
  elseif spellName == "Shadowy Insight" and missingTalent(5, 3) then
    return false
  elseif spellName == "Cascade" and missingTalent(6, 1) then
    return false
  elseif spellName == "Divine Star" and missingTalent(6, 2) then
    return false
  elseif spellName == "Halo" and missingTalent(6, 3) then
    return false
  elseif spellName == "Void Entropy" and missingTalent(7, 2) then
    return false
  else
    return true
  end
end

local function showTargetBars()
  for spellName, frame in pairs(targetBars) do
    if shouldShowBar(spellName) and spellName ~= "Glyph of Mind Spike" then
      frame:Show()
    else
      frame:Hide()
    end

    if spellName == "Mind Flay" or spellName == "Mind Sear" or spellName == "Insanity" then
      frame.stackText:SetText(select(4, UnitBuff("player", "Glyph of Mind Spike")))
    end

    if frame.active then
      -- frame:Show()
      -- frame:SetAlpha(1)
    else
      -- frame:Hide()
      -- frame:SetAlpha(0)
    end
  end
  rearrangeTargetBars()
end

local function init()
  local backdrop = { -- TODO: Configuration options for this
    bgFile = "Interface\\CHATFRAME\\CHATFRAMEBACKGROUND",
    edgeFile = "Interface\\AddOns\\Singularity\\SolidBorder",
    tile = false,
    tileSize = 32,
    edgeSize = 1,
    insets = {
    left = 1,
    right = 1,
    top = 1,
    bottom = 1
    }
  }

  local rc = LibStub("LibRangeCheck-2.0")

  for k, v in pairs(cooldowns) do
    targetBars[k] = CreateFrame("Frame", k, targetBarContainer)
    targetBars[k].active = false
    targetBars[k].spellID = v
    setupBar(targetBars[k], backdrop)
  end
  for k, v in pairs(buffs) do
    targetBars[k] = CreateFrame("Frame", k, targetBarContainer)
    targetBars[k].active = false
    targetBars[k].spellID = v
    setupBar(targetBars[k], backdrop)
  end
  for k, v in pairs(debuffs) do
    targetBars[k] = CreateFrame("Frame", k, targetBarContainer)
    targetBars[k].active = false
    targetBars[k].spellID = v
    targetBars[k].checkForSafeTime = true
    setupBar(targetBars[k], backdrop)
  end

  local yOffset = 0

  showTargetBars()
  targetBars["Mind Sear"]:SetAlpha(0)
  targetBars["Insanity"]:SetAlpha(0)
  targetBarContainer:SetPoint("TOP", UIParent, "CENTER", 0, 200)
  targetBarContainer:SetBackdrop(backdrop)
  targetBarContainer:SetBackdropBorderColor(0, 0, 0, 1)
  targetBarContainer:SetBackdropColor(0, 0, 0, 0.5)
  targetBarContainer:SetSize(targetBars["Mind Blast"]:GetWidth() + targetBars["Mind Blast"].iconTexture:GetWidth() + 1 + 4, 10)
end

local function runTimer(frame, expires)
  frame:SetScript("OnUpdate", function()
    if not frame.active then
      frame.texture:SetTexture(0,0,0,0)
      showTargetBars()
      frame:SetScript("OnUpdate", nil)
    else
      if frame:GetName() == "Glyph of Mind Spike" or frame:GetName() == "Surge of Darkness" or frame:GetName() == "Shadowy Insight" then
        expires = select(7, UnitBuff("player", frame:GetName())) or 0
      end
      if isInList(frame:GetName(), cooldowns) then
        local started, cooldown = GetSpellCooldown(frame:GetName())
        expires = started + cooldown
      end
      local timeLeft = expires - GetTime()

      if timeLeft > 0 then
        frame.texture:SetTexture(0,0.7,0,1)
        if timeLeft >= frame.timeScaleMax then
          frame.texture:SetWidth(frame.texture.baseWidth)
        else
          local b = baseDurations[frame:GetName()]
          if b and timeLeft < b * 0.3 or false then -- 6.0 DoTs 30% thing
            frame.texture:SetTexture(0.7,0,0,1)
          end
          frame.texture:SetWidth(frame.texture.baseWidth * timeLeft / frame.timeScaleMax)
        end
      else
        frame.active = false
        frame.texture:SetTexture(0,0,0,0)
        showTargetBars()
        frame:SetScript("OnUpdate", nil)
      end
    end
  end)
end

local function readFromDebuffList()
  for i, entry in ipairs(activeDebuffs) do
    for unit, _ in pairs(units) do
      if UnitGUID(unit) == entry["targetGUID"] then
        targetBars[entry["spellName"]].active = true
        runTimer(targetBars[entry["spellName"]], entry["expires"])
        if entry["spellName"] == "Mind Flay" then
          targetBars["Mind Flay"]:SetAlpha(1)
          targetBars["Mind Sear"]:SetAlpha(0)
          targetBars["Insanity"]:SetAlpha(0)
        elseif entry["spellName"] == "Mind Sear" then
          targetBars["Mind Flay"]:SetAlpha(0)
          targetBars["Mind Sear"]:SetAlpha(1)
          targetBars["Insanity"]:SetAlpha(0)
        elseif entry["spellName"] == "Insanity" then
          targetBars["Mind Flay"]:SetAlpha(0)
          targetBars["Mind Sear"]:SetAlpha(0)
          targetBars["Insanity"]:SetAlpha(1)
        end
        break
      end
    end
  end

  showTargetBars()
  rearrangeTargetBars()
end

local function insertIntoDebuffList(targetGUID, targetName, spellName, spellID, expires) -- Add one entry to the debuff list
  for k, v in ipairs(activeDebuffs) do
    if v["targetGUID"] == targetGUID and v["spellName"] == spellName then
      table.remove(activeDebuffs, k)
      break
    end
  end

  table.insert(activeDebuffs, {["targetGUID"] = targetGUID, ["targetName"] = targetName, ["spellName"] = spellName, ["spellID"] = spellID, ["expires"] = expires})
  readFromDebuffList()
end

local function removeFromDebuffList(targetGUID, spellName) -- Remove one entry from the debuff list
  for k, v in ipairs(activeDebuffs) do
    if v["targetGUID"] == targetGUID and v["spellName"] == spellName then
      table.remove(activeDebuffs, k)
      readFromDebuffList()
      return
    end
  end
end

local function updateOrbsText()
  local orbs = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
  orbs = orbs > 0 and orbs or "" -- Show nothing at 0 Orbs
  targetBars["Mind Blast"].stackText:SetText(orbs)
end

local function processEvents(self, event, ...)
  if isInList(event, targetingEvents) then
    for spell, _ in pairs(debuffs) do
      targetBars[spell].active = false
    end

    for spellName, spellID in pairs(debuffs) do
      local expires = select(7, UnitDebuff("target", spellName, "", "PLAYER"))

      if expires ~= nil then
        insertIntoDebuffList(UnitGUID("target"), UnitName("target"), spellName, spellID, expires)
      end
    end
    readFromDebuffList()
  elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
    targetBars["Mind Flay"].active = false
    targetBars["Mind Sear"].active = false
    targetBars["Insanity"].active = false
  elseif event == "PLAYER_ENTERING_WORLD" then
    for spellName, _ in pairs(buffs) do
      local expires = select(7, UnitBuff("player", spellName))
      if expires ~= nil then
        targetBars[spellName].active = true
        runTimer(targetBars[spellName], expires)
      end
    end

    for spellName, _ in pairs(cooldowns) do
      local cd = GetSpellCooldown(spellName)
      if cd ~= nil and cd ~= 0 then
        targetBars[spellName].active = true
        runTimer(targetBars[spellName], 0)
      end
    end
    updateOrbsText()
    readFromDebuffList()
  elseif event == "PLAYER_TALENT_UPDATE" then
    showTargetBars()
  else
    local _, type, _, sourceGUID, sourceName, _, _, targetGUID, targetName, _, _,spellID, spellName, _, numOrbs, powerType = ...

    if (type == "SPELL_CAST_SUCCESS" or type == "SPELL_AURA_APPLIED_DOSE") and sourceGUID == UnitGUID("player") and spellName == "Mind Spike" then
      readFromDebuffList()
      -- showTargetBars() -- Show Glyph of Mind Spike stacks on Mind Flay icon
    end

    if (type == "SPELL_ENERGIZE" and powerType == SPELL_POWER_SHADOW_ORBS) or (type == "SPELL_CAST_SUCCESS" and (spellName == "Devouring Plague" or spellName == "Void Entropy" or spellName == "Psychic Horror")) then
      updateOrbsText()
    end

    if isInList(type, relevantTypes) and sourceGUID == UnitGUID("player") and (isInList(spellName, buffs) or isInList(spellName, cooldowns) or isInList(spellName, debuffs)) then

      local unitID = "player"
      for unit, _ in pairs(units) do
        if UnitGUID(unit) == targetGUID then
          unitID = unit
        end
      end

      if isInList(spellName, buffs) then
        local expires = select(7, UnitBuff("player", spellName)) or 0

        if type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_REFRESH" then -- Note that since SPELL_AURA_APPLIED_DOSE fires when you gain stacks but only if you are not already at max stacks we're not handling that type at all here; the timer for each stacked buff is started here, and then RunTimer takes care of reapplications
          targetBars[spellName].active = true
          runTimer(targetBars[spellName], expires)
        end
      elseif isInList(spellName, cooldowns) then
        if type == "SPELL_CAST_SUCCESS" then
          targetBars[spellName].active = true
          runTimer(targetBars[spellName], 0) -- Expire time is checked in RunTimer for cooldowns, so no need to try to get or use it here
        end
      elseif isInList(spellName, debuffs) then
        local expires = select(7, UnitDebuff(unitID, spellName, "", "PLAYER"))

        if expires ~= nil and (type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_REFRESH") then
          insertIntoDebuffList(targetGUID, targetName, spellName, spellID, expires)
        elseif type == "SPELL_AURA_REMOVED" then
          removeFromDebuffList(targetGUID, spellName)
        end
      end
      showTargetBars()
    end
  end
end

local function desaturate(texture, desaturating)
  local shaderSupported = texture:SetDesaturated(desaturating)

  if not shaderSupported then
    if desaturating then
      texture:SetVertexColor(0.5, 0.5, 0.5)
    else
      texture:SetVertexColor(1, 1, 1)
    end
  end
end

local function checkRange()
  if UnitHealth("target") > UnitHealthMax("target") * 0.2 then
    desaturate(targetBars["Shadow Word: Death"].iconTexture, true)
  else
    desaturate(targetBars["Shadow Word: Death"].iconTexture, false)
  end

  if UnitExists("target") then
    local minRange, maxRange = rc:GetRange("target")
    if maxRange == nil then
      return
    end

    local function c(r, g, b)
      -- targetBarContainer:SetBackdropBorderColor(r, g, b, 1)
      for _, v in ipairs({"Cascade", "Divine Star", "Halo"}) do
        if shouldShowBar(v) then
          targetBars[v].stackText:SetTextColor(r, g, b, 1)
          break
        end
      end
    end

    if shouldShowBar("Cascade") then
      targetBars["Cascade"].stackText:SetText(maxRange)
      if maxRange < 40 then
        c(1, 1, 0)
      elseif maxRange == 40 then
        c(0, 1, 0)
      else
        c(1, 0, 0)
      end
    elseif shouldShowBar("Divine Star") then
      targetBars["Divine Star"].stackText:SetText(maxRange)
      if maxRange < 25 then
        c(0, 1, 0)
      elseif maxRange == 25 then
        c(1, 1, 0)
      else
        c(1, 0, 0)
      end
    elseif shouldShowBar("Halo") then
      targetBars["Halo"].stackText:SetText(maxRange)
      if maxRange <= 15 then
        c(1, 0, 0)
      elseif minRange == 15 and maxRange == 20 then
        c(1, 1, 0)
      elseif minRange == 20 and maxRange == 25 then
        c(0, 1, 0)
      elseif minRange == 25 and maxRange == 30 then
        c(1, 1, 0)
      else
        c(1, 0, 0)
      end
    end
  else
    targetBars["Cascade"].stackText:SetTextColor(1, 1, 1, 0)
    targetBars["Divine Star"].stackText:SetTextColor(1, 1, 1, 0)
    targetBars["Halo"].stackText:SetTextColor(1, 1, 1, 0)
  end
end

f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_TALENT_UPDATE")
-- f:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
f:SetScript("OnEvent", processEvents)
f:SetScript("OnUpdate", checkRange)
init()
rearrangeTargetBars()