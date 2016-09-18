-- Basic functionality:
-- Mind Spike stacks on targets
-- Void Ray stacks + duration
-- Make sure Shadow Word: Death health threshold thing works
-- Formula for Void Bolt refreshing DoTs

-- Later:
-- Redo the whole config thing, because there's no way creating all the options
-- manually is the best way to do it
-- Redo all the setup stuff, because things are breaking when changing talents
-- and stuff

local playerIsInVoidform = false
local voidformBar = false -- Probably not actually useful

local function toSet(t)
  local u = {}
  for _, v in ipairs(t) do
    u[v] = true
  end
  return u
end

local cfg = {
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
      a = 0.5,
    },
    borderColor = {
      r = 0,
      g = 0,
      b = 0,
      a = 1,
    },
  },
  barColor = {1/2, 1/2, 1/2, 1},
  barGap = 1,
  barMaxTime = 12,
  barPoint = {"TOP", "TOP", 0, -1},
  barRefreshColor = {1, 0, 0, 1},
  barSize = {200, 20},
  barTexture = "Interface\\AddOns\\Singularity\\Singularity_flat",
  baseDuration = {
    [589] = 14, -- Shadow Word: Pain
    [34914] = 18, -- Vampiric Touch
    [217673] = 10, -- Mind Spike
  },
  buffs = {
    124430, -- Shadowy Insight
    205371, -- Void Ray
    -- Voidform here?
  },
  cooldowns = {
    8092, -- Mind Blast
    34433, -- Shadowfriend/Mindfriender
    10060, -- Power Infusion
    205385, -- Shadow Crash
    32379, -- Shadow Word: Death
    205448, -- Void Bolt
    228260, -- Void Eruption
    205065, -- Void Torrent
    205351, -- Shadow Word: Void
  },
  DeathBar = 32379, -- Shadow Word: Death
  dots = {
    589, -- Shadow Word: Pain
    34914, -- Vampiric Touch
    -- 217673, -- Mind Spike
  },
  dynIconSize = {12, 12},
  dynBarSize = {200, 12},
  dynSortOrder = {
    "target",
    "mouseover",
    "focus",
    "boss1",
    "boss2",
    "boss3",
    "boss4",
    "boss5",
  },
  dynTexCoords = {0.3, 0.7, 0.3, 0.7},
  dynTextPoint = {"CENTER", "CENTER", 0, 0},
  dynText2Point = {"RIGHT", "RIGHT", -1, 0},
  executeRange = 0.35,
  font = {"Interface\\AddOns\\Singularity\\Marken.ttf", 8, "THINOUTLINEMONOCHROME"},
  fontPoint = {"CENTER", "CENTER", 2, 0},
  gcdBarColor = {1, 1, 1, 0.5},
  hiddenBars = { -- Hide cooldowns that are too long to be part of the main rotation
  ["cast"] = false,
  ["voidform"] = true,
  [34433] = true, -- Shadowfriend
  [205385] = true, -- Shadow Crash
  [205065] = true, -- Void Torrent
  [205351] = true, -- Shadow Word: Void
},
hideOOC = false,
iconPoint = {"RIGHT", "LEFT", -1, 0},
iconSize = {20, 20},
links = {
  [205448] = 228260, -- Void Eruption -> Void Bolt
  [123040] = 34433, -- Mindfriender
},
secondaryResourceBar = 8092, -- Mind Blast
secondaryResourceBreakpoint = 70,
secondaryResourceBreakpointColor = {0, 1, 0, 1},
showDoTBars = true,
SingularityPoint = {"TOP", "UIParent", "CENTER", 0, -162},
staticParent = "UIParent",
shouldReplaceIcon = {
  [228260] = 205448, -- Void Eruption -> Void Bolt
},
staticSortOrder = {
  "cast",
  "voidform",
  15407, -- Mind Flay
  228260, -- Void Bolt
  8092, -- Mind Blast
  32379, -- Shadow Word: Death
  34433, -- Shadowfriend
},
texCoords = {0.1, 0.9, 0.1, 0.9}, -- Zoom icons in a little
texts = {
},
trackedEvents = {
  "UNIT_AURA", -- buffs
  "UNIT_POWER_FREQUENT", -- secondary resource
  "UNIT_SPELLCAST_START", -- casts
  "UNIT_SPELLCAST_CHANNEL_START", -- casts
  "UNIT_SPELLCAST_SENT", -- GCD
  "UNIT_SPELLCAST_STOP", -- casts
  "UNIT_SPELLCAST_CHANNEL_STOP", -- casts
  "UNIT_SPELLCAST_INTERRUPTED", -- casts
  "UNIT_SPELLCAST_SUCCEEDED", -- cooldowns
  "COMBAT_LOG_EVENT_UNFILTERED", -- DoTs, Orbs
  "PLAYER_TARGET_CHANGED", -- dynamic reordering
  "UPDATE_MOUSEOVER_UNIT", -- dynamic reordering
  "PLAYER_FOCUS_CHANGED", -- dynamic reordering
  "PLAYER_TALENT_UPDATE", -- texts and settings
  "PLAYER_ENTERING_WORLD", -- texts and settings
  "PLAYER_DEAD", -- texts
  "PLAYER_REGEN_ENABLED", -- hide OOC
  "PLAYER_REGEN_DISABLED", -- hide OOC
},
unitIDSymbols = {
  ["target"] = "t",
  ["mouseover"] = "m",
  ["focus"] = "f",
  ["boss1"] = "b1",
  ["boss2"] = "b2",
  ["boss3"] = "b3",
  ["boss4"] = "b4",
  ["boss5"] = "b5",
},
}

cfg.buffs = toSet(cfg.buffs)
cfg.dots = toSet(cfg.dots)
cfg.cooldowns = toSet(cfg.cooldowns)
local haveMouseover = false

local function updateBarTexts()
  for k, v in pairs(Singularity.bars.dynamic) do
    if type(v) == "table" and v:IsShown() and v.GUID then
      local str = ""
      for _, unitID in pairs(SingularityDB.dynSortOrder) do
        if v.GUID == UnitGUID(unitID) then
          str = SingularityDB.unitIDSymbols[unitID]
          break
        end
      end
      -- v.fs:SetText(str .. v.name)
      v.fs1:SetText(v.name)
      v.fs2:SetText(str)
    end
  end
end

local function updateStackTexts()
  local currPow = UnitPower("player", SingularityDB.secondaryResource)
  local powBar = Singularity.bars.static[SingularityDB.secondaryResourceBar]
  powBar.icon.fs:SetText(currPow)
  if currPow >= SingularityDB.secondaryResourceBreakpoint then
    powBar.icon.fs:SetTextColor(unpack(SingularityDB.secondaryResourceBreakpointColor))
  else
    powBar.icon.fs:SetTextColor(1, 1, 1, 1)
  end

  for spellID in pairs(SingularityDB.buffs) do
    if IsPlayerSpell(spellID) and SingularityDB.texts[spellID] then
      Singularity.bars.static[SingularityDB.texts[spellID]].icon.fs:SetText("")
    end
  end
end

local function onUpdate()
  if haveMouseover and not UnitExists("mouseover") then
    haveMouseover = false
    updateBarTexts()
  end

  if SingularityDB.DeathBar then
    if (not UnitExists("target")) or UnitHealth("target") > UnitHealthMax("target") * SingularityDB.executeRange then
      Singularity.bars.static[SingularityDB.DeathBar].icon.tex:SetDesaturated(true)
    else
      Singularity.bars.static[SingularityDB.DeathBar].icon.tex:SetDesaturated(false)
    end
  end

end

local function createFrames()
  Singularity.bars = {}

  local b = Singularity.bars
  b.dynamic = CreateFrame("frame", nil, Singularity)

  b.gcd = CreateFrame("StatusBar", nil, Singularity)
  b.gcd.icon = CreateFrame("frame", nil, b.gcd)
  b.gcd.icon.tex = b.gcd.icon:CreateTexture()
  b.static = CreateFrame("frame", nil, Singularity)
  b.static.cast = CreateFrame("StatusBar", nil, b.static)
  b.static.cast.icon = CreateFrame("frame", nil, b.static.cast)
  b.static.cast.icon.tex = b.static.cast.icon:CreateTexture()
  b.static.cast.icon.fs = b.static.cast.icon:CreateFontString()

  if voidformBar then
    b.static.voidform = CreateFrame("StatusBar", nil, b.static)
    b.static.voidform.icon = CreateFrame("frame", nil, b.static.voidform)
    b.static.voidform.icon.tex = b.static.voidform.icon:CreateTexture()
    b.static.voidform.icon.fs = b.static.voidform.icon:CreateFontString()
  end

  b.dynamic:SetPoint("TOP", b.static, "BOTTOM", 0, -1)

  for spellID in pairs(SingularityDB.cooldowns) do
    b.static[spellID] = CreateFrame("StatusBar", nil, b.static)
    b.static[spellID].spellID = spellID
    b.static[spellID].icon = CreateFrame("frame", nil, b.static[spellID])
    b.static[spellID].icon.tex = b.static[spellID].icon:CreateTexture()
    b.static[spellID].icon.fs = b.static[spellID].icon:CreateFontString()
  end

  for spellID in pairs(SingularityDB.buffs) do
    b.static[spellID] = CreateFrame("StatusBar", nil, b.static)
    b.static[spellID].spellID = spellID
    b.static[spellID].icon = CreateFrame("frame", nil, b.static[spellID])
    b.static[spellID].icon.tex = b.static[spellID].icon:CreateTexture()
    b.static[spellID].icon.fs = b.static[spellID].icon:CreateFontString()
  end
end

local function setupBar(frame, parent, n)
  local af, at, ox, oy = unpack(SingularityDB.barPoint)
  local iconW, iconH = unpack(SingularityDB.iconSize)
  local barW, barH = unpack(SingularityDB.barSize)

  frame:SetSize(unpack(SingularityDB.barSize))
  frame:SetPoint(af, parent, at, ox + SingularityDB.iconSize[1] / 2, oy - (frame:GetHeight() + SingularityDB.barGap) * n)

  frame:SetStatusBarTexture(SingularityDB.barTexture)
  frame:SetStatusBarColor(unpack(SingularityDB.barColor))
  frame:SetMinMaxValues(0, SingularityDB.barMaxTime)
  frame:SetValue(0)

  local _, _, icon = GetSpellInfo(frame.spellID)
  af, at, ox, oy = unpack(SingularityDB.iconPoint)
  ff, ft, fx, fy = unpack(SingularityDB.fontPoint)
  frame.icon:SetSize(unpack(SingularityDB.iconSize))
  frame.icon:SetPoint(af, frame, at, ox, oy)
  if SingularityDB.shouldReplaceIcon[frame.spellID] then
    frame.icon.tex:SetTexture(select(3, GetSpellInfo(SingularityDB.shouldReplaceIcon[frame.spellID])))
  else
    frame.icon.tex:SetTexture(icon)
  end
  frame.icon.tex:SetTexCoord(unpack(SingularityDB.texCoords))
  frame.icon.tex:SetAllPoints()
  if frame.icon.fs then
    frame.icon.fs:SetFont(unpack(SingularityDB.font))
    frame.icon.fs:SetPoint(ff, frame.icon, ft, fx, fy)
  end
end

local function reorderBars()
  local lastBar = Singularity.bars.dynamic

  for k,v in pairs(Singularity.bars.dynamic) do
    if type(v) == "table" and v:IsShown() and v.GUID then
      v:ClearAllPoints()
      v:SetPoint("TOP", lastBar, "BOTTOM", 0, -1)
      lastBar = v

      local w, h = unpack(SingularityDB.dynBarSize)
      local af, at, ox, oy = unpack(SingularityDB.barPoint)
      local iconW, iconH = unpack(SingularityDB.dynIconSize)
      local n = 0

      for splID, frame in pairs(v) do
        if type(frame) == "table" and frame.spellID and frame:IsShown() then
          frame:SetPoint(af, v, at, ox + iconW / 2, oy - (h + SingularityDB.barGap) * n)
          n = n + 1
        end
      end

      v:SetHeight(h * n + n + 1)

      updateBarTexts()
    end
  end
end

local function clearFrame(self)
  local p = self.GUID and self or self:GetParent()

  local test = true

  for _, frame in pairs(p) do
    if type(frame) == "table" then
      if frame.isActive then
        test = false
      end
    end
  end

  if test then
    p.GUID = nil
    p:Hide()
    reorderBars()
  end
end

local k = 1

local function loadSettings()
  SingularityDB.dynBarSize[1] = SingularityDB.barSize[1] + (SingularityDB.iconSize[1] - SingularityDB.dynIconSize[1])

  Singularity.bars.static:SetParent(SingularityDB.staticParent)
  Singularity.bars.dynamic:SetParent(SingularityDB.staticParent)

  Singularity.bars.static:SetPoint(unpack(SingularityDB.SingularityPoint))
  Singularity.bars.static:SetSize(SingularityDB.barSize[1] + SingularityDB.iconSize[1] + 3, SingularityDB.barSize[2])
  Singularity.bars.static:SetBackdrop(SingularityDB.backdrop)
  local c = SingularityDB.backdrop.color
  Singularity.bars.static:SetBackdropColor(c.r, c.g, c.b, c.a)
  local c = SingularityDB.backdrop.borderColor
  Singularity.bars.static:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
  Singularity.bars.dynamic:SetPoint("TOP", Singularity.bars.static, "BOTTOM", 0, 1)
  Singularity.bars.dynamic:SetSize(1, 1)

  Singularity:UnregisterAllEvents()

  for _, event in pairs(SingularityDB.trackedEvents) do
    Singularity:RegisterEvent(event)
  end

  Singularity:SetScript("OnUpdate", onUpdate)
  Singularity:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
      return self[event](self, event, ...)
    end
  end)

  local p = Singularity.bars.static

  local n = 0

  for i, barIndex in pairs(SingularityDB.staticSortOrder) do
    if p[barIndex] and (not SingularityDB.hiddenBars[barIndex]) and (not (barIndex == "cast" and SingularityDB.hiddenBars["cast"]) or (barIndex == "voidform" and SingularityDB.hiddenBars["voidform"])) then
      -- if not (barIndex ~= "cast" and not IsPlayerSpell(barIndex)) then
      if (barIndex == "cast" or barIndex == "voidform" or IsPlayerSpell(barIndex)) then
        setupBar(p[barIndex], p, n)
        n = n + 1
      end
    end
  end

  for k, frame in pairs(p) do
    if type(frame) ~= "userdata" then
      local test = true
      for i, j in pairs(SingularityDB.staticSortOrder) do
        if j == k then
          test = false
          break
        end
      end
      if test and (not SingularityDB.hiddenBars[k]) and ((SingularityDB.hiddenBars["cast"] == false and k == "cast") or IsPlayerSpell(k)) then
        setupBar(frame, p, n)
        n = n + 1
      end
      if SingularityDB.hiddenBars[k] or ((k ~= "cast" and k ~= "voidform") and not IsPlayerSpell(k)) then
        frame:Hide()
      else
        frame:Show()
      end
    end
  end

  local w, h = unpack(SingularityDB.barSize)

  p:SetHeight((h + SingularityDB.barGap) * n + 1)

  setupBar(Singularity.bars.gcd, Singularity.bars.static, 0)

  Singularity.bars.gcd:SetStatusBarColor(unpack(SingularityDB.gcdBarColor))
  Singularity.bars.gcd:SetHeight(Singularity.bars.static:GetHeight() - 2)
  Singularity.bars.gcd:SetFrameStrata("HIGH")

  local _, _, icon = GetSpellInfo(15407)
  Singularity.bars.static.cast.icon.tex:SetTexture(icon)

  for k, v in pairs(Singularity.bars.dynamic) do
    if type(v) == "table" then
      v:SetWidth(SingularityDB.dynBarSize[1] + SingularityDB.dynIconSize[1] + 2 + 1)
      local n = 0
      for spellID, frame in pairs(v) do
        if type(frame) == "table" then
          if frame["SetStatusBarTexture"] then
            setupBar(frame, v, n)
            frame:SetSize(unpack(SingularityDB.dynBarSize))
            frame.icon:SetSize(SingularityDB.dynBarSize[2], SingularityDB.dynBarSize[2])
            frame.icon.tex:SetTexCoord(unpack(SingularityDB.dynTexCoords))
            n = n + 1
          end
          frame:SetSize(unpack(SingularityDB.dynBarSize))
        end
      end
    end
  end

  reorderBars()
  updateStackTexts()

  if SingularityDB.hideOOC and not UnitAffectingCombat("player") then
    Singularity:Hide()
    Singularity.bars.static:Hide()
    Singularity.bars.dynamic:Hide()
  else
    Singularity:Show()
    Singularity.bars.static:Show()
    Singularity.bars.dynamic:Show()
  end

  if IsPlayerSpell(32379) then
    if GetTalentInfoByID(22317) then
      SingularityDB.executeRange = .35
    else
      SingularityDB.executeRange = .2
    end
  end

end

Singularity = CreateFrame("frame", "Singularity", UIParent)
function Singularity.loadSettings()
  loadSettings()
end

Singularity:RegisterEvent("ADDON_LOADED")
Singularity:SetScript("OnEvent", function(self, event, addon)
  if addon == "Singularity" then
    Singularity:UnregisterEvent("ADDON_LOADED")
    SingularityDB = SingularityDB or {}
    for k, v in pairs(cfg) do
      if type(SingularityDB[k]) == "nil" then
        SingularityDB[k] = v
      end
    end

    SingularityDB = cfg

    createFrames()

    Singularity:SetScript("OnUpdate", function()
      Singularity:SetScript("OnUpdate", nil)
      loadSettings()
    end)
  end
end)

Singularity["PLAYER_REGEN_ENABLED"] = function()
  if SingularityDB.hideOOC then
    Singularity:Hide()
    Singularity.bars.static:Hide()
    Singularity.bars.dynamic:Hide()
  end
end

Singularity["PLAYER_REGEN_DISABLED"] = function()
  Singularity:Show()
  Singularity.bars.static:Show()
  Singularity.bars.dynamic:Show()
end

Singularity["PLAYER_TALENT_UPDATE"] = function()
  Singularity.loadSettings()
  updateStackTexts()
end

Singularity["PLAYER_ENTERING_WORLD"] = Singularity["PLAYER_TALENT_UPDATE"]

Singularity["PLAYER_DEAD"] = function()
  updateStackTexts()
end

Singularity["PLAYER_TARGET_CHANGED"] = function()
  local first, second, third = unpack(SingularityDB.dynSortOrder)
  local p = Singularity.bars.dynamic
  local n

  if (not haveMouseover) and UnitExists("mouseover") then
    haveMouseover = true
  end

  for i = #p, 1, -1 do
    local test = false

    for k, v in pairs(SingularityDB.dynSortOrder) do
      if UnitGUID(v) and p[i].GUID == UnitGUID(v) then
        test = true
        n = k
        break
      end
    end

    if test then
      local tmp = p[i]
      table.remove(p, i)
      table.insert(p, n, tmp)
    end
  end

  reorderBars()
end
Singularity["UPDATE_MOUSEOVER_UNIT"] = Singularity["PLAYER_TARGET_CHANGED"]
Singularity["PLAYER_FOCUS_CHANGED"] = Singularity["PLAYER_TARGET_CHANGED"]



Singularity["UNIT_AURA"] = function(self, event, ...)
  local unitID = ...

  if unitID ~= "player" then return end

  for spellID in pairs(SingularityDB.buffs) do
    if IsPlayerSpell(spellID) then
      local name = GetSpellInfo(spellID)
      local _, _, _, count, _, _, expires = UnitBuff("player", name, "", "PLAYER")

      local p = Singularity.bars.static
      local f = p[spellID]
      f.expires = expires or 0

      if SingularityDB.texts[spellID] then
        Singularity.bars.static[SingularityDB.texts[spellID]].icon.fs:SetText(count)
      end

      f:SetScript("OnUpdate", function()
        f.timeLeft = max(f.expires - GetTime(), 0.01)
        f:SetValue(f.timeLeft)
        if f.timeLeft <= 0.01 then
          f:SetScript("OnUpdate", nil)
        end
      end)
    end
  end
end

Singularity["UNIT_SPELLCAST_SENT"] = function(self, event, ...)
  local unitID = ...
  if unitID ~= "player" then return end

  local f = Singularity.bars.gcd
  f:SetScript("OnUpdate", function()
    local started, duration = GetSpellCooldown(61304)
    if started then
      f.expires = GetTime() + duration
      f:SetScript("OnUpdate", function()
        f.timeLeft = max(f.expires - GetTime(), 0.01)
        f:SetValue(f.timeLeft)
        if f.timeLeft <= 0.01 then
          f:SetScript("OnUpdate", nil)
        end
      end)
    end
  end)
end

Singularity["UNIT_SPELLCAST_CHANNEL_START"] = function(self, event, ...)
  if not SingularityDB.hiddenBars["cast"] then
    local unitID, _, _, _, spellID = ...
    if unitID ~= "player" then return end

    local _, _, _, _, _, expires = UnitChannelInfo(unitID)
    if not expires then _, _, _, _, _, expires = UnitCastingInfo(unitID) end
    expires = expires and expires / 1000 or GetTime()
    local _, _, icon = GetSpellInfo(spellID)

    local f = Singularity.bars.static.cast
    f.icon.tex:SetTexture(icon)

    f.expires = expires
    f:SetScript("OnUpdate", function()
      f.timeLeft = max(f.expires - GetTime(), 0.01) -- Texture:SetWidth doesn't seem to like 0 as an argument
      f:SetValue(f.timeLeft)
    end)
  end
end
Singularity["UNIT_SPELLCAST_START"] = Singularity["UNIT_SPELLCAST_CHANNEL_START"]

Singularity["UNIT_SPELLCAST_STOP"] = function(self, event, ...)
  local unitID, _, _, _, spellID = ...
  if unitID ~= "player" then return end

  Singularity.bars.static.cast:SetScript("OnUpdate", nil)
  Singularity.bars.static.cast:SetValue(0)
end
Singularity["UNIT_SPELLCAST_INTERRUPTED"] = Singularity["UNIT_SPELLCAST_STOP"]
Singularity["UNIT_SPELLCAST_CHANNEL_STOP"] = Singularity["UNIT_SPELLCAST_STOP"]

Singularity["UNIT_SPELLCAST_SUCCEEDED"] = function(self, event, ...)
  local unitID, _, _, _, spellID = ...
  if unitID ~= "player" then return end
  if SingularityDB.hiddenBars[spellID] then return end
  if spellID == 2944 or spellID == 155361 then
    updateStackTexts()
  end

  if not SingularityDB.cooldowns[SingularityDB.links[spellID] or spellID] then return end
  local f = Singularity.bars.static[SingularityDB.links[spellID] or spellID]

  local started, duration
  local elapsed = 0

  f:SetScript("OnUpdate", function()
    started, duration = GetSpellCooldown(spellID)

    if started and started > 0 then
      f.expires = GetTime() + duration
      f:SetScript("OnUpdate", function()
        local _, duration = GetSpellCooldown(spellID)
        f.timeLeft = max(started + duration - GetTime(), 0.01)
        f:SetValue(f.timeLeft)

        if f.timeLeft <= 0.01 then
          f:SetScript("OnUpdate", nil)
        end
      end)
    end
  end)
end

Singularity["UNIT_POWER_FREQUENT"] = function(self, event, ...) -- Insanity
  local unit, powerType = ...
  if unit == "player" and powerType == "INSANITY" then
    --if select(12, ...) == 194249 then -- Voidform
    --  Singularity.bars.static.insanity.expires =

    -- Assuming the buff tooltip is right, insanity drains at 9.5/second to start
    -- and 0.5/second more per second after that. So, if we currently have d
    -- stacks of Voidform*, then in s seconds i insanity will have been
    -- drained, where
    --   i = s * (2d + s + 37)/4
    --   <=> d = 2i/s - s/2 - 37/2
    --   <=> s = 1/2 * (sqrt(16i + 4*d^2 + 148d + 1369) - 2d - 37).
    --
    -- So, with current values, when our insanity value updates, we will exit
    -- Voidform (sqrt(16i + 4*d^2 + 148d + 1369) - 2d - 37)/2 seconds.
    --
    -- From in-game testing it seems like this is about right:
    -- math.floor((math.sqrt(16*insanity + 4*(stacks^2) + 148*stacks + 1369) - 2*stacks - 37)/2 + 0.5)

    --  return
    --end
    updateStackTexts()

    if voidformBar then
      if playerIsInVoidform then
        local insanity = UnitPower("player", "INSANITY")
        local stacks = select(4, UnitBuff("player", "Voidform")) - 2 -- TODO: Figure out localization
        -- local expires = math.floor((math.sqrt(16*insanity + 4*(stacks^2) + 148*stacks + 1369) - 2*stacks - 37)/2 + 0.5)
        local expires = (math.sqrt(16*insanity + 4*(stacks^2) + 148*stacks + 1369) - 2*stacks - 37)/2
        Singularity.bars.static.voidform.expires = GetTime() + expires
      end
    end
  end
end

Singularity["COMBAT_LOG_EVENT_UNFILTERED"] = function(self, event, ...)
  local timestamp, subevent, _, srcGUID, _, _, _, tarGUID, tarName, _, _, spellID, _, _, _, powerType = ...

  if srcGUID ~= UnitGUID("player") then return end
  if not SingularityDB.showDoTBars then return end

  if voidformBar then
    if spellID == 194249 and srcGUID == UnitGUID("player") then -- Voidform
      if subevent == "SPELL_AURA_APPLIED" then
        playerIsInVoidform = true
        Singularity.bars.static.voidform:SetScript("OnUpdate", function()
          local vf = Singularity.bars.static.voidform
          -- local insanity = UnitPower("player", "INSANITY")
          -- local stacks = select(4, UnitBuff("player", "Voidform")) - 2 -- TODO: Figure out localization
          -- local timeLeft = math.floor((math.sqrt(16*insanity + 4*(stacks^2) + 148*stacks + 1369) - 2*stacks - 37)/2 + 0.5)
          timeLeft = (vf.expires or 0) - GetTime()
          vf:SetValue(timeLeft)
        end)
      elseif subevent == "SPELL_AURA_REMOVED" then
        playerIsInVoidform = false
        Singularity.bars.static.voidform:SetScript("OnUpdate", nil)
        Singularity.bars.static.voidform:SetValue(0)
      end
    end
  end

  if subevent == "SPELL_DAMAGE" and spellID == 205448 then
    for dot, _ in pairs(SingularityDB.dots) do
      for _, frame in pairs(Singularity.bars.dynamic) do
        if type(frame) == "table" then
          if frame.GUID == tarGUID then
            local f = frame[dot]
            -- I have no idea what to refresh the timers to.
            -- f.expires = f.expires + min(f.baseDuration, f.baseDuration * 1.3 - f.timeLeft)
            -- f.expires = GetTime() + f.baseDuration + 2 -- ???????????????????????????
            break
          end
        end
      end
    end
    return
  end

  if not SingularityDB.dots[spellID] then return end

  if subevent == "UNIT_DIED" then
    clearFrame(Singularity.bars.dynamic[tarGUID])
  end

  if subevent == "SPELL_AURA_APPLIED_DOSE" and spellID == 217673 then -- Mind Spike
    for _, frame in pairs(Singularity.bars.dynamic) do
      if type(frame) == "table" then
        if frame.GUID == tarGUID then
          local f = frame[spellID]
          f.expires = GetTime() + 10
          break
        end
      end
    end
    return
  end

  if subevent == "SPELL_AURA_REFRESH" then
    for _, frame in pairs(Singularity.bars.dynamic) do
      if type(frame) == "table" then
        if frame.GUID == tarGUID then
          local f = frame[spellID]
          f.expires = f.expires + min(f.baseDuration, f.baseDuration * 1.3 - f.timeLeft)
          break
        end
      end
    end
    return
  end

  if subevent == "SPELL_AURA_REMOVED" then
    local p
    for _, frame in pairs(Singularity.bars.dynamic) do
      if type(frame) == "table" then
        if frame.GUID == tarGUID then
          p = frame
          local f = p[spellID]
          f.isActive = false
          f:SetValue(0)
          f:SetScript("OnUpdate", nil)
          break
        end
      end
    end

    if p then
      p[spellID]:Hide()
      clearFrame(p[spellID])
      reorderBars()
    end
    return
  end

  if subevent == "SPELL_AURA_APPLIED" then
    local test = true
    local p
    for k,v in pairs(Singularity.bars.dynamic) do
      if type(v) == "table" then
        local bar = v
        if (not bar.GUID) or bar.GUID == tarGUID then -- Reuse unit frame
          test = false
          p = bar
          p:Show()
          break
        end
      end
    end

    if test then -- Create unit frame
      p = CreateFrame("frame", nil, Singularity.bars.dynamic)
      table.insert(Singularity.bars.dynamic, p)
      p:SetBackdrop(SingularityDB.backdrop)
      p:SetBackdropColor(0, 0, 0, 0.5)
      p:SetBackdropBorderColor(0, 0, 0, 1)
      local w = SingularityDB.dynBarSize[1]
      local iconW = SingularityDB.dynIconSize[1]
      p:SetSize(w + iconW + 2 + 1, 1)
      local n = 0

      for splID in pairs(SingularityDB.dots) do -- Create spell frames
        if not p[splID] then
          p[splID] = CreateFrame("StatusBar", nil, p)
          p[splID].spellID = splID
          p[splID].icon = CreateFrame("frame", nil, p[splID])
          p[splID].icon.tex = p[splID].icon:CreateTexture()
          p[splID].icon.fs = p[splID].icon:CreateFontString()
          p[splID].icon.fs:SetFont(unpack(SingularityDB.font))
          p[splID]:Hide()
          setupBar(p[splID], p, n)
          p[splID]:SetHeight(SingularityDB.dynBarSize[2])
          p[splID].icon:SetHeight(SingularityDB.dynBarSize[2])
          p[splID].icon.tex:SetTexCoord(unpack(SingularityDB.dynTexCoords))
          p[splID]:SetWidth(SingularityDB.dynBarSize[1])
          p[splID].icon:SetWidth(SingularityDB.dynBarSize[2])
          n = n + 1
        end
      end

      p.textFrame = CreateFrame("frame", nil, p)

      p.fs1 = p.textFrame:CreateFontString()
      p.fs1:SetFont(unpack(SingularityDB.font))
      local from, to, x, y = unpack(SingularityDB.dynTextPoint)
      p.fs1:SetPoint(from, p, to, x, y)

      p.fs2 = p.textFrame:CreateFontString()
      p.fs2:SetFont(unpack(SingularityDB.font))
      local from, to, x, y = unpack(SingularityDB.dynText2Point)
      p.fs2:SetPoint(from, p, to, x, y)

      p:SetFrameStrata("HIGH")
    end

    local f = p[spellID]
    f:Show()
    p.name = tarName:gsub("%S+%s", function(s) return s:sub(1,1) .. ". " end)
    p.GUID = tarGUID

    reorderBars()

    f.baseDuration = SingularityDB.baseDuration[spellID]
    f.expires = GetTime() + f.baseDuration
    f.isActive = true
    f.set = true

    f:SetScript("OnUpdate", function()
      local _, _, _, castTime = GetSpellInfo(f.spellID)
      castTime = castTime / 1000
      f.timeLeft = max(f.expires - GetTime(), 0.01)
      f:SetValue(f.timeLeft)

      local expiring = f.timeLeft - castTime <= f.baseDuration * 0.3

      if not expiring and f.set then
        f.set = false
        f:SetStatusBarColor(unpack(SingularityDB.barColor))
      elseif expiring and not f.set then
        f.set = true
        f:SetStatusBarColor(unpack(SingularityDB.barRefreshColor))
      end

      if f.timeLeft <= 0.01 then
        f:SetScript("OnUpdate", nil)
      end
    end)

    return
  end
end
