-- Basic functionality:
-- Add Insanity tracking (UNIT_POWER_FREQUENT, arg1 == "player", arg2 ==
-- "INSANITY", where Orbs tracking was before)
-- Insanity decay rate tracking? Time until 0? In bar form?
-- Remove range tracking
-- Remove tracking of things that are no longer in the game
-- Add tracking of new things (Void Torrent, Void Bolt, Shadow Word: Void,
-- Lingering Insanity?, Shadow Word: Death health threshold changing depending
-- on talents, Void Ray + stack text, Shadow Crash, Mind Spike stacks)

-- Later:
-- Use StatusBar frames for easier updating (which I should've been doing from
-- the start...)
-- Redo the whole config thing, because there's no way creating all the options
-- manually is the best way to do it
-- Split OnEvent into different functions to make it less monolithic
-- Basically just review all the code














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
  -- nonHiddenBars = {
  --   205448, -- Void Bolt
  -- },
  DeathBar = 32379, -- Shadow Word: Death
  dots = {
    589, -- Shadow Word: Pain
    34914, -- Vampiric Touch
    217673, -- Mind Spike
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
  font = {"Interface\\AddOns\\Singularity\\Marken.ttf", 8, "THINOUTLINEMONOCHROME"},
  fontPoint = {"CENTER", "CENTER", 2, 0},
  gcdBarColor = {1, 1, 1, 0.5},
  hiddenBars = {
    ["cast"] = false,
    [34433] = true,
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
  showDoTBars = true,
  SingularityPoint = {"TOP", "UIParent", "CENTER", 0, -162},
  staticParent = "UIParent",
  shouldReplaceIcon = {
    [228260] = 205448, -- Void Eruption -> Void Bolt
  },
  staticSortOrder = {
    "cast",
    15407, -- Mind Flay
    8092, -- Mind Blast
    32379, -- Shadow Word: Death
    34433, -- Shadowfriend
    205448, -- Void Bolt
  },
  texCoords = {0.1, 0.9, 0.1, 0.9},
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
-- cfg.nonHiddenBars = toSet(cfg.nonHiddenBars)
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

  for spellID in pairs(SingularityDB.buffs) do
    if IsPlayerSpell(spellID) and SingularityDB.texts[spellID] then
      Singularity.bars.static[SingularityDB.texts[spellID]].icon.fs:SetText("")
    end
  end
end

local function onUpdate(self, elapsed)
  -- self.dt = self.dt + elapsed
  -- if self.dt < SingularityDB.updateInterval then -- Update Shadow Word: Death desaturation and range display at most every 50 ms, just in case it might make a difference to someone's FPS sometime
  --   return
  -- else
    -- self.dt = self.dt - SingularityDB.updateInterval
  -- end
  if haveMouseover and not UnitExists("mouseover") then
    haveMouseover = false
    updateBarTexts()
  end

  if SingularityDB.DeathBar then
    if (not UnitExists("target")) or UnitHealth("target") > UnitHealthMax("target") * 0.2 then
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

  b.gcd = CreateFrame("frame", nil, Singularity)
  b.gcd.tex = b.gcd:CreateTexture()
  b.gcd.icon = CreateFrame("frame", nil, b.gcd)
  b.gcd.icon.tex = b.gcd.icon:CreateTexture()
  -- b.gcd.icon.fs = b.gcd.icon:CreateFontString()
  -- b.gcd.icon.fs:SetFont(unpack(SingularityDB.font))
  b.static = CreateFrame("frame", nil, Singularity)
  b.static.cast = CreateFrame("frame", nil, b.static)
  b.static.cast.tex = b.static.cast:CreateTexture()
  b.static.cast.icon = CreateFrame("frame", nil, b.static.cast)
  b.static.cast.icon.tex = b.static.cast.icon:CreateTexture()
  b.static.cast.icon.fs = b.static.cast.icon:CreateFontString()
  b.dynamic:SetPoint("TOP", b.static, "BOTTOM", 0, -1) -- TODO -- TODO: Figure out what I was supposed to do here

  for spellID in pairs(SingularityDB.cooldowns) do
    b.static[spellID] = CreateFrame("frame", nil, b.static)
    b.static[spellID].spellID = spellID
    b.static[spellID].tex = b.static[spellID]:CreateTexture()
    b.static[spellID].icon = CreateFrame("frame", nil, b.static[spellID])
    b.static[spellID].icon.tex = b.static[spellID].icon:CreateTexture()
    b.static[spellID].icon.fs = b.static[spellID].icon:CreateFontString()
  end

  for spellID in pairs(SingularityDB.buffs) do
    b.static[spellID] = CreateFrame("frame", nil, b.static)
    b.static[spellID].spellID = spellID
    b.static[spellID].tex = b.static[spellID]:CreateTexture()
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
  frame:SetPoint(af, parent, at, ox + SingularityDB.iconSize[1] / 2, oy - (frame:GetHeight() + SingularityDB.barGap) * n) -- TODO

  frame.tex:SetPoint("LEFT", frame, "LEFT")
  frame.tex:SetSize(unpack(SingularityDB.barSize))
  frame.tex:SetTexture(SingularityDB.barTexture)
  frame.tex:SetVertexColor(unpack(SingularityDB.barColor))
  frame.tex:SetWidth(0.01) -- So bars don't appear full until they're first used

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

local function eventHandler(self, event, ...)
  -- Also listen for target changing to trigger DoT frame reordering, death to trigger text and buff updates, maybe vehicle stuff to trigger hiding. Maybe set the Singularity frame to be shown on seeing an interesting cast/buff/whatever as a failsafe, because if those things happen then clearly the player isn't in a vehicle.
  -- print("eventHandler", event, ...)

  if event == "PLAYER_REGEN_ENABLED" then
    if SingularityDB.hideOOC then
      Singularity:Hide()
      Singularity.bars.static:Hide()
      Singularity.bars.dynamic:Hide()
    end
    return
  end

  if event == "PLAYER_REGEN_DISABLED" then
    Singularity:Show()
    Singularity.bars.static:Show()
    Singularity.bars.dynamic:Show()
    return
  end

  if event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
    Singularity.loadSettings()
    updateStackTexts()
    return
  end

  if event == "PLAYER_DEAD" then
    updateStackTexts()
    return
  end

  if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" or event == "PLAYER_FOCUS_CHANGED" then
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

  if event == "UNIT_POWER_FREQUENT" then
    local unit, powerType = ...

    if unit == "player" and powerType == "INSANITY" then
      updateStackTexts()
    end
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then -- Handle DoTs and Orbs
    local timestamp, subevent, _, srcGUID, _, _, _, tarGUID, tarName, _, _, spellID, _, _, _, powerType = ...

    if srcGUID ~= UnitGUID("player") then return end

    if subevent == "SPELL_ENERGIZE" then
      if powerType ~= SingularityDB.secondaryResource then return end
      updateStackTexts()
      return
    end

    if not SingularityDB.showDoTBars then return end

    if not SingularityDB.dots[spellID] then return end

    if subevent == "SPELL_AURA_APPLIED" then
      local test = true
      local p
      for k,v in pairs(Singularity.bars.dynamic) do
        if type(v) == "table" then
          local bar = v
          -- print(bar,bar.GUID,tarGUID)
          if (not bar.GUID) or bar.GUID == tarGUID then -- Reuse unit frame
            test = false
            -- print("reusing unit frame")
            p = bar
            p:Show()
            break
          end
        end
      end

      if test then -- Create unit frame
        -- print("creating unit frame",#Singularity.bars.dynamic)
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
            p[splID] = CreateFrame("frame", nil, p)
            p[splID].spellID = splID
            p[splID].tex = p[splID]:CreateTexture()
            p[splID].icon = CreateFrame("frame", nil, p[splID])
            p[splID].icon.tex = p[splID].icon:CreateTexture()
            p[splID].icon.fs = p[splID].icon:CreateFontString()
            p[splID].icon.fs:SetFont(unpack(SingularityDB.font))
            p[splID]:Hide()
            setupBar(p[splID], p, n)
            p[splID]:SetHeight(SingularityDB.dynBarSize[2])
            p[splID].tex:SetHeight(SingularityDB.dynBarSize[2])
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
        f.tex:SetWidth(SingularityDB.dynBarSize[1] * min(f.timeLeft / SingularityDB.barMaxTime, 1))

        local expiring = f.timeLeft - castTime <= f.baseDuration * 0.3

        if not expiring and f.set then
          f.set = false
          f.tex:SetVertexColor(unpack(SingularityDB.barColor))
        elseif expiring and not f.set then
          f.set = true
          f.tex:SetVertexColor(unpack(SingularityDB.barRefreshColor))
        end

        if f.timeLeft == 0.01 then
          f:SetScript("OnUpdate", nil)
        end
      end)

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

    if subevent == "SPELL_AURA_REMOVED" then
      local p
      for _, frame in pairs(Singularity.bars.dynamic) do
        if type(frame) == "table" then
          if frame.GUID == tarGUID then
            p = frame
            local f = p[spellID]
            f.isActive = false
            f.tex:SetWidth(0.01)
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

    if subevent == "UNIT_DIED" then
      clearFrame(Singularity.bars.dynamic[tarGUID])
    end

    return
  end

  if event == "UNIT_AURA" then -- Handle buffs
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
          f.tex:SetWidth(SingularityDB.barSize[1] * min(f.timeLeft / SingularityDB.barMaxTime, 1))
          if f.timeLeft == 0.01 then
            f:SetScript("OnUpdate", nil)
          end
        end)
      end
    end

    return
  end

  if event == "UNIT_SPELLCAST_SENT" then -- Handle the GCD
    local unitID = ...
    if unitID ~= "player" then return end

    local f = Singularity.bars.gcd
    f:SetScript("OnUpdate", function()
      local started, duration = GetSpellCooldown(61304)
      if started then
        f.expires = GetTime() + duration
        f:SetScript("OnUpdate", function()
          f.timeLeft = max(f.expires - GetTime(), 0.01)
          f.tex:SetWidth(SingularityDB.barSize[1] * min(f.timeLeft / SingularityDB.barMaxTime, 1))
          if f.timeLeft == 0 then
            f:SetScript("OnUpdate", nil)
          end
        end)
      end
    end)
  end

  if (not SingularityDB.hiddenBars["cast"]) and (event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START") then -- Handle casts
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
      f.tex:SetWidth(SingularityDB.barSize[1] * min(f.timeLeft / SingularityDB.barMaxTime, 1))
    end)
    return
  end

  if event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then -- Handle aborted casts
    local unitID, _, _, _, spellID = ...
    if unitID ~= "player" then return end

    Singularity.bars.static.cast:SetScript("OnUpdate", nil)
    Singularity.bars.static.cast.tex:SetWidth(0.01)

    return
  end

  if event == "UNIT_SPELLCAST_SUCCEEDED" then -- Handle cooldowns
    local unitID, _, _, _, spellID = ...
    if unitID ~= "player" then return end
    if SingularityDB.hiddenBars[spellID] then return end
    if spellID == 2944 or spellID == 155361 then
      updateStackTexts()
    end

    if not SingularityDB.cooldowns[SingularityDB.links[spellID] or spellID] then return end
    local f = Singularity.bars.static[SingularityDB.links[spellID] or spellID]

    -- Have SingularityDB.cooldowns[spellID].alts = {}, being a table of spellIDs to hide when this one activates

    local started, duration
    local elapsed = 0

    f:SetScript("OnUpdate", function(self, dt)
      elapsed = elapsed + dt
      if elapsed > 1 then
        f:SetScript("OnUpdate", nil) -- In case... something? ¯\_(ツ)_/¯
      end
      started, duration = GetSpellCooldown(spellID)
      if started and started > 0 then
        f.expires = GetTime() + duration
        f:SetScript("OnUpdate", function()
          local _, duration = GetSpellCooldown(spellID)
          -- f.timeLeft = max(f.expires - GetTime(), 0.01)
          f.timeLeft = max(started + duration - GetTime(), 0.01)
          f.tex:SetWidth(SingularityDB.barSize[1] * min(f.timeLeft / SingularityDB.barMaxTime, 1))
          if f.timeLeft == 0.01 then
            f:SetScript("OnUpdate", nil)
          end
        end)
      end
    end)
    return
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
  Singularity.bars.dynamic:SetSize(1,1)

  Singularity:UnregisterAllEvents()
  for _, event in pairs(SingularityDB.trackedEvents) do
    Singularity:RegisterEvent(event)
  end

  Singularity:SetScript("OnUpdate", onUpdate)
  Singularity:SetScript("OnEvent", eventHandler)

  local p = Singularity.bars.static

  local n = 0

  for i, barIndex in pairs(SingularityDB.staticSortOrder) do
    if p[barIndex] and (not SingularityDB.hiddenBars[barIndex]) and (not (barIndex == "cast" and SingularityDB.hiddenBars["cast"])) then
      if not (barIndex ~= "cast" and not IsPlayerSpell(barIndex)) then
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
      if SingularityDB.hiddenBars[k] or (k ~= "cast" and not IsPlayerSpell(k)) then
        frame:Hide()
      else
        frame:Show()
      end
    end
  end

  local w, h = unpack(SingularityDB.barSize)

  p:SetHeight((h + SingularityDB.barGap) * n + 1)

  setupBar(Singularity.bars.gcd, Singularity.bars.static, 0)

  Singularity.bars.gcd.tex:SetVertexColor(unpack(SingularityDB.gcdBarColor))
  Singularity.bars.gcd.tex:SetPoint("TOPLEFT", Singularity.bars.gcd, "TOPLEFT")
  Singularity.bars.gcd.tex:SetHeight(Singularity.bars.static:GetHeight() - 2)
  Singularity.bars.gcd:SetFrameStrata("HIGH")

  local _, _, icon = GetSpellInfo(15407)
  Singularity.bars.static.cast.icon.tex:SetTexture(icon)

  for k, v in pairs(Singularity.bars.dynamic) do
    if type(v) == "table" then
      v:SetWidth(SingularityDB.dynBarSize[1] + SingularityDB.dynIconSize[1] + 2 + 1)
      local n = 0
      for spellID, frame in pairs(v) do
        if type(frame) == "table" then
          if frame.tex then
            setupBar(frame, v, n)
            frame.tex:SetSize(unpack(SingularityDB.dynBarSize))
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
