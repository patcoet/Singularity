-- TODO: Make sure all inputs get validated, sliders have good values, etc.
-- TODO: Anchor inputs should be selects

local sm = LibStub("LibSharedMedia-3.0")
sm:Register("border", "Solid", "Interface\\AddOns\\Singularity\\SolidBorder")
sm:Register("font", "Marke Eigenbau", "Interface\\AddOns\\Singularity\\Marken.ttf")
sm:Register("font", "PF Arma Five", "Interface\\AddOns\\Singularity\\pf_arma_five.ttf")
sm:Register("font", "Manaspace", "Interface\\AddOns\\Singularity\\manaspc.ttf")

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
    header = {
      name = "Appearance options",
      order = 0,
      type = "header",
    },
    barContainerGroup = {
      name = "Bar container frame",
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
                Singularity_reloadBars()
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
                Singularity_reloadBars()
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
                Singularity_reloadBars()
              end,
            },
            barContainerEdgeTexture = {
              name = "Edge texture",
              type = "select",
              order = 3,
              values = AceGUIWidgetLSMlists.border,
              dialogControl = "LSM30_Border",
              get = function() return getHandle("border", SingularityDB.targetContainer.backdrop.edgeFile) end,
              set = function(i, key)
                SingularityDB.targetContainer.backdrop.edgeFile = sm:Fetch("border", key)
                Singularity_reloadBars()
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
                Singularity_reloadBars()
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
                Singularity_reloadBars()
              end,
            },
            barContainerTileSize = {
              name = "Tile size",
              type = "input",
              order = 5,
              get = function() return tostring(SingularityDB.targetContainer.backdrop.tileSize) end,
              set = function(i, value)
                SingularityDB.targetContainer.backdrop.tileSize = value
                Singularity_reloadBars()
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
                    Singularity_reloadBars()
                  end,
                },
                barContainerInsetRight = {
                  order = 102,
                  name = "Right",
                  type = "input",
                  get = function() return tostring(SingularityDB.targetContainer.backdrop.insets.right) end,
                  set = function(i, value)
                    SingularityDB.targetContainer.backdrop.insets.right = value
                    Singularity_reloadBars()
                  end,
                },
                barContainerInsetTop = {
                  order = 102,
                  name = "Top",
                  type = "input",
                  get = function() return tostring(SingularityDB.targetContainer.backdrop.insets.top) end,
                  set = function(i, value)
                    SingularityDB.targetContainer.backdrop.insets.top = value
                    Singularity_reloadBars()
                  end,
                },
                barContainerInsetBottom = {
                  order = 102,
                  name = "Bottom",
                  type = "input",
                  get = function() return tostring(SingularityDB.targetContainer.backdrop.insets.bottom) end,
                  set = function(i, value)
                    SingularityDB.targetContainer.backdrop.insets.bottom = value
                    Singularity_reloadBars()
                  end,
                },
              },
            },
          },
        },
        barContainerAnchorGroup = {
          name = "Anchor",
          type = "group",
          inline = false,
          args = {
            barContainerAnchorFrom = {
              name = "Anchor from",
              type = "select",
              values = anchorPoints,
              get = function() return SingularityDB.targetContainer.anchorFrom end,
              set = function(i, key)
                SingularityDB.targetContainer.anchorFrom = key
                Singularity_reloadBars()
              end,
            },
            barContainerAnchorFrame = {
              name = "Anchor frame",
              type = "input",
              width = "double",
              get = function() return SingularityDB.targetContainer.anchorFrame end,
              set = function(i, value)
                SingularityDB.targetContainer.anchorFrame = value
                Singularity_reloadBars()
              end,
            },
            barContainerAnchorTo = {
              name = "Anchor to",
              type = "select",
              values = anchorPoints,
              get = function() return SingularityDB.targetContainer.anchorTo end,
              set = function(i, key)
                SingularityDB.targetContainer.anchorTo = key
                Singularity_reloadBars()
              end,
            },
            barContainerXOffset = {
              name = "X offset",
              type = "input",
              get = function() return tostring(SingularityDB.targetContainer.xOffset) end,
              set = function(i, value)
                SingularityDB.targetContainer.xOffset = value
                Singularity_reloadBars()
              end,
            },
            barContainerYOffset = {
              name = "Y offset",
              type = "input",
              get = function() return tostring(SingularityDB.targetContainer.yOffset) end,
              set = function(i, value)
                SingularityDB.targetContainer.yOffset = value
                Singularity_reloadBars()
              end,
            },
          },
        },
        barContainerSpacing = {
          name = "Spacing",
          desc = "Spacing between bar container edges and timer bars",
          type = "input",
          get = function() return tostring(SingularityDB.targetContainer.spacing) end,
          set = function(i, value)
            SingularityDB.targetContainer.spacing = value
            Singularity_reloadBars()
          end,
        },
      },
    },
    timerBarGroup = {
      name = "Timer bar frames",
      type = "group",
      inline = false,
      args = {
        barMaxTime = { -- Is this an appearance or functionality option?
          name = "Common maximum time",
          type = "range",
          min = 1,
          max = 30,
          softMin = 4,
          softMax = 20,
          get = function() return SingularityDB.bar.maxTime end,
          set = function(i, value) SingularityDB.bar.maxTime = value end,
        },
        barHeight = {
          name = "Height",
          type = "input",
          get = function() return tostring(SingularityDB.bar.height) end,
          set = function(i, value)
            SingularityDB.bar.height = value
            Singularity_reloadBars()
          end,
        },
        barSpacing = {
          name = "Spacing",
          desc = "Vertical spacing between individual bars",
          type = "input",
          get = function() return tostring(SingularityDB.bar.spacing) end,
          set = function(i, value)
            SingularityDB.bar.spacing = value
            Singularity_reloadBars()
          end,
        },
        barWidth = {
          name = "Width",
          type = "input",
          get = function() return tostring(SingularityDB.bar.width) end,
          set = function(i, value)
            SingularityDB.bar.width = value
            Singularity_reloadBars()
          end,
        },
        iconGroup = {
          name = "Spell icons",
          type = "group",
          inline = true,
          args = {
            iconAnchorYOffset = {
              name = "X offset",
              type = "input",
              get = function() return tostring(SingularityDB.bar.icon.xOffset) end,
              set = function(i, value)
                SingularityDB.bar.icon.xOffset = value
                Singularity_reloadBars()
              end,
            },
            iconSize = {
              name = "Size",
              type = "input",
              get = function() return tostring(SingularityDB.bar.icon.size) end,
              set = function(i, value)
                SingularityDB.bar.icon.size = value
                Singularity_reloadBars()
              end,
            },
          },
        },
        barTextureGroup = {
          name = "Bar texture",
          type = "group",
          inline = true,
          args = {
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
                Singularity_reloadBars()
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
                Singularity_reloadBars()
              end,
            },
            barTextureInset = {
              name = "Texture inset",
              desc = "Space between texture and border",
              type = "input",
              get = function() return tostring(SingularityDB.bar.texture.inset) end,
              set = function(i, value)
                SingularityDB.bar.texture.inset = value
                Singularity_reloadBars()
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
              values = AceGUIWidgetLSMlists.background,
              dialogControl = "LSM30_Background",
              get = function() return getHandle("background", SingularityDB.bar.backdrop.bgFile) end,
              set = function(i, key)
                SingularityDB.bar.backdrop.bgFile = sm:Fetch("background", key)
                Singularity_reloadBars()
              end,
            },
            barBackdropColor = {
              name = "Backdrop color",
              type = "color",
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
                Singularity_reloadBars()
              end,
            },
            barBorderColor = {
              name = "Border color",
              type = "color",
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
                Singularity_reloadBars()
              end,
            },
            barEdgeTexture = {
              name = "Edge texture",
              type = "select",
              values = AceGUIWidgetLSMlists.border,
              dialogControl = "LSM30_Border",
              get = function() return getHandle("border", SingularityDB.bar.backdrop.edgeFile) end,
              set = function(i, key)
                SingularityDB.bar.backdrop.edgeFile = sm:Fetch("border", key)
                Singularity_reloadBars()
              end,
            },
            barEdgeSize = {
              name = "Edge size",
              type = "range",
              min = 0,
              softMin = 1,
              softMax = 16,
              max = 100,
              get = function() return SingularityDB.bar.backdrop.edgeSize end,
              set = function(i, value)
                SingularityDB.bar.backdrop.edgeSize = value
                Singularity_reloadBars()
              end,
            },
            barShouldTile = {
              name = "Tile",
              type = "toggle",
              get = function() return SingularityDB.bar.backdrop.tile end,
              set = function()
                local cfg = SingularityDB.bar.backdrop
                cfg.tile = not cfg.tile
                Singularity_reloadBars()
              end,
            },
            barTileSize = {
              name = "Tile size",
              type = "input",
              get = function() return tostring(SingularityDB.bar.backdrop.tileSize) end,
              set = function(i, value)
                SingularityDB.bar.backdrop.tileSize = value
                Singularity_reloadBars()
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
                    Singularity_reloadBars()
                  end,
                },
                barInsetRight = {
                  order = 102,
                  name = "Right",
                  type = "input",
                  get = function() return tostring(SingularityDB.bar.backdrop.insets.right) end,
                  set = function(i, value)
                    SingularityDB.bar.backdrop.insets.right = value
                    Singularity_reloadBars()
                  end,
                },
                barInsetTop = {
                  order = 102,
                  name = "Top",
                  type = "input",
                  get = function() return tostring(SingularityDB.bar.backdrop.insets.top) end,
                  set = function(i, value)
                    SingularityDB.bar.backdrop.insets.top = value
                    Singularity_reloadBars()
                  end,
                },
                barInsetBottom = {
                  order = 102,
                  name = "Bottom",
                  type = "input",
                  get = function() return tostring(SingularityDB.bar.backdrop.insets.bottom) end,
                  set = function(i, value)
                    SingularityDB.bar.backdrop.insets.bottom = value
                    Singularity_reloadBars()
                  end,
                },
              },
            },
          },
        },
      },
    },
    iconTextGroup = {
      name = "Icon text",
      type = "group",
      inline = false,
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
  },
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Singularity", options, nil)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Singularity")