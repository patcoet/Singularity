-- TODO: Sort functions and stuff before releasing
-- TODO: Do all TODOs
-- TODO: Probably remove a bunch of for pairs do things
-- TODO: Refactor literally everything
-- TODO: Check that we're not passing more information around than we need to

local rc

local defaults = {
  bar = {
    backdrop = {
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\AddOns\\Singularity\\SolidBorder",
      tile = false,
      tileSize = 32,
      edgeSize = 1,
      insets = {
        left = 1,
        right = 1,
        top = 1,
        bottom = 1,
      },
      color = {
        r = 0,
        g = 0,
        b = 0,
        a = 0,
      },
      borderColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0,
      },
    },
    icon = {
      coords = {
        l = 0.1,
        r = 0.9,
        t = 0.1,
        b = 0.9,
      },
      size = 20,
      xOffset = -1,
    },
    text = {
      anchorFrom = "CENTER",
      anchorTo = "CENTER",
      fontPath = "Interface\\AddOns\\Singularity\\Marken.ttf",
      -- fontPath = "Fonts\\FRIZQT__.ttf",
      fontSize = 8,
      fontFlags = "THINOUTLINEMONOCHROME",
      xOffset = 1,
      yOffset = 0,
    },
    texture = {
      alert = {
        r = 0.7,
        g = 0,
        b = 0,
        a = 1,
      },
      color = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 1,
      },
      path = "Interface\\Buttons\\WHITE8X8",
      inset = 0,
    },
    height = 20,
    maxTime = 12,
    spacing = 1,
    width = 200,
  },
  targetContainer = {
    backdrop = {
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\AddOns\\Singularity\\SolidBorder",
      tile = false,
      tileSize = 32,
      edgeSize = 1,
      insets = {
        left = 1,
        right = 1,
        top = 1,
        bottom = 1
      },
      color = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.5,
      },
      borderColor = {
        br = 0,
        bg = 0,
        bb = 0,
        ba = 1,
      },
    },
    anchorFrom = "TOP",
    anchorFrame = "UIParent",
    anchorTo = "CENTER",
    xOffset = 0,
    yOffset = -120,
    spacing = 1,
  },
  gcdColor = {
    r = 1,
    g = 0,
    b = 1,
    a = 0.3,
  },
  alwaysShowOrbText = true,
  checkRange = true,
  desaturateSWD = true,
  mouseover = false,
  showIcons = true,
  showOrbText = true,

  barDisplayOrder = {
    "Insanity",
    "Mind Flay",
    "Mind Sear",
    "Devouring Plague",
    "Shadow Word: Insanity",
    "Mind Blast",
    "Glyph of Mind Spike",
    "Shadow Word: Death",
    "Surge of Darkness",
    "Shadowy Insight",
    "Divine Star",
    "Vampiric Touch",
    "Shadow Word: Pain",
    "Cascade",
    "Halo",
    "Mindbender",
    "Void Entropy",
    "Power Infusion",
    "Shadowfiend",
  },
  baseDurations = {
    ["Shadow Word: Pain"] = 18,
    ["Vampiric Touch"] = 15,
  },
  buffs = {
    ["Shadow Word: Insanity"] = 132573,
    ["Glyph of Mind Spike"] = 81292,
    ["Surge of Darkness"] = 87160,
    -- ["Shadowy Insight"] = 124430,
  },
  cooldowns = {
    ["Shadow Word: Death"] = 32379,
    ["Mind Blast"] = 8092,
    ["Divine Star"] = 122121,
    ["Cascade"] = 127632,
    ["Halo"] = 120644,
    ["Mindbender"] = 123040,
    -- ["Power Infusion"] = 10060,
    ["Shadowfiend"] = 34433,
  },
  debuffs = {
    ["Mind Flay"] = 15407,
    ["Insanity"] = 129197,
    ["Mind Sear"] = 48045,
    -- ["Devouring Plague"] = 158831,
    ["Vampiric Touch"] = 34914,
    ["Shadow Word: Pain"] = 589,
    ["Void Entropy"] = 155361,
  },
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

local activeDebuffs = {} -- A list of all DoTs we have active. {{["targetGUID"], ["targetName"], ["spellName"], ["spellID"], ["expires"]}, ...}
targetBarContainer = CreateFrame("Frame", nil, UIParent)
targetBars = {} -- A list of bar frames for the target+player units. {["spellName"] = CreateFrame(), ...}
gcdBar = CreateFrame("Frame", "GCD indicator", targetBarContainer)
gcdBar:SetFrameStrata("HIGH")
gcdBar.texture = gcdBar:CreateTexture()
local f = CreateFrame("Frame") -- For RegisterEvent and such

local function isInList(item, list) -- Utility function
  for k, v in pairs(list) do
    if k == item then
      return true
    end
  end
  return false
end

local function rearrangeTargetBars()
  local numBars = 1
  for _, spellName in ipairs(SingularityDB.barDisplayOrder) do
    if targetBars[spellName] ~= nil then
      if targetBars[spellName]:IsShown() then
        if spellName ~= "Insanity" and spellName ~= "Mind Flay" and spellName ~= "Mind Sear" then
          numBars = numBars + 1
        end
        local xOffset = SingularityDB.targetContainer.spacing
        if SingularityDB.showIcons then
          xOffset = xOffset + SingularityDB.bar.icon.size - SingularityDB.bar.icon.xOffset + 1
        end
        targetBars[spellName]:SetPoint("TOPLEFT", targetBarContainer, "TOPLEFT", xOffset, -(SingularityDB.bar.height + SingularityDB.bar.spacing) * (numBars - 1) - SingularityDB.targetContainer.spacing - 1)
      end
    end
  end
  targetBarContainer:SetHeight((SingularityDB.bar.height + SingularityDB.bar.spacing) * numBars + SingularityDB.targetContainer.spacing * 2 + 1)
  gcdBar:SetSize(SingularityDB.bar.width - SingularityDB.bar.texture.inset, targetBarContainer:GetHeight() - SingularityDB.targetContainer.spacing - 3)
  gcdBar.texture:SetHeight(gcdBar:GetHeight())
end

local function setupBar(barFrame)
  local b = barFrame
  b.iconTexture = b:CreateTexture()
  if SingularityDB.showIcons then
    b.iconTexture:SetPoint("RIGHT", b, "LEFT", SingularityDB.bar.icon.xOffset, SingularityDB.bar.icon.yOffset)
    b.iconTexture:SetSize(SingularityDB.bar.icon.size, SingularityDB.bar.icon.size)
    b.iconTexture:SetTexCoord(SingularityDB.bar.icon.coords.l, SingularityDB.bar.icon.coords.r, SingularityDB.bar.icon.coords.t, SingularityDB.bar.icon.coords.b)
    b.iconTexture:SetTexture(select(3, GetSpellInfo(b.spellID)))
  end
  b:SetBackdrop(SingularityDB.bar.backdrop)
  b:SetBackdropColor(SingularityDB.bar.backdrop.color.r, SingularityDB.bar.backdrop.color.g, SingularityDB.bar.backdrop.color.b, SingularityDB.bar.backdrop.color.a)
  b:SetBackdropBorderColor(SingularityDB.bar.backdrop.borderColor.r, SingularityDB.bar.backdrop.borderColor.g, SingularityDB.bar.backdrop.borderColor.b, SingularityDB.bar.backdrop.borderColor.a)
  b:SetSize(SingularityDB.bar.width, SingularityDB.bar.height)
  b.stackText = b:CreateFontString()
  b.stackText:SetFont(SingularityDB.bar.text.fontPath, SingularityDB.bar.text.fontSize, SingularityDB.bar.text.fontFlags)

  Singularity_updateFonts()
  b.texture = b:CreateTexture()
  b.texture:SetPoint("LEFT", b, "LEFT", 0, 0)
  b.texture:SetHeight(SingularityDB.bar.height - SingularityDB.bar.texture.inset)
end

local function shouldShowBar(spellName)
  local function missingTalent(row, column)
    return not select(4, GetTalentInfo(row, column, GetActiveSpecGroup()))
  end

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
    if spellName ~= "Glyph of Mind Spike" and shouldShowBar(spellName) then
      frame:Show()
    else
      frame:Hide()
    end

    if spellName == "Mind Flay" or spellName == "Mind Sear" or spellName == "Insanity" then
      frame.stackText:SetText(select(4, UnitBuff("player", "Glyph of Mind Spike")))
    end

    if spellName == "Surge of Darkness" and shouldShowBar(spellName) then
      frame.stackText:SetText(select(4, UnitBuff("player", "Surge of Darkness")))
    end
  end

  if shouldShowBar("Mindbender") then
    targetBars["Mindbender"]:Show()
    targetBars["Shadowfiend"]:Hide()
  else
    targetBars["Mindbender"]:Hide()
    targetBars["Shadowfiend"]:Show()
  end

  rearrangeTargetBars()
end

local function init()
  for k, v in pairs(SingularityDB.cooldowns) do
    targetBars[k] = CreateFrame("Frame", k, targetBarContainer)
    targetBars[k].active = false
    targetBars[k].spellID = v
    setupBar(targetBars[k])
  end
  for k, v in pairs(SingularityDB.buffs) do
    targetBars[k] = CreateFrame("Frame", k, targetBarContainer)
    targetBars[k].active = false
    targetBars[k].spellID = v
    setupBar(targetBars[k])
  end
  for k, v in pairs(SingularityDB.debuffs) do
    targetBars[k] = CreateFrame("Frame", k, targetBarContainer)
    targetBars[k].active = false
    targetBars[k].spellID = v
    targetBars[k].checkForSafeTime = true
    setupBar(targetBars[k])
  end

  showTargetBars()
  if targetBars["Mind Sear"] ~= nil then
    targetBars["Mind Sear"]:SetAlpha(0)
  end
  if targetBars["Insanity"] ~= nil then
    targetBars["Insanity"]:SetAlpha(0)
  end
  targetBarContainer:SetPoint(SingularityDB.targetContainer.anchorFrom, SingularityDB.targetContainer.anchorFrame, SingularityDB.targetContainer.anchorTo, SingularityDB.targetContainer.xOffset, SingularityDB.targetContainer.yOffset)
  targetBarContainer:SetBackdrop(SingularityDB.targetContainer.backdrop)
  targetBarContainer:SetBackdropBorderColor(SingularityDB.targetContainer.backdrop.borderColor.r, SingularityDB.targetContainer.backdrop.borderColor.g, SingularityDB.targetContainer.backdrop.borderColor.b, SingularityDB.targetContainer.backdrop.borderColor.a)
  targetBarContainer:SetBackdropColor(SingularityDB.targetContainer.backdrop.color.r, SingularityDB.targetContainer.backdrop.color.g, SingularityDB.targetContainer.backdrop.color.b, SingularityDB.targetContainer.backdrop.color.a)
  local extra = 0
  if SingularityDB.showIcons then
    extra = SingularityDB.bar.icon.size
  end
  targetBarContainer:SetSize(SingularityDB.bar.width + SingularityDB.targetContainer.spacing, 0)

  gcdBar:SetPoint("TOPLEFT", targetBars["Mind Flay"], "TOPLEFT", SingularityDB.bar.texture.inset, 0)
  gcdBar.texture:SetPoint("LEFT", gcdBar, "LEFT")

  Singularity_reloadBars()
end

local function runTimer(frame, expires)
  frame:SetScript("OnUpdate", function()
    if not frame.active then
      showTargetBars()
      frame.texture:SetTexture(0, 0, 0, 0)
      frame:SetScript("OnUpdate", nil)
    else
      if frame:GetName() == "Glyph of Mind Spike" or frame:GetName() == "Surge of Darkness" or frame:GetName() == "Shadowy Insight" then
        expires = select(7, UnitBuff("player", frame:GetName())) or 0
      end
      if isInList(frame:GetName(), SingularityDB.cooldowns) then
        local started, cooldown = GetSpellCooldown(frame:GetName())
        expires = started + cooldown
      end
      local timeLeft = expires - GetTime()


      if timeLeft > 0 then
        if frame:GetName() == "GCD indicator" then
          local cfg = SingularityDB.gcdColor
          frame.texture:SetTexture(cfg.r, cfg.g, cfg.b, cfg.a)
        else
          frame.texture:SetTexture(SingularityDB.bar.texture.color.r,SingularityDB.bar.texture.color.g,SingularityDB.bar.texture.color.b,SingularityDB.bar.texture.color.a)
        end
        if timeLeft >= SingularityDB.bar.maxTime then
          frame.texture:SetWidth(SingularityDB.bar.width - SingularityDB.bar.texture.inset)
        else
          local b = SingularityDB.baseDurations[frame:GetName()]
          if b and timeLeft < b * 0.3 + select(4, GetSpellInfo(frame:GetName())) / 1000 or false then -- 30% of base + cast time
            frame.texture:SetTexture(SingularityDB.bar.texture.alert.r,SingularityDB.bar.texture.alert.g,SingularityDB.bar.texture.alert.b,SingularityDB.bar.texture.alert.a)
          end
          frame.texture:SetWidth((SingularityDB.bar.width - SingularityDB.bar.texture.inset) * timeLeft / SingularityDB.bar.maxTime)
        end
      else
        frame.active = false
        frame.texture:SetTexture(0, 0, 0, 0)
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
        if entry["spellName"] == "Insanity" or entry["spellName"] == "Mind Flay" or entry["spellName"] == "Mind Sear" then
          for k, v in ipairs{"Insanity", "Mind Flay", "Mind Sear"} do
            if targetBars[v] ~= nil then
              targetBars[v]:SetAlpha(0)
            end
          end
          targetBars[entry["spellName"]]:SetAlpha(1)
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

local function processEvents(self, event, ...)
  if event == "ADDON_LOADED" and select(1, ...) == "Singularity" then
    SingularityDB = SingularityDB or {}

    for k,v in pairs(defaults) do
      -- if type(SingularityDB[k]) == "nil" then -- TODO: Uncomment before release, dummy
        SingularityDB[k] = v
      -- end
    end

    init()
    rearrangeTargetBars()
    f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    f:RegisterEvent("PLAYER_TALENT_UPDATE")
    f:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
    f:UnregisterEvent("ADDON_LOADED")
  elseif event == "CURRENT_SPELL_CAST_CHANGED" then
    gcdBar.active = true
    local start, duration = GetSpellCooldown(61304)
    runTimer(gcdBar, start + duration)
  elseif isInList(event, targetingEvents) then
    for spell, _ in pairs(SingularityDB.debuffs) do
      targetBars[spell].active = false
    end

    for spellName, spellID in pairs(SingularityDB.debuffs) do
      local expires = select(7, UnitDebuff("target", spellName, "", "PLAYER"))

      if expires ~= nil then
        insertIntoDebuffList(UnitGUID("target"), UnitName("target"), spellName, spellID, expires)
      end
    end
    readFromDebuffList()
  elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
    for _, v in pairs({"Insanity", "Mind Flay", "Mind Sear"}) do
      if targetBars[v] ~= nil then
        targetBars[v].active = false
      end
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    for spellName, _ in pairs(SingularityDB.buffs) do
      local expires = select(7, UnitBuff("player", spellName))
      if expires ~= nil then
        targetBars[spellName].active = true
        runTimer(targetBars[spellName], expires)
      end
    end

    for spellName, _ in pairs(SingularityDB.cooldowns) do
      local cd = GetSpellCooldown(spellName)
      if cd ~= nil and cd ~= 0 then
        targetBars[spellName].active = true
        runTimer(targetBars[spellName], 0)
      end
    end
    Singularity_updateOrbsText()
    readFromDebuffList()
  elseif event == "PLAYER_TALENT_UPDATE" then
    showTargetBars()
  else
    local _, type, _, sourceGUID, sourceName, _, _, targetGUID, targetName, _, _,spellID, spellName, _, numOrbs, powerType = ...

    if (type == "SPELL_CAST_SUCCESS" or type == "SPELL_AURA_APPLIED_DOSE") and sourceGUID == UnitGUID("player") and spellName == "Mind Spike" then
      readFromDebuffList()
    end

    if (type == "SPELL_ENERGIZE" and powerType == SPELL_POWER_SHADOW_ORBS) or (type == "SPELL_CAST_SUCCESS" and (spellName == "Devouring Plague" or spellName == "Void Entropy" or spellName == "Psychic Horror")) then
      Singularity_updateOrbsText()
    end

    if isInList(type, relevantTypes) and sourceGUID == UnitGUID("player") and (isInList(spellName, SingularityDB.buffs) or isInList(spellName, SingularityDB.cooldowns) or isInList(spellName, SingularityDB.debuffs)) then

      local unitID = "player"
      for unit, _ in pairs(units) do
        if UnitGUID(unit) == targetGUID then
          unitID = unit
        end
      end

      if isInList(spellName, SingularityDB.buffs) then
        local expires = select(7, UnitBuff("player", spellName)) or 0

        if type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_REFRESH" then -- Note that since SPELL_AURA_APPLIED_DOSE fires when you gain stacks but only if you are not already at max stacks we're not handling that type at all here; the timer for each stacked buff is started here, and then RunTimer takes care of reapplications
          targetBars[spellName].active = true
          runTimer(targetBars[spellName], expires)
        end
      elseif isInList(spellName, SingularityDB.cooldowns) then
        if type == "SPELL_CAST_SUCCESS" then
          targetBars[spellName].active = true
          runTimer(targetBars[spellName], 0) -- Expire time is checked in RunTimer for cooldowns, so no need to try to get or use it here
        end
      elseif isInList(spellName, SingularityDB.debuffs) then
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

local function onUpdate()
  if SingularityDB.desaturateSWD then
    if UnitHealth("target") > UnitHealthMax("target") * 0.2 then
      desaturate(targetBars["Shadow Word: Death"].iconTexture, true)
    else
      desaturate(targetBars["Shadow Word: Death"].iconTexture, false)
    end
  else
    desaturate(targetBars["Shadow Word: Death"].iconTexture, false)
  end

  if not SingularityDB.checkRange then
    targetBars["Cascade"].stackText:SetTextColor(1, 1, 1, 0)
    targetBars["Divine Star"].stackText:SetTextColor(1, 1, 1, 0)
    targetBars["Halo"].stackText:SetTextColor(1, 1, 1, 0)
    return
  end

  if rc == nil then
    rc = LibStub("LibRangeCheck-2.0")
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

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", processEvents)
f:SetScript("OnUpdate", onUpdate)

function Singularity_reloadBars()
  local cfg = SingularityDB.bar
  for spellName, frame in pairs(targetBars) do
    frame:SetSize(cfg.width, cfg.height)
    frame:SetBackdrop(cfg.backdrop)
    frame:SetBackdropBorderColor(cfg.backdrop.borderColor.r, cfg.backdrop.borderColor.g, cfg.backdrop.borderColor.b, cfg.backdrop.borderColor.a)
    frame:SetBackdropColor(cfg.backdrop.color.r, cfg.backdrop.color.g, cfg.backdrop.color.b, cfg.backdrop.color.a)
    frame.texture:SetSize(cfg.width - cfg.texture.inset, cfg.height - cfg.texture.inset)
    frame.iconTexture:SetSize(cfg.icon.size, cfg.icon.size)
    frame.iconTexture:SetPoint("RIGHT", frame, "LEFT", cfg.icon.xOffset, 0)
    if SingularityDB.showIcons then
      frame.iconTexture:Show()
    else
      frame.iconTexture:Hide()
    end
  end

  cfg = SingularityDB.targetContainer
  targetBarContainer:SetBackdrop(cfg.backdrop)
  targetBarContainer:SetBackdropBorderColor(cfg.backdrop.borderColor.r, cfg.backdrop.borderColor.g, cfg.backdrop.borderColor.b, cfg.backdrop.borderColor.a)
  targetBarContainer:SetBackdropColor(cfg.backdrop.color.r, cfg.backdrop.color.g, cfg.backdrop.color.b, cfg.backdrop.color.a)
  local width = SingularityDB.bar.width + cfg.spacing
  if SingularityDB.showIcons then
    width = width + SingularityDB.bar.icon.size + -SingularityDB.bar.icon.xOffset + 1
  end

  targetBarContainer:SetWidth(width + cfg.spacing + 1)

  targetBarContainer:ClearAllPoints()
  targetBarContainer:SetPoint(cfg.anchorFrom, cfg.anchorFrame, cfg.anchorTo, cfg.xOffset, cfg.yOffset)

  rearrangeTargetBars()
end

function Singularity_updateFonts()
  local cfg = SingularityDB.bar.text
  for k, v in pairs(targetBars) do
    v.stackText:SetFont(cfg.fontPath, cfg.fontSize, cfg.fontFlags)
    v.stackText:ClearAllPoints()
    v.stackText:SetPoint(cfg.anchorFrom, v.iconTexture, cfg.anchorTo, cfg.xOffset, cfg.yOffset)
  end
end

function Singularity_updateOrbsText()
  local orbs = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
  if not SingularityDB.alwaysShowOrbText then
    orbs = orbs > 0 and orbs or "" -- Show nothing at 0 Orbs
  end
  if not SingularityDB.showOrbText then
    orbs = ""
  end

  local text = targetBars["Mind Blast"].stackText

  if orbs >= 3 then
    text:SetTextColor(0, 1, 0, 1)
  else
    text:SetTextColor(1, 1, 1, 1)
  end

  text:SetText(orbs)
end