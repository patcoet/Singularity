Singularity = CreateFrame("Frame", nil, UIParent)
Singularity.name, Singularity.thing = ...
Singularity:RegisterEvent("ADDON_LOADED")
Singularity:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
Singularity:RegisterEvent("PLAYER_ENTERING_WORLD")

local debug = function(...)
  print(...) -- XXX: Comment before release
end

local defaults = {
  width = 200,
  height = 3,
  spacing = 1,
  borderWidth = 1,
  interval = 1/30,
  maxTime = 6,
  x = 0,
  y = -164,
}

local spells = {    -- [spellId] = shown
  [17]     = false, -- Power Word: Shield
  [586]    = false, -- Fade
  [8092]   = true,  -- Mind Blast
  [8122]   = false, -- Psychic Scream
  [10060]  = false, -- Power Infusion
  [32375]  = false, -- Mass Dispel
  [47585]  = false, -- Dispersion
  [199911] = false,  -- Shadow Word: Death (talented)
  [205448] = false,  -- Void Bolt
}

local colors = {
  {88/255, 42/255, 114/255, 1},
  {34/255, 102/255, 102/255, 1},
  {170/255, 132/255, 57/255, 1},
  {170/255, 57/255, 57/255, 1},
  {170/255, 108/255, 57/255, 1},
}

local executeRange = 0.35
local executeBar = 199911

local isInTable = function(table, value)
  for k, v in pairs(table) do
    if v == value then
      return true, k
    end
  end

  return false
end

local elapsed = 0
local doCooldowns = function(self, dt)
  elapsed = elapsed + dt
  if elapsed >= SingularityDB.interval then
    elapsed = elapsed - SingularityDB.interval
  else
    return
  end

  for _, bar in pairs(Singularity.bars) do
    local start, duration = GetSpellCooldown(bar.spellId)
    if start > 0 then
      bar:SetValue((start + duration) - GetTime())
    else
      bar:SetValue(0)
    end
  end
end

local init = function()
  for k, v in pairs(defaults) do
    -- if SingularityDB[k] == nil then -- XXX: Uncomment before release
      SingularityDB[k] = defaults[k]
    -- end
  end

  local cfg = SingularityDB
  Singularity:SetPoint("CENTER", UIParent, "CENTER", cfg.x, cfg.y)
  Singularity:SetSize(1, 1)
  Singularity:Show()
  Singularity.bars = Singularity.bars or {} -- Create table if it doesn't exist
  local i = 0

  Singularity.insanity = Singularity.insanity or
                         CreateFrame("StatusBar", nil, Singularity)
  local bar = Singularity.insanity
  bar:SetSize(cfg.width, cfg.height)
  local spacing = -(i * (bar:GetHeight() + cfg.borderWidth * 2 + cfg.spacing))
  bar:SetPoint("TOP", Singularity, "TOP", 0, spacing)
  bar:SetMinMaxValues(0, 100)
  bar:SetValue(UnitPower("player"))
  bar:SetStatusBarTexture("Interface\\AddOns\\Singularity\\flat")
  bar:SetStatusBarColor(unpack(colors[i + 1]))
  bar.bg = bar.bg or bar:CreateTexture(nil, "BACKGROUND")
  bar.bg:SetPoint("CENTER")
  bar.bg:SetSize(bar:GetWidth() + 2, bar:GetHeight() + 2)
  bar.bg:SetColorTexture(0, 0, 0, 1)
  i = i + 1

  Singularity.cast = Singularity.cast or
                     CreateFrame("StatusBar", nil, Singularity)
  local bar = Singularity.cast
  bar:SetSize(cfg.width, cfg.height)
  local spacing = -(i * (bar:GetHeight() + cfg.borderWidth * 2 + cfg.spacing))
  bar:SetPoint("TOP", Singularity, "TOP", 0, spacing)
  bar:SetMinMaxValues(0, cfg.maxTime)
  bar:SetValue(0)
  bar:SetStatusBarTexture("Interface\\AddOns\\Singularity\\flat")
  bar:SetStatusBarColor(unpack(colors[i + 1]))
  bar.bg = bar.bg or bar:CreateTexture(nil, "BACKGROUND")
  bar.bg:SetPoint("CENTER")
  bar.bg:SetSize(bar:GetWidth() + 2, bar:GetHeight() + 2)
  bar.bg:SetColorTexture(0, 0, 0, 1)
  i = i + 1

  for spellId, shown in pairs(spells) do
    Singularity.bars[spellId] = Singularity.bars[spellId] or
                                CreateFrame("StatusBar", nil, Singularity)
    local bar = Singularity.bars[spellId]
    bar.spellId = spellId

    if shown then
      bar:Show()
      bar:SetSize(cfg.width, cfg.height)
      local spacing = -(i * (bar:GetHeight() + cfg.borderWidth * 2 + cfg.spacing))
      bar:SetPoint("TOP", Singularity, "TOP", 0, spacing)
      bar:SetMinMaxValues(0, cfg.maxTime)
      bar:SetStatusBarTexture("Interface\\AddOns\\Singularity\\flat")
      bar:SetStatusBarColor(unpack(colors[i + 1]))
      bar.bg = bar.bg or bar:CreateTexture(nil, "BACKGROUND")
      bar.bg:SetPoint("CENTER")
      bar.bg:SetSize(bar:GetWidth() + 2, bar:GetHeight() + 2)
      bar.bg:SetColorTexture(0, 0, 0, 1)
      i = i + 1
    else
      bar:Hide()
    end
  end

  Singularity:SetScript("OnUpdate", nil)
  Singularity:SetScript("OnUpdate", doCooldowns)
  Singularity:UnregisterAllEvents()
  Singularity:RegisterEvent("UNIT_HEALTH_FREQUENT")
  Singularity:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  Singularity:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  Singularity:RegisterEvent("UNIT_POWER_FREQUENT")
  Singularity:RegisterEvent("UNIT_SPELLCAST_START")
  Singularity:RegisterEvent("UNIT_SPELLCAST_STOP")
  Singularity:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
  Singularity:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
end

local hideBar = function(spellId)
  spells[spellId] = false
  init()
end

local showBar = function(spellId)
  spells[spellId] = true
  init()
end

local disable = function()
  Singularity:SetScript("OnUpdate", nil)
  Singularity:UnregisterAllEvents()
  Singularity:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  Singularity:Hide()
end

Singularity:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" and ... == "Singularity" or event == "PLAYER_ENTERING_WORLD" then
    Singularity:UnregisterEvent("ADDON_LOADED")

    local _, class = UnitClass("player")
    local specId = GetSpecialization()

    if class == "PRIEST" and specId == 3 then
      init()
    end
  end

  if event == "PLAYER_SPECIALIZATION_CHANGED" and ... == "player" then
    local _, class = UnitClass("player")
    local specId = GetSpecialization()

    if specId == 3 then
      init()
    else
      disable()
    end
  end

  if event == "UNIT_HEALTH_FREQUENT" and ... == "target" then
    local cur, max = UnitHealth("target"), UnitHealthMax("target")

    if cur/max < executeRange then
      showBar(executeBar)
    else
      hideBar(executeBar)
    end
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local subevent = select(2, ...)
    local srcGuid = select(4, ...)
    local spellId = select(12, ...)
    if spellId == 194249 and srcGuid == UnitGUID("player") then
      if subevent == "SPELL_AURA_APPLIED" then
        showBar(205448)
      elseif subevent == "SPELL_AURA_REMOVED" then
        hideBar(205448)
      end
    end
  end

  if event == "UNIT_POWER_FREQUENT" then
    local unit, powerType = ...

    if unit == "player" and powerType == "INSANITY" then
      Singularity.insanity:SetValue(UnitPower("player"))
    end
  end

  if ... == "player" then
    if event == "UNIT_SPELLCAST_START" then
      local endTime = select(6, UnitCastingInfo("player"))/1000
      Singularity.cast:SetScript("OnUpdate", function(self)
        self:SetValue(endTime - GetTime())
        if endTime <= GetTime() then
          self:SetScript("OnUpdate", nil)
        end
      end)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
      local endTime = select(6, UnitChannelInfo("player"))/1000
      Singularity.cast:SetScript("OnUpdate", function(self)
        self:SetValue(endTime - GetTime())
        if endTime <= GetTime() then
          self:SetScript("OnUpdate", nil)
        end
      end)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
      Singularity.cast:SetValue(0)
      Singularity.cast:SetScript("OnUpdate", nil)
    end
  end

end)

