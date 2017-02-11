Singularity = CreateFrame("Frame", nil, UIParent)
Singularity.name, Singularity.thing = ...
Singularity:RegisterEvent("ADDON_LOADED")
Singularity:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
Singularity:RegisterEvent("PLAYER_ENTERING_WORLD")
local SingularityDB = {}

local debug = function(...)
  --print("Singularity:", ...) -- XXX: Comment out before release
end

local defaults = {
  width = 200,
  height = 24,
  spacing = 1,
  borderWidth = 1,
  interval = 1/30,
  maxTime = 6,
  x = 0,
  y = -190,
  inset = 0.8,

  backdrop = {
  	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  	edgeFile = "Interface\\AddOns\\Singularity\\onepixel",
  	tile = false,
  	tileSize = 0,
  	edgeSize = 1,
  	insets = {left = 1, right = 1, top = 1, bottom = 1},
  },
}

-- local spells = {    -- [spellId] = shown
--   [17]     = false, -- Power Word: Shield
--   [586]    = false, -- Fade
--   [8092]   = true,  -- Mind Blast
--   [8122]   = false, -- Psychic Scream
--   [10060]  = false, -- Power Infusion
--   [32375]  = false, -- Mass Dispel
--   [47585]  = false, -- Dispersion
--   [199911] = true,  -- Shadow Word: Death (talented)
--   [205448] = false,  -- Void Bolt
-- }

local spells = { -- {spellId, shown}
	-- (So that we can use ipairs to iterate through them in a set order)
	{205448, false}, -- Void Bolt
	{8092,   true}, -- Mind Blast
	{199911, true}, -- Shadow Word: Death (talented)
	{205385, false}, -- Shadow Crash
}

local colors = {
  {215, 7, 125, 1},
  {186, 2, 106, 1},
  {149, 8, 88, 1},
  {120, 6, 70, 1},
  {78, 0, 44, 1},
}
for i, color in ipairs(colors) do
	for j = 1, 3 do
		color[j] = color[j]/255
	end
end

local executeRange = 0.35
local executeBar = 199911
local showInsanityBar = true
local lagCompensation = 0.300 -- Pretend cooldowns finish 300 ms earlier

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
  	local start, duration
  	-- if bar.spellId == executeBar then
  	-- 	local curr, max = GetSpellCharges(bar.spellId)
  	-- 	if curr == max then
  	-- 		start = 0
  	-- 	else
  	-- 	  start, duration = select(3, GetSpellCharges(bar.spellId))
  	-- 	end
  	-- else
	    start, duration = GetSpellCooldown(bar.spellId)
	  -- end
    if start and start > 0 + lagCompensation then
      bar:SetValue(((start + duration) - GetTime()) - lagCompensation)
    else
      bar:SetValue(0)
    end
  end
end

local init = function()
	debug("init")
  for k, v in pairs(defaults) do
    -- if SingularityDB[k] == nil then -- XXX: Uncomment before release
      SingularityDB[k] = defaults[k]
    -- end
  end

  local cfg = SingularityDB
  Singularity:SetPoint("CENTER", UIParent, "CENTER", cfg.x + (cfg.borderWidth * 2 + cfg.spacing + cfg.height)/2, cfg.y)
  Singularity:SetSize(1, 1)
  Singularity:Show()
  Singularity.bars = Singularity.bars or {} -- Create table if it doesn't exist
  local i = 0

  Singularity.cast = Singularity.cast or
                     CreateFrame("StatusBar", nil, Singularity)
  local bar = Singularity.cast
  bar:SetSize(cfg.width - cfg.borderWidth * 2, cfg.height - cfg.borderWidth * 2)
  local spacing = -(i * (bar:GetHeight() + cfg.borderWidth * 2 + cfg.spacing))
  bar:SetPoint("TOP", Singularity, "TOP", 0, spacing)
  bar:SetMinMaxValues(0, cfg.maxTime)
  bar:SetValue(0)
  bar:SetStatusBarTexture("Interface\\AddOns\\Singularity\\flat")
  bar:SetStatusBarColor(unpack(colors[i + 1]))
  bar.bg = bar.bg or CreateFrame("Frame", nil, bar)
  bar.bg:SetPoint("CENTER")
  bar.bg:SetSize(cfg.width, cfg.height)
  bar.bg:SetBackdrop(cfg.backdrop)
  bar.bg:SetBackdropColor(0, 0, 0, 0.5)
  bar.bg:SetBackdropBorderColor(0, 0, 0, 1)
  if bar.icon == nil then
	  bar.icon = CreateFrame("Frame", nil, bar)
	  bar.icon:SetPoint("RIGHT", bar, "LEFT", -(cfg.borderWidth * 2 + cfg.spacing), 0)
	  bar.icon:SetSize(cfg.height - cfg.borderWidth * 2, cfg.height - cfg.borderWidth * 2)
	  bar.icon.bg = bar.icon:CreateTexture(nil, "MEDIUM")
	  bar.icon.bg:SetColorTexture(0, 0, 0, 1)
    bar.icon.bg:SetPoint("CENTER")
    bar.icon.bg:SetSize(cfg.height, cfg.height)
    bar.icon.tex = bar.icon:CreateTexture(nil, "MEDIUM", nil, 1)
    local _, _, fileId = GetSpellInfo(61304)
    bar.icon.tex:SetTexture(fileId)
    bar.icon.tex:SetAllPoints()
	  bar.icon.tex:SetTexCoord(1 - cfg.inset, cfg.inset, 1 - cfg.inset, cfg.inset) 
  end
  i = i + 1

  if showInsanityBar then
  	debug("setting up insanity bar")
	  Singularity.insanity = Singularity.insanity or
	                         CreateFrame("StatusBar", nil, Singularity)
	  local bar = Singularity.insanity
	  bar:SetSize(cfg.width - cfg.borderWidth * 2, cfg.height - cfg.borderWidth * 2)
	  local spacing = -(i * (bar:GetHeight() + cfg.borderWidth * 2 + cfg.spacing))
	  bar:SetPoint("TOP", Singularity, "TOP", 0, spacing)
	  bar:SetMinMaxValues(0, 100)
	  bar:SetValue(UnitPower("player"))
	  bar:SetStatusBarTexture("Interface\\AddOns\\Singularity\\flat")
	  bar:SetStatusBarColor(unpack(colors[i + 1]))

	  bar.bg = bar.bg or CreateFrame("Frame", nil, bar)
	  bar.bg:SetPoint("CENTER")
	  bar.bg:SetSize(cfg.width, cfg.height)
	  bar.bg:SetBackdrop(cfg.backdrop)
	  bar.bg:SetBackdropColor(0, 0, 0, 0.5)
	  bar.bg:SetBackdropBorderColor(0, 0, 0, 1)
	  i = i + 1

		if bar.icon == nil then
		  bar.icon = CreateFrame("Frame", nil, bar)
		  bar.icon:SetPoint("RIGHT", bar, "LEFT", -(cfg.borderWidth * 2 + cfg.spacing), 0)
		  bar.icon:SetSize(cfg.height - cfg.borderWidth * 2, cfg.height - cfg.borderWidth * 2)
		  bar.icon.bg = bar.icon:CreateTexture(nil, "MEDIUM")
		  bar.icon.bg:SetColorTexture(0, 0, 0, 1)
	    bar.icon.bg:SetPoint("CENTER")
	    bar.icon.bg:SetSize(cfg.height, cfg.height)
	    bar.icon.tex = bar.icon:CreateTexture(nil, "MEDIUM", nil, 1)
	    local _, _, fileId = GetSpellInfo(194249)
	    bar.icon.tex:SetTexture(fileId)
	    bar.icon.tex:SetAllPoints()
	    bar.icon.tex:SetTexCoord(1 - cfg.inset, cfg.inset, 1 - cfg.inset, cfg.inset) 
	  end
	end

  for _, spell in ipairs(spells) do
  	local spellId, shown = spell[1], spell[2]
    Singularity.bars[spellId] = Singularity.bars[spellId] or
                                CreateFrame("StatusBar", nil, Singularity)
    local bar = Singularity.bars[spellId]
    bar.spellId = spellId
    if bar.icon == nil then
	    bar.icon = CreateFrame("Frame", nil, bar)
	    bar.icon:SetPoint("RIGHT", bar, "LEFT", -(cfg.borderWidth * 2 + cfg.spacing), 0)
	    bar.icon:SetSize(cfg.height - cfg.borderWidth * 2, cfg.height - cfg.borderWidth * 2)

	    bar.icon.bg = bar.icon:CreateTexture(nil, "MEDIUM")
	    bar.icon.bg:SetColorTexture(0, 0, 0, 1)
	    bar.icon.bg:SetPoint("CENTER")
	    bar.icon.bg:SetSize(cfg.height, cfg.height)

	    bar.icon.tex = bar.icon:CreateTexture(nil, "MEDIUM", nil, 1)
	    local _, _, fileId = GetSpellInfo(spellId)
	    bar.icon.tex:SetTexture(fileId)
	    bar.icon.tex:SetAllPoints()
	    bar.icon.tex:SetTexCoord(1 - cfg.inset, cfg.inset, 1 - cfg.inset, cfg.inset)
	  end

	  if shown then
	  	bar:Show()
	  	bar:SetSize(cfg.width - cfg.borderWidth * 2, cfg.height - cfg.borderWidth * 2)
	  	local spacing = -(i * (bar:GetHeight() + cfg.borderWidth * 2 + cfg.spacing))
	  	bar:SetPoint("TOP", Singularity, "TOP", 0, spacing)
	  	bar:SetMinMaxValues(0, cfg.maxTime)
	  	bar:SetStatusBarTexture("Interface\\AddOns\\Singularity\\flat")
	  	bar:SetStatusBarColor(unpack(colors[i + 1]))
	  	-- bar.bg = bar.bg or bar:CreateTexture(nil, "BACKGROUND")
	  	-- bar.bg:SetPoint("CENTER")
	  	-- bar.bg:SetSize(bar:GetWidth() + 2, bar:GetHeight() + 2)
	  	-- bar.bg:SetColorTexture(0, 0, 0, 1)

	    bar.bg = bar.bg or CreateFrame("Frame", nil, bar)
	    bar.bg:SetPoint("CENTER")
	    bar.bg:SetSize(cfg.width, cfg.height)
	    bar.bg:SetBackdrop(cfg.backdrop)
	    bar.bg:SetBackdropColor(0, 0, 0, 0.5)
	    bar.bg:SetBackdropBorderColor(0, 0, 0, 1)

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
	Singularity:RegisterEvent("PLAYER_TARGET_CHANGED")
	Singularity:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Singularity:RegisterEvent("UNIT_POWER_FREQUENT")
	Singularity:RegisterEvent("UNIT_SPELLCAST_START")
	Singularity:RegisterEvent("UNIT_SPELLCAST_STOP")
	Singularity:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	Singularity:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
end

local hideBar = function(bar)
	debug("hideBar", bar)
	if bar == "insanity" then
		showInsanityBar = false
		Singularity.insanity:Hide()
	else
		for _, spell in ipairs(spells) do
			if spell[1] == bar then
				spell[2] = false
			end
		end
	end
	--init()
end

local showBar = function(bar)
	debug("showBar", bar)
	if bar == "insanity" then
		showInsanityBar = true
		Singularity.insanity:Show()
	else
		for _, spell in ipairs(spells) do
			if spell[1] == bar then
				spell[2] = true
			end
		end
	end
	-- init()
end

local disable = function()
	Singularity:SetScript("OnUpdate", nil)
	Singularity:UnregisterAllEvents()
	Singularity:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	Singularity:Hide()
end

Singularity:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and ... == "Singularity"
		or event == "PLAYER_ENTERING_WORLD" then
		Singularity:UnregisterEvent("ADDON_LOADED")


		Singularity:SetScript("OnUpdate", function()
			Singularity:SetScript("OnUpdate", nil)

			local _, class = UnitClass("player")
			local specId = GetSpecialization()

			if class == "PRIEST" and specId == 3 then
				init()
			else
				disable()
			end
		end)
	end

	if event == "PLAYER_SPECIALIZATION_CHANGED" and ... == "player" then
		local _, class = UnitClass("player")
		local specId = GetSpecialization()

		if class == "PRIEST" and specId == 3 then
			init()
		else
			disable()
		end
	end

  if (event == "UNIT_HEALTH_FREQUENT" and ... == "target") or (event == "PLAYER_TARGET_CHANGED" and UnitExists("target")) then
  	debug("health")
    local cur, max = UnitHealth("target"), UnitHealthMax("target")

    -- if cur/max < executeRange then
    if IsUsableSpell(32379) or (select(4, GetTalentInfo(4, 2)) and IsUsableSpell(199911)) then
      -- showBar(executeBar)
      Singularity.bars[executeBar].icon.tex:SetDesaturated(false)
    else
      -- hideBar(executeBar)
      Singularity.bars[executeBar].icon.tex:SetDesaturated(true)
    end
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
  	local subevent = select(2, ...)
  	local srcGuid = select(4, ...)
  	local spellId = select(12, ...)
    if spellId == 194249 and srcGuid == UnitGUID("player") then -- Voidform
    	if subevent == "SPELL_AURA_APPLIED" then
    		hideBar("insanity")
    		showBar(205448)
    		init()
  		elseif subevent == "SPELL_AURA_REMOVED" then
  			showBar("insanity")
  			hideBar(205448)
  			init()
  		end
  	end
  end

  if event == "UNIT_POWER_FREQUENT" then
  	local unit, powerType = ...

  	if unit == "player" and powerType == "INSANITY" then
  		Singularity.insanity:SetValue(UnitPower("player"))
  		if IsUsableSpell(228260) then -- Void Eruption
  			Singularity.insanity.icon.tex:SetDesaturated(false)
  		else
  			Singularity.insanity.icon.tex:SetDesaturated(true)
  		end
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
			local _, _, _, texture = UnitCastingInfo("player")
			Singularity.cast.icon.tex:SetTexture(texture)
		elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
			local endTime = select(6, UnitChannelInfo("player"))/1000
			Singularity.cast:SetScript("OnUpdate", function(self)
				self:SetValue(endTime - GetTime())
				if endTime <= GetTime() then
  				self:SetScript("OnUpdate", nil)
				end
			end)
			local _, _, _, texture = UnitChannelInfo("player")
			Singularity.cast.icon.tex:SetTexture(texture)
		elseif event == "UNIT_SPELLCAST_STOP"
				or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
			Singularity.cast:SetValue(0)
			Singularity.cast:SetScript("OnUpdate", nil)
		end
	end
end)

