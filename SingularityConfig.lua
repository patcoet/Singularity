local sm = LibStub("LibSharedMedia-3.0")
sm:Register("border", "Solid", "Interface\\AddOns\\Singularity\\SolidBorder")
sm:Register("font", "Marke Eigenbau", "Interface\\AddOns\\Singularity\\Marken.ttf")

local function getHandle(type, path)
  local table = sm:HashTable(type)
  for k, v in pairs(table) do
    if v == path then
      return k
    end
  end
end

local anchorPoints = {
  ["TOPLEFT"] = "Top left",
  ["TOP"] = "Top",
  ["TOPRIGHT"] = "Top right",
  ["RIGHT"] = "Right",
  ["BOTTOMRIGHT"] = "Bottom right",
  ["BOTTOM"] = "Bottom",
  ["BOTTOMLEFT"] = "Bottom left",
  ["LEFT"] = "Left",
  ["CENTER"] = "Center",
}

local options = {
  type = "group",
  args = {
    generalOptionsGroup = {
      name = "General options",
      type = "group",
      order = 0,
      args = {
        alwaysShowOrbText = {
          name = "Display Shadow Orbs stacks at 0",
          type = "toggle",
          width = "double",
          order = 1,
          get = function() return SingularityDB.alwaysShowOrbsText end,
          set = function()
            SingularityDB.alwaysShowOrbsText = not SingularityDB.alwaysShowOrbsText
            Singularity_updateOrbsText()
          end,
        },
        alwaysShowSpikeText = {
          name = "Display Glyph of Mind Spike stacks at 0",
          type = "toggle",
          width = "double",
          order = 1,
          get = function() return SingularityDB.alwaysShowSpikeText end,
          set = function()
            SingularityDB.alwaysShowSpikeText = not SingularityDB.alwaysShowSpikeText
            Singularity_updateSpikeText()
          end,
        },
        alwaysShowSurgeText = {
          name = "Display Surge of Darkness stacks at 0",
          type = "toggle",
          width = "double",
          order = 1,
          get = function() return SingularityDB.alwaysShowSurgeText end,
          set = function()
            SingularityDB.alwaysShowSurgeText = not SingularityDB.alwaysShowSurgeText
            Singularity_updateSurgeText()
          end,
        },
        hideShadowfriend = {
          name = "Hide Shadowfriend bar",
          type = "toggle",
          get = function()
            for k, v in pairs(SingularityDB.hiddenSpells) do
              if k == "Shadowfiend" then
                return true
              end
            end
            return false
          end,
          set = function(i, hiding)
            if hiding then
              SingularityDB.hiddenSpells["Shadowfiend"] = ""
            else
              SingularityDB.hiddenSpells["Shadowfiend"] = nil
            end
            Singularity_updateBars()
          end,
        },
        hideSWP = {
          name = "Hide Shadow Word: Pain bar",
          type = "toggle",
          width = "double",
          get = function()
            for k, v in pairs(SingularityDB.hiddenSpells) do
              if k == "Shadow Word: Pain" then
                return true
              end
            end
            return false
          end,
          set = function(i, hiding)
            if hiding then
              SingularityDB.hiddenSpells["Shadow Word: Pain"] = ""
            else
              SingularityDB.hiddenSpells["Shadow Word: Pain"] = nil
            end
            Singularity_updateBars()
          end,
        },
        hideVT = {
          name = "Hide Vampiric Touch bar",
          type = "toggle",
          width = "double",
          get = function()
            for k, v in pairs(SingularityDB.hiddenSpells) do
              if k == "Vampiric Touch" then
                return true
              end
            end
            return false
          end,
          set = function(i, hiding)
            if hiding then
              SingularityDB.hiddenSpells["Vampiric Touch"] = ""
            else
              SingularityDB.hiddenSpells["Vampiric Touch"] = nil
            end
            Singularity_updateBars()
          end,
        },
        hideMF = {
          name = "Hide Mind Flay bar",
          type = "toggle",
          width = "double",
          get = function()
            for k, v in pairs(SingularityDB.hiddenSpells) do
              if k == "Mind Flay" then
                return true
              end
            end
            return false
          end,
          set = function(i, hiding)
            if hiding then
              SingularityDB.hiddenSpells["Mind Flay"] = ""
              SingularityDB.hiddenSpells["Mind Sear"] = ""
              SingularityDB.hiddenSpells["Insanity"] = ""
            else
              SingularityDB.hiddenSpells["Mind Flay"] = nil
              SingularityDB.hiddenSpells["Mind Sear"] = nil
              SingularityDB.hiddenSpells["Insanity"] = nil
            end
            Singularity_updateBars()
          end,
        },
        hideWithNoTarget = {
          name = "Hide Singularity with no enemy target",
          type = "toggle",
          width = "double",
          order = 1,
          get = function() return SingularityDB.hideWithNoTarget end,
          set = function()
            SingularityDB.hideWithNoTarget = not SingularityDB.hideWithNoTarget
            if SingularityDB.hideWithNoTarget and not UnitExists("target") then
              Singularity:Hide()
            else
              Singularity:Show()
            end
          end,
        },
        barMaxTime = {
          name = "Common maximum bar time",
          desc = "(Seconds)",
          type = "range",
          width = "double",
          order = -1,
          min = 1,
          max = 30,
          softMin = 4,
          softMax = 14,
          get = function() return SingularityDB.bar.maxTime end,
          set = function(i, value) SingularityDB.bar.maxTime = value end,
        },
        updateInterval = {
          name = "Range display update interval (seconds)",
          type = "input",
          width = "double",
          order = -1,
          get = function() return tostring(SingularityDB.updateInterval) end,
          set = function(i, value)
            SingularityDB.updateInterval = value + 0
          end,
        },
      },
    },
    barContainerGroup = {
      name = "Bar container",
      type = "group",
      inline = false,
      args = {
        barContainerTextureGroup = {
          name = "Textures",
          type = "group",
          inline = false,
          args = {
            barContainerBackdropTexture = {
              name = "Backdrop texture",
              type = "select",
              order = 1,
              values = AceGUIWidgetLSMlists.background,
              dialogControl = "LSM30_Background",
              get = function() return getHandle("background", SingularityDB.targetContainer.backdrop.bgFile) end,
              set = function(i, key)
                SingularityDB.targetContainer.backdrop.bgFile = sm:Fetch("background", key)
                Singularity_updateBars()
              end,
            },
            barContainerBackdropColor = {
              name = "Backdrop color",
              type = "color",
              order = 0,
              hasAlpha = true,
              get = function()
                local cfg = SingularityDB.targetContainer.backdrop.color
                return cfg.r, cfg.g, cfg.b, cfg.a
              end,
              set = function(i, r, g, b, a)
                local cfg = SingularityDB.targetContainer.backdrop.color
                cfg.r = r
                cfg.g = g
                cfg.b = b
                cfg.a = a
                Singularity_updateBars()
              end,
            },
            barContainerBorderColor = {
              name = "Border color",
              type = "color",
              order = 2,
              hasAlpha = true,
              get = function()
                local cfg = SingularityDB.targetContainer.backdrop.borderColor
                return cfg.r, cfg.g, cfg.b
              end,
              set = function(i, r, g, b, a)
                local cfg = SingularityDB.targetContainer.backdrop.borderColor
                cfg.r = r
                cfg.g = g
                cfg.b = b
                cfg.a = a
                Singularity_updateBars()
              end,
            },
            barContainerEdgeTexture = {
              name = "Border texture",
              type = "select",
              order = 3,
              values = AceGUIWidgetLSMlists.border,
              dialogControl = "LSM30_Border",
              get = function() return getHandle("border", SingularityDB.targetContainer.backdrop.edgeFile) end,
              set = function(i, key)
                SingularityDB.targetContainer.backdrop.edgeFile = sm:Fetch("border", key)
                Singularity_updateBars()
              end,
            },
            barContainerEdgeSize = {
              name = "Edge size",
              type = "range",
              width = "double",
              order = 4,
              min = 0,
              softMin = 1,
              softMax = 16,
              max = 100,
              get = function() return SingularityDB.targetContainer.backdrop.edgeSize end,
              set = function(i, value)
                SingularityDB.targetContainer.backdrop.edgeSize = value
                Singularity_updateBars()
              end,
            },
            barContainerShouldTile = {
              name = "Tile",
              type = "toggle",
              order = 6,
              get = function() return SingularityDB.targetContainer.backdrop.tile end,
              set = function()
                local cfg = SingularityDB.targetContainer.backdrop
                cfg.tile = not cfg.tile
                Singularity_updateBars()
              end,
            },
            barContainerTileSize = {
              name = "Tile size",
              type = "input",
              order = 5,
              get = function() return tostring(SingularityDB.targetContainer.backdrop.tileSize) end,
              set = function(i, value)
                SingularityDB.targetContainer.backdrop.tileSize = value
                Singularity_updateBars()
              end,
            },
            barContainerInsetGroup = {
              name = "Border insets",
              type = "group",
              order = -1,
              inline = true,
              args = {
                barContainerInsetLeft = {
                  order = 102,
                  name = "Left",
                  type = "input",
                  get = function() return tostring(SingularityDB.targetContainer.backdrop.insets.left) end,
                  set = function(i, value)
                    SingularityDB.targetContainer.backdrop.insets.left = value
                    Singularity_updateBars()
                  end,
                },
                barContainerInsetRight = {
                  order = 102,
                  name = "Right",
                  type = "input",
                  get = function() return tostring(SingularityDB.targetContainer.backdrop.insets.right) end,
                  set = function(i, value)
                    SingularityDB.targetContainer.backdrop.insets.right = value
                    Singularity_updateBars()
                  end,
                },
                barContainerInsetTop = {
                  order = 102,
                  name = "Top",
                  type = "input",
                  get = function() return tostring(SingularityDB.targetContainer.backdrop.insets.top) end,
                  set = function(i, value)
                    SingularityDB.targetContainer.backdrop.insets.top = value
                    Singularity_updateBars()
                  end,
                },
                barContainerInsetBottom = {
                  order = 102,
                  name = "Bottom",
                  type = "input",
                  get = function() return tostring(SingularityDB.targetContainer.backdrop.insets.bottom) end,
                  set = function(i, value)
                    SingularityDB.targetContainer.backdrop.insets.bottom = value
                    Singularity_updateBars()
                  end,
                },
              },
            },
          },
        },
        barContainerAnchorGroup = {
          name = "Anchor",
          type = "group",
          inline = true,
          args = {
            barContainerParentFrame = {
              name = "Parent frame",
              type = "input",
              order = 0,
              get = function() return SingularityDB.targetContainer.parentFrame end,
              set = function(i, value)
                SingularityDB.targetContainer.parentFrame = value
                Singularity_updateBars()
              end,
            },
            barContainerAnchorFrom = {
              name = "Anchor from",
              type = "select",
              values = anchorPoints,
              get = function() return SingularityDB.targetContainer.anchorFrom end,
              set = function(i, key)
                SingularityDB.targetContainer.anchorFrom = key
                Singularity_updateBars()
              end,
            },
            barContainerAnchorFrame = {
              name = "Anchor frame",
              type = "input",
              order = 0,
              get = function() return SingularityDB.targetContainer.anchorFrame end,
              set = function(i, value)
                SingularityDB.targetContainer.anchorFrame = value
                Singularity_updateBars()
              end,
            },
            barContainerAnchorTo = {
              name = "Anchor to",
              type = "select",
              values = anchorPoints,
              get = function() return SingularityDB.targetContainer.anchorTo end,
              set = function(i, key)
                SingularityDB.targetContainer.anchorTo = key
                Singularity_updateBars()
              end,
            },
            barContainerXOffset = {
              name = "X offset",
              type = "input",
              get = function() return tostring(SingularityDB.targetContainer.xOffset) end,
              set = function(i, value)
                SingularityDB.targetContainer.xOffset = value
                Singularity_updateBars()
              end,
            },
            barContainerYOffset = {
              name = "Y offset",
              type = "input",
              get = function() return tostring(SingularityDB.targetContainer.yOffset) end,
              set = function(i, value)
                SingularityDB.targetContainer.yOffset = value
                Singularity_updateBars()
              end,
            },
          },
        },
      },
    },
    timerBarGroup = {
      name = "Timer bars",
      type = "group",
      inline = false,
      args = {
        barHeight = {
          name = "Height",
          type = "input",
          order = 1,
          get = function() return tostring(SingularityDB.bar.height) end,
          set = function(i, value)
            SingularityDB.bar.height = value
            Singularity_updateBars()
          end,
        },
        barSpacing = {
          name = "Inner spacing",
          desc = "Vertical spacing between individual bars",
          type = "input",
          get = function() return tostring(SingularityDB.bar.spacing) end,
          set = function(i, value)
            SingularityDB.bar.spacing = value
            Singularity_updateBars()
          end,
        },
        barContainerSpacing = {
          name = "Outer spacing",
          desc = "Spacing between bar container edges and timer bars",
          type = "input",
          get = function() return tostring(SingularityDB.targetContainer.spacing) end,
          set = function(i, value)
            SingularityDB.targetContainer.spacing = value
            Singularity_updateBars()
          end,
        },
        barWidth = {
          name = "Width",
          type = "input",
          order = 0,
          get = function() return tostring(SingularityDB.bar.width) end,
          set = function(i, value)
            SingularityDB.bar.width = value
            Singularity_updateBars()
          end,
        },
        barTextureInset = {
          name = "Texture spacing",
          desc = "Spacing between bar texture and border",
          type = "input",
          get = function() return tostring(SingularityDB.bar.texture.inset) end,
          set = function(i, value)
            SingularityDB.bar.texture.inset = value
            Singularity_updateBars()
          end,
        },
        barColorsGroup = {
          name = "Bar colors",
          type = "group",
          order = 0,
          inline = true,
          args = {
            gcdBarColor = {
              name = "GCD color",
              desc = "Color used to display the global cooldown",
              type = "color",
              hasAlpha = true,
              get = function()
                local cfg = SingularityDB.gcdColor
                return cfg.r, cfg.g, cfg.b, cfg.a
              end,
              set = function(i, r, g, b, a)
                local cfg = SingularityDB.gcdColor
                cfg.r = r
                cfg.g = g
                cfg.b = b
                cfg.a = a
                Singularity_updateBars()
              end,
            },
            barTextureNormalColor = {
              name = "Normal color",
              type = "color",
              hasAlpha = true,
              get = function()
                local cfg = SingularityDB.bar.texture.color
                return cfg.r, cfg.g, cfg.b, cfg. a
              end,
              set = function(i, r, g, b, a)
                local cfg = SingularityDB.bar.texture.color
                cfg.r = r
                cfg.g = g
                cfg.b = b
                cfg.a = a
                Singularity_updateBars()
              end,
            },
            barTextureAlertColor = {
              name = "Alert color",
              desc = "Color used when DoTs are safe to refresh",
              type = "color",
              hasAlpha = true,
              get = function()
                local cfg = SingularityDB.bar.texture.alert
                return cfg.r, cfg.g, cfg.b, cfg. a
              end,
              set = function(i, r, g, b, a)
                local cfg = SingularityDB.bar.texture.alert
                cfg.r = r
                cfg.g = g
                cfg.b = b
                cfg.a = a
                Singularity_updateBars()
              end,
            },
          },
        },
        barBackdropGroup = {
          name = "Textures",
          type = "group",
          inline = false,
          args = {
            barBackdropTexture = {
              name = "Backdrop texture",
              type = "select",
              order = 1,
              values = AceGUIWidgetLSMlists.background,
              dialogControl = "LSM30_Background",
              get = function() return getHandle("background", SingularityDB.bar.backdrop.bgFile) end,
              set = function(i, key)
                SingularityDB.bar.backdrop.bgFile = sm:Fetch("background", key)
                Singularity_updateBars()
              end,
            },
            barBackdropColor = {
              name = "Backdrop color",
              type = "color",
              order = 0,
              hasAlpha = true,
              get = function()
                local cfg = SingularityDB.bar.backdrop.color
                return cfg.r, cfg.g, cfg.b, cfg.a
              end,
              set = function(i, r, g, b, a)
                local cfg = SingularityDB.bar.backdrop.color
                cfg.r = r
                cfg.g = g
                cfg.b = b
                cfg.a = a
                Singularity_updateBars()
              end,
            },
            barBorderColor = {
              name = "Border color",
              type = "color",
              order = 2,
              hasAlpha = true,
              get = function()
                local cfg = SingularityDB.bar.backdrop.borderColor
                return cfg.r, cfg.g, cfg.b
              end,
              set = function(i, r, g, b, a)
                local cfg = SingularityDB.bar.backdrop.borderColor
                cfg.r = r
                cfg.g = g
                cfg.b = b
                cfg.a = a
                Singularity_updateBars()
              end,
            },
            barEdgeTexture = {
              name = "Border texture",
              type = "select",
              order = 3,
              values = AceGUIWidgetLSMlists.border,
              dialogControl = "LSM30_Border",
              get = function() return getHandle("border", SingularityDB.bar.backdrop.edgeFile) end,
              set = function(i, key)
                SingularityDB.bar.backdrop.edgeFile = sm:Fetch("border", key)
                Singularity_updateBars()
              end,
            },
            barEdgeSize = {
              name = "Edge size",
              type = "range",
              order = 4,
              width = "double",
              min = 0,
              softMin = 1,
              softMax = 16,
              max = 100,
              get = function() return SingularityDB.bar.backdrop.edgeSize end,
              set = function(i, value)
                SingularityDB.bar.backdrop.edgeSize = value
                Singularity_updateBars()
              end,
            },
            barShouldTile = {
              name = "Tile",
              type = "toggle",
              order = 6,
              get = function() return SingularityDB.bar.backdrop.tile end,
              set = function()
                local cfg = SingularityDB.bar.backdrop
                cfg.tile = not cfg.tile
                Singularity_updateBars()
              end,
            },
            barTileSize = {
              name = "Tile size",
              type = "input",
              order = 5,
              get = function() return tostring(SingularityDB.bar.backdrop.tileSize) end,
              set = function(i, value)
                SingularityDB.bar.backdrop.tileSize = value
                Singularity_updateBars()
              end,
            },
            barInsetGroup = {
              name = "Border insets",
              type = "group",
              inline = true,
              args = {
                barInsetLeft = {
                  order = 102,
                  name = "Left",
                  type = "input",
                  get = function() return tostring(SingularityDB.bar.backdrop.insets.left) end,
                  set = function(i, value)
                    SingularityDB.bar.backdrop.insets.left = value
                    Singularity_updateBars()
                  end,
                },
                barInsetRight = {
                  order = 102,
                  name = "Right",
                  type = "input",
                  get = function() return tostring(SingularityDB.bar.backdrop.insets.right) end,
                  set = function(i, value)
                    SingularityDB.bar.backdrop.insets.right = value
                    Singularity_updateBars()
                  end,
                },
                barInsetTop = {
                  order = 102,
                  name = "Top",
                  type = "input",
                  get = function() return tostring(SingularityDB.bar.backdrop.insets.top) end,
                  set = function(i, value)
                    SingularityDB.bar.backdrop.insets.top = value
                    Singularity_updateBars()
                  end,
                },
                barInsetBottom = {
                  order = 102,
                  name = "Bottom",
                  type = "input",
                  get = function() return tostring(SingularityDB.bar.backdrop.insets.bottom) end,
                  set = function(i, value)
                    SingularityDB.bar.backdrop.insets.bottom = value
                    Singularity_updateBars()
                  end,
                },
              },
            },
          },
        },
      },
    },
    iconGroup = {
      name = "Spell icons",
      type = "group",
      inline = false,
      args = {
        iconTextGroup = {
          name = "Icon text",
          type = "group",
          inline = true,
          order = 0,
          args = {
            iconTextAnchorFrom = {
              name = "Anchor from",
              type = "select",
              values = anchorPoints,
              get = function() return SingularityDB.bar.text.anchorFrom end,
              set = function(i, key)
                SingularityDB.bar.text.anchorFrom = key
                Singularity_updateFonts()
              end,
            },
            iconTextAnchorTo = {
              name = "Anchor to",
              type = "select",
              values = anchorPoints,
              get = function() return SingularityDB.bar.text.anchorTo end,
              set = function(i, key)
                SingularityDB.bar.text.anchorTo = key
                Singularity_updateFonts()
              end,
            },
            iconTextXOffset = {
              name = "X offset",
              type = "input",
              get = function() return tostring(SingularityDB.bar.text.xOffset) end,
              set = function(i, value)
                SingularityDB.bar.text.xOffset = value
                Singularity_updateFonts()
              end,
            },
            iconTextYOffset = {
              name = "Y offset",
              type = "input",
              get = function() return tostring(SingularityDB.bar.text.yOffset) end,
              set = function(i, value)
                SingularityDB.bar.text.yOffset = value
                Singularity_updateFonts()
              end,
            },
            iconTextFont = {
              name = "Font",
              type = "select",
              order = 0,
              values = AceGUIWidgetLSMlists.font,
              dialogControl = "LSM30_Font",
              get = function() return getHandle("font", SingularityDB.bar.text.fontPath) end,
              set = function(i, key)
                SingularityDB.bar.text.fontPath = sm:Fetch("font", key)
                Singularity_updateFonts()
              end,
            },
            iconTextFontSize = {
              name = "Size",
              type = "input",
              order = 1,
              get = function() return tostring(SingularityDB.bar.text.fontSize) end,
              set = function(i, value)
                SingularityDB.bar.text.fontSize = value
                Singularity_updateFonts()
              end,
            },
            iconTextFontFlags = {
              name = "Font flags",
              type = "multiselect",
              order = 2,
              values = {
                ["THINOUTLINE"] = "Thin outline",
                ["THICKOUTLINE"] = "Thick outline",
                ["MONOCHROME"] = "Monochrome",
              },
              get = function(s, key, value)
                local s = SingularityDB.bar.text.fontFlags
                return s:find(key) and true or false
              end,
              set = function(s, flag, enable)
                local s = SingularityDB.bar.text.fontFlags
                local isMonochrome = s:find("MONOCHROME") ~= nil
                if flag ~= "MONOCHROME" then
                  s = enable and flag or ""
                  if isMonochrome then
                    s = s .. "MONOCHROME"
                  end
                else
                  s = enable and s .. flag or s:gsub(flag, "")
                end
                SingularityDB.bar.text.fontFlags = s
                Singularity_updateFonts()
              end,
            },
          },
        },
        iconSizeGroup = {
          name = "Icon size",
          type = "group",
          inline = true,
          args = {
            iconAnchorXOffset = {
              name = "X offset",
              type = "input",
              get = function() return tostring(SingularityDB.bar.icon.xOffset) end,
              set = function(i, value)
                SingularityDB.bar.icon.xOffset = value
                Singularity_updateBars()
              end,
            },
            iconHeight = {
              name = "Height",
              type = "input",
              get = function() return tostring(SingularityDB.bar.icon.height) end,
              set = function(i, value)
                SingularityDB.bar.icon.height = value
                Singularity_updateBars()
              end,
            },
            iconWidth = {
              name = "Width",
              type = "input",
              get = function() return tostring(SingularityDB.bar.icon.width) end,
              set = function(i, value)
                SingularityDB.bar.icon.width = value
                Singularity_updateBars()
              end,
            },
          },
        },
        iconCoordsGroup = {
          name = "Coords",
          type = "group",
          order = -1,
          inline = false,
          args = {
            iconCoordLeft = {
              name = "Left",
              type = "input",
              get = function() return tostring(SingularityDB.bar.icon.coords.l) end,
              set = function(i, value)
                SingularityDB.bar.icon.coords.l = value
                Singularity_updateBars()
                end,
            },
            iconCoordRight = {
              name = "Right",
              type = "input",
              get = function() return tostring(SingularityDB.bar.icon.coords.r) end,
              set = function(i, value)
                SingularityDB.bar.icon.coords.r = value
                Singularity_updateBars()
                end,
            },
            iconCoordTop = {
              name = "Top",
              type = "input",
              get = function() return tostring(SingularityDB.bar.icon.coords.t) end,
              set = function(i, value)
                SingularityDB.bar.icon.coords.t = value
                Singularity_updateBars()
                end,
            },
            iconCoordBottom = {
              name = "Bottom",
              type = "input",
              get = function() return tostring(SingularityDB.bar.icon.coords.b) end,
              set = function(i, value)
                SingularityDB.bar.icon.coords.b = value
                Singularity_updateBars()
                end,
            },
          },
        },
      },
    },
  },
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Singularity", options, nil)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Singularity")

SLASH_SINGULARITY1, SLASH_SINGULARITY2 = "/singularity", "/sng"
function SlashCmdList.SINGULARITY()
  InterfaceOptionsFrame_OpenToCategory("Singularity")
end