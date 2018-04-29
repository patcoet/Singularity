SingularityFrame = CreateFrame("Frame", nil, UIParent)
Singularity = LibStub("AceAddon-3.0"):NewAddon("Singularity")

-- TODO:
-- Settings: add and remove bars
--           do PitBull's default bar thing for bar colors
--             (have a default bar color setting and individual bar color settings)

local debug = function() end

local defaultProfile = {
  profile = {
    backdrop = {
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\AddOns\\Singularity\\Singularity_flat",
      tile = false,
      tileSize = 1,
      edgeSize = 1,
      insets = {left = 1, right = 1, top = 1, bottom = 1},
    },
    barColor = {215/255, 7/255, 125/255, 1},
    bgColor = {0, 0, 0, 0.5},
    borderColor = {0, 0, 0, 1},
    colors = {
      {215/255, 7/255, 125/255, 1},
      {186/255, 2/255, 106/255, 1},
      {149/255, 8/255, 88/255, 1},
      {120/255, 6/255, 70/255, 1},
      {78/255, 0/255, 44/255, 1},
    },
    spells = {
      228260, -- Void Eruption/Bolt
      8092, -- Mind Blast
      32379, -- Shadow Word: Death
      205385, -- Shadow Crash
    },

    barSpacing = 1,
    borderWidth = 1,
    height = 16,
    iconSpacing = 1,
    inset = 0.8,
    maxTime = 6,
    updatesPerSecond = 60,
    width = 164,
    x = 0,
    y = -250,

    anchorFrame = "UIParent",
    anchorFrom = "CENTER",
    anchorTo = "CENTER",
    barTexture = "Singularity_flat",
    borderTexture = "Singularity_flat",
    parentFrame = "UIParent",

    debugging = false,
    desaturateUnusableSpells = true,
    showCastBar = true,
    showIcons = true,
    usingSpellQueueWindow = false,
  },
}

local options = {
  name = "Singularity",
  handler = Singularity,
  type = "group",
  args = {
    settings = {
      name = "Settings",
      type = "group",
      order = 0,
      args = {},
    },
  },
}

function Singularity:CreateFrames()
  debug("CreateFrames")
  SingularityFrame.bars = {}

  local cfg = self.db.profile

  -- if cfg.showCastBar then
    debug("setting up cast bar")
    SingularityFrame.cast = CreateFrame("Frame", nil, SingularityFrame)
    SingularityFrame.cast.bar = CreateFrame("StatusBar", nil, SingularityFrame.cast)
    if cfg.showIcons then
      SingularityFrame.cast.icon = CreateFrame("Frame", nil, SingularityFrame.cast)
      SingularityFrame.cast.icon.tex = SingularityFrame.cast.icon:CreateTexture()
    end
  -- end

  for n, spellId in pairs(cfg.spells) do
    debug("setting up bar for spellID", spellId)
    SingularityFrame.bars[spellId] = CreateFrame("Frame", nil, SingularityFrame)
    SingularityFrame.bars[spellId].bar = CreateFrame("StatusBar", nil, SingularityFrame.bars[spellId])
    if cfg.showIcons then
      SingularityFrame.bars[spellId].icon = CreateFrame("Frame", nil, SingularityFrame.bars[spellId])
      SingularityFrame.bars[spellId].icon.tex = SingularityFrame.bars[spellId].icon:CreateTexture()
    end
  end
end

function Singularity:ApplySettings()
  debug("ApplySettings")
  local cfg = Singularity.db.profile
  local sf = SingularityFrame

  cfg.backdrop.edgeSize = cfg.borderWidth
  cfg.backdrop.edgeFile = LibStub("LibSharedMedia-3.0"):Fetch("border", cfg.borderTexture)

  sf:SetParent(_G[cfg.parentFrame])
  sf:SetPoint(cfg.anchorFrom, _G[cfg.anchorFrame], cfg.anchorTo, cfg.x, cfg.y)
  sf:SetSize(cfg.width, cfg.height)

  local totalBars = 0
  if cfg.showCastBar then
    debug("setting up cast bar")
    if cfg.showIcons then
      sf.cast:SetSize(cfg.width - cfg.height - cfg.iconSpacing, cfg.height)
    else
      sf.cast:SetSize(cfg.width, cfg.height)
    end
    sf.cast:SetPoint("TOPRIGHT")
    sf.cast:SetBackdrop(cfg.backdrop)
    sf.cast:SetBackdropColor(unpack(cfg.bgColor))
    sf.cast:SetBackdropBorderColor(unpack(cfg.borderColor))
    sf.cast.bar:SetPoint("CENTER")
    sf.cast.bar:SetSize(sf.cast:GetWidth() - cfg.backdrop.insets.left*2, sf.cast:GetHeight() - cfg.backdrop.insets.left*2)
    sf.cast.bar:SetMinMaxValues(0, cfg.maxTime)
    sf.cast.bar:SetValue(0)
    sf.cast.bar:SetStatusBarTexture(LibStub("LibSharedMedia-3.0"):Fetch("statusbar", cfg.barTexture))
    sf.cast.bar:SetStatusBarColor(unpack(cfg.barColor))
    if cfg.showIcons then
      sf.cast.icon:SetPoint("RIGHT", sf.cast, "LEFT", -cfg.iconSpacing, 0)
      sf.cast.icon:SetSize(cfg.height, cfg.height)
      sf.cast.icon:SetBackdrop(cfg.backdrop)
      sf.cast.icon:SetBackdropBorderColor(unpack(cfg.borderColor))
      sf.cast.icon.tex:SetPoint("TOPLEFT", sf.cast.icon, "TOPLEFT", cfg.backdrop.insets.left, -cfg.backdrop.insets.left)
      sf.cast.icon.tex:SetPoint("BOTTOMRIGHT", sf.cast.icon, "BOTTOMRIGHT", -cfg.backdrop.insets.left, cfg.backdrop.insets.left)
      local _, _, fileId = GetSpellInfo(61304)
      sf.cast.icon.tex:SetTexture(fileId)
      sf.cast.icon.tex:SetTexCoord(1 - cfg.inset, cfg.inset, 1 - cfg.inset, cfg.inset)
      sf.cast.icon.tex:SetDesaturated(false)
      sf.cast.icon:Show()
    else
      sf.cast.icon:Hide()
    end
    totalBars = totalBars + 1
    sf.cast:Show()
  else
    sf.cast:Hide()
  end

  for n, spellId in pairs(cfg.spells) do
    debug("setting up bar for spellID", spellId)
    sf.bars[spellId].spellId = spellId
    if cfg.showIcons then
      sf.bars[spellId]:SetSize(cfg.width - cfg.height - cfg.iconSpacing, cfg.height)
    else
      sf.bars[spellId]:SetSize(cfg.width, cfg.height)
    end
    sf.bars[spellId]:SetPoint("TOPRIGHT", SingularityFrame, "TOPRIGHT", 0, -(cfg.height + cfg.barSpacing)*totalBars)
    sf.bars[spellId]:SetBackdrop(cfg.backdrop)
    sf.bars[spellId]:SetBackdropColor(unpack(cfg.bgColor))
    sf.bars[spellId]:SetBackdropBorderColor(unpack(cfg.borderColor))
    sf.bars[spellId].bar:SetPoint("CENTER")
    sf.bars[spellId].bar:SetSize(sf.bars[spellId]:GetWidth() - cfg.backdrop.insets.left*2, sf.bars[spellId]:GetHeight() - cfg.backdrop.insets.left*2)
    sf.bars[spellId].bar:SetMinMaxValues(0, cfg.maxTime)
    sf.bars[spellId].bar:SetValue(0)
    sf.bars[spellId].bar:SetStatusBarTexture(LibStub("LibSharedMedia-3.0"):Fetch("statusbar", cfg.barTexture))
    sf.bars[spellId].bar:SetStatusBarColor(unpack(cfg.barColor))
    if cfg.showIcons then
      sf.bars[spellId].icon:SetPoint("RIGHT", sf.bars[spellId], "LEFT", -cfg.iconSpacing, 0)
      sf.bars[spellId].icon:SetSize(cfg.height, cfg.height)
      sf.bars[spellId].icon:SetBackdrop(cfg.backdrop)
      sf.bars[spellId].icon:SetBackdropBorderColor(unpack(cfg.borderColor))
      sf.bars[spellId].icon.tex:SetPoint("TOPLEFT", sf.bars[spellId].icon, "TOPLEFT", cfg.backdrop.insets.left, -cfg.backdrop.insets.left)
      sf.bars[spellId].icon.tex:SetPoint("BOTTOMRIGHT", sf.bars[spellId].icon, "BOTTOMRIGHT", -cfg.backdrop.insets.left, cfg.backdrop.insets.left)
      local _, _, fileId = GetSpellInfo(spellId)
      sf.bars[spellId].icon.tex:SetTexture(fileId)
      sf.bars[spellId].icon.tex:SetTexCoord(1 - cfg.inset, cfg.inset, 1 - cfg.inset, cfg.inset)
      sf.bars[spellId].icon.tex:SetDesaturated(false)
      sf.bars[spellId].icon:Show()
    else
      sf.bars[spellId].icon:Hide()
    end
    totalBars = totalBars + 1
  end

  SingularityFrame:SetHeight(cfg.height * totalBars + cfg.barSpacing * (totalBars - 1))
end

function Singularity:OnInitialize()
  debug("OnInitialize")
  self.db = LibStub("AceDB-3.0"):New("SingularityDB", defaultProfile, true)
  options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  LibStub("AceConfig-3.0"):RegisterOptionsTable("Singularity", options, nil)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Singularity")

  LibStub("LibSharedMedia-3.0"):Register("statusbar", "Singularity_flat", "Interface\\AddOns\\Singularity\\Singularity_flat.tga")
  LibStub("LibSharedMedia-3.0"):Register("border", "Singularity_flat", "Interface\\AddOns\\Singularity\\Singularity_flat.tga")

  self.db.RegisterCallback(Singularity, "OnProfileChanged", "ApplySettings")
  self.db.RegisterCallback(Singularity, "OnProfileCopied", "ApplySettings")
  self.db.RegisterCallback(Singularity, "OnProfileReset", "ApplySettings")

  LibStub("LibDualSpec-1.0"):EnhanceDatabase(self.db, "Singularity")
  LibStub("LibDualSpec-1.0"):EnhanceOptions(options.args.profile, self.db)

  debug = function(...)
    if Singularity.db.profile.debugging then
      print("Singularity:", ...)
    end
  end

  self:CreateFrames()
end

function Singularity:OnEnable()
  debug("OnEnable")
  self:ApplySettings()

  SingularityFrame:RegisterEvent("UNIT_SPELLCAST_START")
  SingularityFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
  SingularityFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
  SingularityFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
  SingularityFrame:SetScript("OnEvent", function(self, event, ...)
    if ... == "player" then
      if event == "UNIT_SPELLCAST_START" then
        local endTime = select(6, UnitCastingInfo("player"))/1000
        SingularityFrame.cast:SetScript("OnUpdate", function(self)
          self.bar:SetValue(endTime - GetTime())
          if endTime <= GetTime() then
            self:SetScript("OnUpdate", nil)
          end
        end)
        local _, _, _, texture = UnitCastingInfo("player")
        if Singularity.db.profile.showIcons then
          SingularityFrame.cast.icon.tex:SetTexture(texture)
        end
      elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local endTime = select(6, UnitChannelInfo("player"))/1000
        SingularityFrame.cast:SetScript("OnUpdate", function(self)
          self.bar:SetValue(endTime - GetTime())
          if endTime <= GetTime() then
            self:SetScript("OnUpdate", nil)
          end
        end)
        local _, _, _, texture = UnitChannelInfo("player")
        if Singularity.db.profile.showIcons then
          SingularityFrame.cast.icon.tex:SetTexture(texture)
        end
      elseif event == "UNIT_SPELLCAST_STOP"
          or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        SingularityFrame.cast.bar:SetValue(0)
        SingularityFrame.cast:SetScript("OnUpdate", nil)
      end
    end
  end)

  local elapsed = 0
  SingularityFrame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed >= 1/Singularity.db.profile.updatesPerSecond then
      elapsed = elapsed - 1/Singularity.db.profile.updatesPerSecond
    else
      return
    end

    for _, bar in pairs(SingularityFrame.bars) do
      local start, duration = GetSpellCooldown(bar.spellId)

      if Singularity.db.profile.showIcons and Singularity.db.profile.desaturateUnusableSpells then
        bar.icon.tex:SetDesaturated(not IsUsableSpell(bar.spellId))
      end

      if Singularity.db.profile.showIcons then
        local _, _, fileId = GetSpellInfo(bar.spellId)
        bar.icon.tex:SetTexture(fileId) -- For spells that do switchy things, like Void Eruption/Bolt
      end

      local spellQueueWindow = 0
      if Singularity.db.profile.usingSpellQueueWindow then
        spellQueueWindow = (0 + GetCVar("SpellQueueWindow"))/1000
      end
      if start and start > 0 + spellQueueWindow then
        bar.bar:SetValue(((start + duration) - GetTime()) - spellQueueWindow)
      else
        bar.bar:SetValue(0)
      end
    end
  end)
end

function Singularity:OnDisable()
  debug("OnDisable")
  SingularityFrame:SetScript("OnUpdate", nil)
  SingularityFrame:UnregisterAllEvents()
  SingularityFrame:Hide()
end











options.args.settings.args.general = {
  type = "group",
  name = "General",
  order = 0,
  args = {
    barTexture = {
      type = "select",
      name = "Bar texture",
      values = LibStub("LibSharedMedia-3.0"):HashTable("statusbar"),
      dialogControl = "LSM30_Statusbar",
      get = function() return Singularity.db.profile.barTexture end,
      set = function(info, value)
        Singularity.db.profile.barTexture = value
        Singularity:ApplySettings()
      end,
    },
    barColor = {
      type = "color",
      name = "Bar color",
      hasAlpha = true,
      get = function() return unpack(Singularity.db.profile.barColor) end,
      set = function(info, r, g, b, a)
        Singularity.db.profile.barColor = {r, g, b, a}
        Singularity:ApplySettings()
      end,
    },
    bgColor = {
      type = "color",
      name = "Bar background color",
      hasAlpha = true,
      get = function() return unpack(Singularity.db.profile.bgColor) end,
      set = function(info, r, g, b, a)
        Singularity.db.profile.bgColor = {r, g, b, a}
        Singularity:ApplySettings()
      end,
    },
    borderColor = {
      type = "color",
      name = "Bar border color",
      hasAlpha = true,
      get = function() return unpack(Singularity.db.profile.borderColor) end,
      set = function(info, r, g, b, a)
        Singularity.db.profile.borderColor = {r, g, b, a}
        Singularity:ApplySettings()
      end,
    },
    desaturateUnusableSpells = {
      name = "Desaturate unusable spells",
      type = "toggle",
      get = function() return Singularity.db.profile.desaturateUnusableSpells end,
      set = function(info, value)
        Singularity.db.profile.desaturateUnusableSpells = value
        Singularity:ApplySettings()
      end,
    },
    showCastBar = {
      name = "Show cast bar",
      type = "toggle",
      get = function() return Singularity.db.profile.showCastBar end,
      set = function(info, value)
        Singularity.db.profile.showCastBar = value
        Singularity:ApplySettings()
      end,
    },
    showIcons = {
      name = "Show icons",
      type = "toggle",
      get = function() return Singularity.db.profile.showIcons end,
      set = function(info, value)
        Singularity.db.profile.showIcons = value
        Singularity:ApplySettings()
      end,
    },
    height = {
      type = "range",
      name = "Bar height",
      softMin = 2,
      softMax = 30,
      step = 1,
      get = function() return Singularity.db.profile.height end,
      set = function(info, value)
        Singularity.db.profile.height = value
        Singularity:ApplySettings()
      end,
    },
    maxTime = {
      type = "range",
      name = "Common max time",
      softMin = 4,
      softMax = 10,
      step = 1,
      get = function() return Singularity.db.profile.maxTime end,
      set = function(info, value)
        Singularity.db.profile.maxTime = value
        Singularity:ApplySettings()
      end
    },
    barSpacing = {
      type = "range",
      name = "Spacing between bars",
      softMin = 0,
      softMax = 10,
      step = 1,
      get = function() return Singularity.db.profile.barSpacing end,
      set = function(info, value)
        Singularity.db.profile.barSpacing = value
        Singularity:ApplySettings()
      end,
    },
    iconSpacing = {
      type = "range",
      name = "Spacing between bars and icons",
      softMin = 0,
      softMax = 10,
      step = 1,
      get = function() return Singularity.db.profile.iconSpacing end,
      set = function(info, value)
        Singularity.db.profile.iconSpacing = value
        Singularity:ApplySettings()
      end,
    },
    width = {
      type = "range",
      name = "Bar width",
      softMin = 100,
      softMax = 300,
      step = 1,
      bigStep = 10,
      get = function() return Singularity.db.profile.width end,
      set = function(info, value)
        Singularity.db.profile.width = value
        Singularity:ApplySettings()
      end,
    },
    x = {
      type = "range",
      name = "Horizontal position",
      softMin = -500,
      softMax = 500,
      step = 0.5,
      bigStep = 10,
      get = function() return Singularity.db.profile.x end,
      set = function(info, value)
        Singularity.db.profile.x = value
        Singularity:ApplySettings()
      end,
    },
    y = {
      type = "range",
      name = "Vertical position",
      softMin = -500,
      softMax = 500,
      step = 0.5,
      bigStep = 10,
      get = function() return Singularity.db.profile.y end,
      set = function(info, value)
        Singularity.db.profile.y = value
        Singularity:ApplySettings()
      end,
    },
  },
}
options.args.settings.args.advanced = {
  type = "group",
  name = "Advanced",
  args = {
    anchorFrame = {
      type = "input",
      name = "Anchor frame",
      get = function() return Singularity.db.profile.anchorFrame end,
      set = function(info, value)
        if _G[value] == nil then
          value = "UIParent"
        end
        Singularity.db.profile.anchorFrame = value
        Singularity:ApplySettings()
      end,
    },
    borderWidth = {
      type = "range",
      name = "Border width",
      min = 0,
      softMax = 10,
      step = 1,
      get = function() return Singularity.db.profile.borderWidth end,
      set = function(info, value)
        Singularity.db.profile.borderWidth = value
        Singularity:ApplySettings()
      end,
    },
    borderInsets = {
      type = "range",
      name = "Border insets",
      min = 0,
      max = 20,
      step = 0.5,
      get = function() return Singularity.db.profile.backdrop.insets.left end,
      set = function(info, value)
        local i = Singularity.db.profile.backdrop.insets
        i.left = value
        i.right = value
        i.top = value
        i.bottom = value
        Singularity:ApplySettings()
      end,
    },
    borderTexture = {
      type = "select",
      name = "Border texture",
      values = LibStub("LibSharedMedia-3.0"):HashTable("border"),
      dialogControl = "LSM30_Border",
      get = function() return Singularity.db.profile.borderTexture end,
      set = function(info, value)
        Singularity.db.profile.borderTexture = value
        Singularity:ApplySettings()
      end,
    },
    inset = {
      type = "range",
      name = "Icon inset",
      min = 0.55,
      max = 1,
      step = 0.05,
      get = function() return Singularity.db.profile.inset end,
      set = function(info, value)
        Singularity.db.profile.inset = value
        Singularity:ApplySettings()
      end,
    },
    updatesPerSecond = {
      type = "range",
      name = "Visual update rate",
      desc = "Maximum updates per second",
      softMin = 15,
      softMax = 60,
      step = 5,
      get = function() return Singularity.db.profile.updatesPerSecond end,
      set = function(info, value)
        Singularity.db.profile.updatesPerSecond = value
        Singularity:ApplySettings()
      end,
    },
    anchorFrom = {
      type = "input",
      name = "Anchor from",
      get = function() return Singularity.db.profile.anchorFrom end,
      set = function(info, value)
        Singularity.db.profile.anchorFrom = value
        Singularity:ApplySettings()
      end,
    },
    anchorTo = {
      type = "input",
      name = "Anchor to",
      get = function() return Singularity.db.profile.anchorTo end,
      set = function(info, value)
        Singularity.db.profile.anchorTo = value
        Singularity:ApplySettings()
      end,
    },
    parentFrame = {
      type = "input",
      name = "Parent frame",
      get = function() return Singularity.db.profile.parentFrame end,
      set = function(info, value)
        if _G[value] == nil then
          value = "UIParent"
        end
        Singularity.db.profile.parentFrame = value
        Singularity:ApplySettings()
      end,
    },

    debugging = {
      name = "Debug mode",
      type = "toggle",
      get = function() return Singularity.db.profile.debugging end,
      set = function(info, value) Singularity.db.profile.debugging = value end,
    },

    usingSpellQueueWindow = {
      name = "Use spell queue window",
      type = "toggle",
      get = function() return Singularity.db.profile.usingSpellQueueWindow end,
      set = function(info, value)
        Singularity.db.profile.usingSpellQueueWindow = value
      end,
    },
  },
}