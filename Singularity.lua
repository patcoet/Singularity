-- TODO: Low-level support
if UnitClass("player") ~= "Priest" then
  DisableAddOn("Singularity")
  return
end



local gcdBar, f, rc, targetBarContainer, targetBars
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
        l = 0.15,
        r = 0.85,
        t = 0.15,
        b = 0.85,
      },
      height = 17,
      width = 17,
      xOffset = -1,
    },
    text = {
      anchorFrom = "CENTER",
      anchorTo = "CENTER",
      fontPath = "Interface\\AddOns\\Singularity\\Marken.ttf",
      fontSize = 8,
      fontFlags = "THINOUTLINEMONOCHROME",
      xOffset = 1,
      yOffset = 0,
    },
    texture = {
      alert = {
        r = 0,
        g = 0.5,
        b = 0,
        a = 1,
      },
      color = {
        r = 0.5,
        g = 0.5,
        b = 0.5,
        a = 1,
      },
      path = "Interface\\Buttons\\WHITE8X8",
      inset = 0,
    },
    height = 17,
    maxTime = 8,
    spacing = 1,
    width = 177,
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
    parentFrame = "UIParent",
    xOffset = 0,
    yOffset = -162,
    spacing = 0,
  },
  gcdColor = {
    r = 1,
    g = 1,
    b = 1,
    a = 0.5,
  },
  alwaysShowOrbsText = false,
  alwaysShowSurgeText = false,
  alwaysShowSpikeText = false,
  hideWithNoTarget = true,
  updateInterval = 0.15,

  barDisplayOrder = {
    "Insanity",
    "Mind Flay",
    "Mind Sear",
    "Devouring Plague",
    "Shadow Word: Insanity",
    "Mind Blast",
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
  },
  channeledSpells = {
    "Insanity",
    "Mind Flay",
    "Mind Sear",
  },
  cooldowns = {
    ["Shadow Word: Death"] = 32379,
    ["Mind Blast"] = 8092,
    ["Divine Star"] = 122121,
    ["Cascade"] = 127632,
    ["Halo"] = 120644,
    ["Mindbender"] = 123040,
  },
  debuffs = {
    ["Mind Flay"] = 15407,
    ["Insanity"] = 129197,
    ["Mind Sear"] = 48045,
    ["Vampiric Touch"] = 34914,
    ["Shadow Word: Pain"] = 589,
    ["Void Entropy"] = 155361,
  },
  hiddenSpells = {
    ["Glyph of Mind Spike"] = "",
  },
  orbSpenders = {
    ["Devouring Plague"] = "",
    ["Void Entropy"] = "",
    ["Psychic Horror"] = "",
  },
}



-- Utility functions
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

local function isInList(item, list)
  for k, v in pairs(list) do
    if k == item then
      return true
    end
  end
  return false
end

local function shouldShowBar(spellName)
  if isInList(spellName, SingularityDB.hiddenSpells) then
    return false
  end

  for row = 1, 7 do
    for column = 1, 3 do
      local _, name, _, enabled = GetTalentInfo(row, column, GetActiveSpecGroup())
      if name == spellName:gsub("Shadow Word: ", "") and not enabled then
        return false
      end
    end
  end

  return true
end



-- Main functions
local function runTimer(frame, expires)
  local name = frame:GetName():sub(17)
  frame:SetScript("OnUpdate", function()
    if not frame.active then
      frame.texture:SetTexture(0, 0, 0, 0)
      frame:SetScript("OnUpdate", nil)
    else
      if name == "Glyph of Mind Spike" or name == "Surge of Darkness" or name == "Shadowy Insight" then
        expires = select(7, UnitBuff("player", name)) or 0
      end

      if isInList(name, SingularityDB.cooldowns) then
        local startTime, cooldown = GetSpellCooldown(name)
        expires = startTime + cooldown
      end
      local timeLeft = expires - GetTime()

      if timeLeft > 0 then
        local cfg
        if frame:GetName() == "Singularity_Bar_GCD" then
          cfg = SingularityDB.gcdColor
          frame.texture:SetTexture(cfg.r, cfg.g, cfg.b, cfg.a)
        else
          cfg = SingularityDB.bar.texture.color
          frame.texture:SetTexture(cfg.r, cfg.g, cfg.b, cfg.a)
        end
        if timeLeft >= SingularityDB.bar.maxTime then
          cfg = SingularityDB.bar
          frame.texture:SetWidth(cfg.width - cfg.texture.inset)
        else
          local spellName = name
          local b = SingularityDB.baseDurations[spellName]
          if b and timeLeft < b * 0.3 + select(4, GetSpellInfo(spellName)) / 1000 or false then -- 30% of base + cast time
            cfg = SingularityDB.bar.texture.alert
            frame.texture:SetTexture(cfg.r, cfg.g, cfg.b, cfg.a)
          end
          cfg = SingularityDB.bar
          frame.texture:SetWidth((SingularityDB.bar.width - cfg.texture.inset) * timeLeft / cfg.maxTime)
        end
      else
        frame.active = false
        frame.texture:SetTexture(0, 0, 0, 0)
        if name == "Surge of Darkness" then
          Singularity_updateSurgeText()
        end
        frame:SetScript("OnUpdate", nil)
      end
    end
  end)
end

local function readDebuffList()
  for _, entry in ipairs(activeDebuffs) do
    if UnitGUID("target") == entry["targetGUID"] then
      targetBars[entry["spellName"]].active = true
      runTimer(targetBars[entry["spellName"]], entry["expires"])

      if entry["spellName"] == "Insanity" or entry["spellName"] == "Mind Flay" or entry["spellName"] == "Mind Sear" then -- Hide the two others
        for _, spellName in ipairs{"Insanity", "Mind Flay", "Mind Sear"} do
          if targetBars[spellName] then
            targetBars[spellName]:SetAlpha(0)
          end
        end
        targetBars[entry["spellName"]]:SetAlpha(1)
      end
    end
  end
end

local function updateDebuffList(targetGUID, spellName, expires)
  for n, entry in ipairs(activeDebuffs) do
    if entry["targetGUID"] == targetGUID and entry["spellName"] == spellName then
      table.remove(activeDebuffs, n)
      break
    end
  end

  if expires > 0 then
    table.insert(activeDebuffs, {["targetGUID"] = targetGUID, ["spellName"] = spellName, ["expires"] = expires})
  end
end



-- Global functions (called from SingularityConfig)
function Singularity_reloadBars()
  local cfg
  for spellName, frame in pairs(targetBars) do
    cfg = SingularityDB.bar
    frame:SetSize(cfg.width, cfg.height)
    frame:SetBackdrop(cfg.backdrop)
    cfg = cfg.backdrop.borderColor
    frame:SetBackdropBorderColor(cfg.r, cfg.g, cfg.b, cfg.a)
    cfg = SingularityDB.bar.backdrop.color
    frame:SetBackdropColor(cfg.r, cfg.g, cfg.b, cfg.a)
    cfg = SingularityDB.bar
    frame.texture:SetSize(cfg.width - cfg.texture.inset, cfg.height - cfg.texture.inset)
    cfg = cfg.icon
    frame.iconTexture:SetTexCoord(cfg.coords.l, cfg.coords.r, cfg.coords.t, cfg.coords.b)
    frame.iconTexture:SetSize(cfg.width, cfg.height)
    frame.iconTexture:SetPoint("RIGHT", frame, "LEFT", cfg.xOffset, 0)
  end

  cfg = SingularityDB.targetContainer
  targetBarContainer:SetBackdrop(cfg.backdrop)
  cfg = cfg.backdrop.borderColor
  targetBarContainer:SetBackdropBorderColor(cfg.r, cfg.g, cfg.b, cfg.a)
  cfg = SingularityDB.targetContainer.backdrop.color
  targetBarContainer:SetBackdropColor(cfg.r, cfg.g, cfg.b, cfg.a)

  cfg = SingularityDB.bar.icon
  local width = SingularityDB.bar.width + SingularityDB.targetContainer.spacing + cfg.width + -cfg.xOffset + 1

  targetBarContainer:SetWidth(SingularityDB.bar.width + SingularityDB.targetContainer.spacing * 2 + cfg.width + -cfg.xOffset + 2)

  cfg = SingularityDB.targetContainer
  targetBarContainer:SetParent(cfg.parentFrame)

  targetBarContainer:ClearAllPoints()
  targetBarContainer:SetPoint(cfg.anchorFrom, cfg.anchorFrame, cfg.anchorTo, cfg.xOffset, cfg.yOffset)

  for spellName, frame in pairs(targetBars) do
    if shouldShowBar(spellName) then
      frame:Show()
    else
      frame:Hide()
    end
  end

  local numBars = 1
  for _, spellName in ipairs(SingularityDB.barDisplayOrder) do
    if targetBars[spellName] ~= nil then
      if targetBars[spellName]:IsShown() then
        if spellName ~= "Insanity" and spellName ~= "Mind Flay" and spellName ~= "Mind Sear" then
          numBars = numBars + 1
        end
        local xOffset = SingularityDB.targetContainer.spacing
        if SingularityDB.showIcons then
          xOffset = xOffset + SingularityDB.bar.icon.width - SingularityDB.bar.icon.xOffset + 1
        end
        targetBars[spellName]:SetPoint("TOPLEFT", targetBarContainer, "TOPLEFT", xOffset, -(SingularityDB.bar.height + SingularityDB.bar.spacing) * (numBars - 1) - SingularityDB.targetContainer.spacing - 1)
      end
    end
  end

  local cfg = SingularityDB.bar
  targetBarContainer:SetHeight((cfg.height + cfg.spacing) * numBars + SingularityDB.targetContainer.spacing * 2 + 1)
  gcdBar:SetSize(cfg.width - cfg.texture.inset, targetBarContainer:GetHeight() - SingularityDB.targetContainer.spacing - 3)
  gcdBar.texture:SetHeight(gcdBar:GetHeight())
end

function Singularity_updateFonts()
  local cfg = SingularityDB.bar.text
  for k, v in pairs(targetBars) do
    v.stackText:SetFont(cfg.fontPath, cfg.fontSize, cfg.fontFlags)
    v.stackText:ClearAllPoints()
    v.stackText:SetPoint(cfg.anchorFrom, v.iconTexture, cfg.anchorTo, cfg.xOffset, cfg.yOffset)
  end
end

function Singularity_updateSpikeText()
  local glyphIsInUse = false
  for i = 1, 6 do
    if select(4, GetGlyphSocketInfo(i, GetActiveSpecGroup())) == 33371 then
      glyphIsInUse = true
    end
  end
  -- if not glyphIsInUse then
  --   return
  -- end

  local text = select(4, UnitBuff("player", "Glyph of Mind Spike")) or 0

  if (text == 0 and not SingularityDB.alwaysShowSpikeText) or not glyphIsInUse then
    text = ""
  end

  for _, spellName in ipairs(SingularityDB.channeledSpells) do
    targetBars[spellName].stackText:SetText(text)
  end
end

function Singularity_updateOrbsText()
  local orbs = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
  if not SingularityDB.alwaysShowOrbsText then
    orbs = orbs > 0 and orbs or "" -- Show nothing at 0 Orbs
  end

  local text = targetBars["Mind Blast"].stackText

  if orbs ~= "" and orbs >= 3 then
    text:SetTextColor(0, 1, 0, 1)
  else
    text:SetTextColor(1, 1, 1, 1)
  end

  text:SetText(orbs)
end

function Singularity_updateSurgeText()
  if not shouldShowBar("Surge of Darkness") then
    return
  end

  local text = select(4, UnitBuff("player", "Surge of Darkness")) or 0

  if text == 0 and not SingularityDB.alwaysShowSurgeText then
    text = ""
  end

  targetBars["Surge of Darkness"].stackText:SetText(text)
end



-- Startup stuff
local function onUpdate(self, elapsed)
  self.dt = self.dt + elapsed
  if self.dt < SingularityDB.updateInterval then -- Update Shadow Word: Death desaturation and range display at most every 50 ms, just in case it might make a difference to someone's FPS sometime
    return
  else
    self.dt = self.dt - SingularityDB.updateInterval
  end

  if UnitHealth("target") > UnitHealthMax("target") * 0.2 then
    desaturate(targetBars["Shadow Word: Death"].iconTexture, true)
  else
    desaturate(targetBars["Shadow Word: Death"].iconTexture, false)
  end

  if rc == nil then
    rc = LibStub("LibRangeCheck-2.0")
  end

  local minRange, maxRange = rc:GetRange("target")
  if maxRange == nil then
    return
  end

  if shouldShowBar("Cascade") then
    targetBars["Cascade"].stackText:SetText(maxRange)
    local t = targetBars["Cascade"].stackText
    if maxRange < 40 then
      t:SetTextColor(1, 1, 0, 1)
    elseif maxRange == 40 then
      t:SetTextColor(0, 1, 0, 1)
    else
      t:SetTextColor(1, 0, 0, 1)
    end
  elseif shouldShowBar("Divine Star") then
    targetBars["Divine Star"].stackText:SetText(maxRange)
    local t = targetBars["Divine Star"].stackText
    if maxRange < 25 then
      t:SetTextColor(0, 1, 0, 1)
    elseif maxRange == 25 then
      t:SetTextColor(1, 1, 0, 1)
    else
      t:SetTextColor(1, 0, 0, 1)
    end
  elseif shouldShowBar("Halo") then
    targetBars["Halo"].stackText:SetText(maxRange)
    local t = targetBars["Halo"].stackText
    if maxRange <= 15 then
      t:SetTextColor(1, 0, 0, 1)
    elseif minRange == 15 and maxRange == 20 then
      t:SetTextColor(1, 1, 0, 1)
    elseif minRange == 20 and maxRange == 25 then
      t:SetTextColor(0, 1, 0, 1)
    elseif minRange == 25 and maxRange == 30 then
      t:SetTextColor(1, 1, 0, 1)
    else
      t:SetTextColor(1, 0, 0, 1)
    end
  end
end

local function init()
  local function loadSettings()
    SingularityDB = SingularityDB or {}

    for k,v in pairs(defaults) do
      if type(SingularityDB[k]) == "nil" then
        SingularityDB[k] = v
      end
    end
  end

  local function setupBar(spellName, spellID) -- Should only do things that Singularity_reloadBars() doesn't
    targetBars[spellName] = CreateFrame("Frame", "Singularity_Bar_" .. spellName, targetBarContainer)
    local b = targetBars[spellName]
    b.spellID = spellID
    local cfg
    b.iconTexture = b:CreateTexture()
    if SingularityDB.showIcons then
      cfg = SingularityDB.bar.icon
      b.iconTexture:SetPoint("RIGHT", b, "LEFT", cfg.xOffset, cfg.yOffset)
      b.iconTexture:SetSize(cfg.width, cfg.height)
      cfg = cfg.coords
      b.iconTexture:SetTexCoord(cfg.l, cfg.r, cfg.t, cfg.b)
      b.iconTexture:SetTexture(select(3, GetSpellInfo(b.spellID)))
    end
    cfg = SingularityDB.bar.backdrop
    b:SetBackdrop(cfg)
    cfg = cfg.color
    b:SetBackdropColor(cfg.r, cfg.g, cfg.b, cfg.a)
    cfg = SingularityDB.bar.backdrop.borderColor
    b:SetBackdropBorderColor(cfg.r, cfg.g, cfg.b, cfg.a)
    cfg = SingularityDB.bar
    b:SetSize(cfg.width, cfg.height)
    b.stackText = b:CreateFontString()
    cfg = cfg.text
    b.stackText:SetFont(cfg.fontPath, cfg.fontSize, cfg.fontFlags)

    Singularity_updateFonts()
    b.texture = b:CreateTexture()
    b.texture:SetPoint("LEFT", b, "LEFT", 0, 0)

    cfg = SingularityDB.bar
    b.texture:SetHeight(cfg.height - cfg.texture.inset)
    b.active = false
  end

  loadSettings()

  activeDebuffs = {} -- A list of all debuffs the player has active; {{["targetGUID"], ["spellName"], ["expires"]}, ...}
  targetBarContainer = CreateFrame("Frame", "Singularity", UIParent)
  targetBars = {} -- A list of bar frames; {["spellName"] = CreateFrame(), ...}

  for spellName, spellID in pairs(SingularityDB.cooldowns) do
    setupBar(spellName, spellID)
  end
  desaturate(targetBars["Shadow Word: Death"].iconTexture, true)
  for spellName, spellID in pairs(SingularityDB.buffs) do
    setupBar(spellName, spellID)
  end
  for spellName, spellID in pairs(SingularityDB.debuffs) do
    setupBar(spellName, spellID)
  end

  gcdBar = CreateFrame("Frame", "Singularity_Bar_GCD", targetBarContainer)
  gcdBar.texture = gcdBar:CreateTexture()

  -- showTargetBars()

  if targetBars["Mind Sear"] ~= nil then
    targetBars["Mind Sear"]:SetAlpha(0)
  end
  if targetBars["Insanity"] ~= nil then
    targetBars["Insanity"]:SetAlpha(0)
  end

  local cfg = SingularityDB.targetContainer
  targetBarContainer:SetPoint(cfg.anchorFrom, cfg.anchorFrame, cfg.anchorTo, cfg.xOffset, cfg.yOffset)
  targetBarContainer:SetBackdrop(cfg.backdrop)
  cfg = cfg.backdrop.borderColor
  targetBarContainer:SetBackdropBorderColor(cfg.r, cfg.g, cfg.b, cfg.a)
  cfg = SingularityDB.targetContainer.backdrop.color
  targetBarContainer:SetBackdropColor(cfg.r, cfg.g, cfg.b, cfg.a)
  targetBarContainer:SetSize(SingularityDB.bar.width + SingularityDB.targetContainer.spacing, 0)

  gcdBar:SetFrameStrata("HIGH")
  gcdBar:SetPoint("TOPLEFT", targetBars["Mind Flay"], "TOPLEFT", SingularityDB.bar.texture.inset, 0) -- Note: Depends on there being a Mind Flay bar
  gcdBar.texture:SetPoint("LEFT", gcdBar, "LEFT")

  Singularity_reloadBars()

  if SingularityDB.hideWithNoTarget then
    targetBarContainer:Hide()
  end

  f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
  f:RegisterEvent("PLAYER_TALENT_UPDATE")
  f:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
  f:UnregisterEvent("ADDON_LOADED")
end

local function processEvents(self, event, ...)
  if event == "ADDON_LOADED" and select(1, ...) == "Singularity" then -- Create frames, load options, etc.
    init()
    return
  end

  if event == "PLAYER_ENTERING_WORLD" and currSpec == "Shadow" then -- Recheck buffs and cooldowns after reloading UI (which deselects the player's target, so no need to check for target debuffs here)
    for spellName, _ in pairs(SingularityDB.buffs) do
      local expires = select(7, UnitBuff("player", spellName))
      if expires then
        targetBars[spellName].active = true
        runTimer(targetBars[spellName], expires)
      end
    end
    for spellName, _ in pairs(SingularityDB.cooldowns) do
      local cd = GetSpellCooldown(spellName)
      if cd and cd > 0 then
        targetBars[spellName].active = true
        runTimer(targetBars[spellName], 0)
      end
    end
    Singularity_updateSpikeText()
    Singularity_updateOrbsText()
    Singularity_updateSurgeText()
    return
  end

  if event == "PLAYER_TALENT_UPDATE" then
    Singularity_updateSpikeText()
    Singularity_updateSurgeText()
    Singularity_reloadBars()
    return
  end

  if event == "CURRENT_SPELL_CAST_CHANGED" then -- Fires whenever the player starts or stops casting, so whenever the GCD is started or cancelled
    gcdBar.active = true
    local startTime, duration = GetSpellCooldown(61304) -- Global Cooldown
    runTimer(gcdBar, startTime + duration)
    return
  end

  if event == "PLAYER_TALENT_UPDATE" then -- Make sure the right bars are shown
    Singularity_reloadBars()
    return
  end

  if event == "UNIT_SPELLCAST_CHANNEL_STOP" and ... == "player" then -- Clear the Insanity/Mind Flay/Mind Sear bar when the player stops channeling
    for _, spellName in ipairs(SingularityDB.channeledSpells) do
      if targetBars[spellName] then
        targetBars[spellName].active = false
      end
    end
    return
  end

  if event == "PLAYER_TARGET_CHANGED" then -- When the player changes targets, clear the current debuff timers and replace them with the debuff timers for the new target
    for spellName, _ in pairs(SingularityDB.debuffs) do
      targetBars[spellName].active = false
    end

    if not UnitExists("target") or not UnitCanAttack("player", "target") then
      f:SetScript("OnUpdate", nil)
      targetBars["Cascade"].stackText:SetTextColor(0, 0, 0, 0)
      targetBars["Divine Star"].stackText:SetTextColor(0, 0, 0, 0)
      targetBars["Halo"].stackText:SetTextColor(0, 0, 0, 0)
      if SingularityDB.hideWithNoTarget then
        targetBarContainer:Hide()
      end
      return
    end

    if UnitExists("target") then
      f:SetScript("OnUpdate", onUpdate)

      local _, currSpec = GetSpecializationInfo(GetSpecialization())

      if SingularityDB.hideWithNoTarget and currSpec == "Shadow" then
        targetBarContainer:Show()
      end

      for spellName, spellID in pairs(SingularityDB.debuffs) do
        local expires = select(7, UnitDebuff("target", spellName, "", "PLAYER"))

        if expires then
          updateDebuffList(UnitGUID("target"), spellName, expires)
        end
      end
      readDebuffList()
      return
    end
  end

  if event == "SPELL_UPDATE_USABLE" or (event == "UNIT_SPELLCAST_INTERRUPTED" and ... == "player") then -- When a cooldown begins or ends, update cooldown bars
    for spellName, spellID in pairs(SingularityDB.cooldowns) do
      local startTime, duration = GetSpellCooldown(spellID)
      targetBars[spellName].active = true
      runTimer(targetBars[spellName], startTime + duration)
    end
    return
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local _, type, _, sourceGUID, sourceName, _, _, targetGUID, targetName, _, _, spellID, spellName, _, _, powerType = ...

    if sourceGUID ~= UnitGUID("player") then -- We're only interested in spells cast by the player
      return
    end

    if type == "SPELL_PERIODIC_DAMAGE" and (spellName == "Vampiric Touch" or spellName == "Devouring Plague") then
      Singularity_updateSurgeText()
    end

    if (type == "SPELL_ENERGIZE" and powerType == SPELL_POWER_SHADOW_ORBS) or isInList(spellName, SingularityDB.orbSpenders) then -- If the spell generates or spends Shadow Orbs, update the Shadow Orbs display
      Singularity_updateOrbsText()
      return
    end

    if type == "SPELL_CAST_SUCCESS" and spellName == "Mind Spike" then -- If the player casts Mind Spike and is using Glyph of Mind Spike, update the Glyph of Mind Spike counter
      Singularity_updateSpikeText()
      return
    end

    if type == "SPELL_CAST_SUCCESS" and isInList(spellName, SingularityDB.cooldowns) then
      local startTime, duration = GetSpellCooldown(spellID)
      targetBars[spellName].active = true
      runTimer(targetBars[spellName], startTime + duration)
    end

    if type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_REFRESH" or type == "SPELL_AURA_REMOVED" or type == "SPELL_AURA_APPLIED_DOSE" then -- Buffs and debuffs
      if isInList(spellName, SingularityDB.buffs) then
        local expires = select(7, UnitBuff("player", spellName)) or 0 -- 0 if the buff isn't on the target, i.e. if we got here from SPELL_AURA_REMOVED
        targetBars[spellName].active = true
        runTimer(targetBars[spellName], expires)
        Singularity_updateSpikeText()
        Singularity_updateSurgeText()
      end

      if isInList(spellName, SingularityDB.debuffs) then
        local expires = select(7, UnitDebuff("target", spellName, "", "PLAYER")) or 0 -- 0 if the debuff isn't on the unit, i.e. if we got here from SPELL_AURA_REMOVED
        updateDebuffList(targetGUID, spellName, expires)
        readDebuffList()
      end

      Singularity_reloadBars()
      return
    end
  end
end

f = CreateFrame("Frame")
f.dt = 0
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", processEvents)