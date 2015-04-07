local sm = LibStub("LibSharedMedia-3.0")
sm:Register("border", "Solid", "Interface\\AddOns\\Singularity\\SolidBorder")
sm:Register("font", "Marke Eigenbau", "Interface\\AddOns\\Singularity\\Marken.ttf")
sm:Register("statusbar", "Singularity Flat", "Interface\\AddOns\\Singularity\\Singularity_flat")

function getHandle(type, path)
  local table = sm:HashTable(type)
  for k, v in pairs(table) do
    if v == path then
      return k
    end
  end
end

local options = {
  type = "group",
  args = {
    general = {
      name = "General options",
      type = "group",
      order = 0,
      args = {
        staticParent = {
          name = "Parent frame",
          type = "input",
          get = function()
            return tostring(SingularityDB.staticParent)
          end,
          set = function(i, value)
            SingularityDB.staticParent = value
            Singularity.loadSettings()
          end,
        },
        toggleHideOOC = {
          name = "Hide out of combat",
          type = "toggle",
          width = "double",
          order = 6,
          get = function() return SingularityDB.hideOOC end,
          set = function()
            SingularityDB.hideOOC = not SingularityDB.hideOOC
            Singularity.loadSettings()
          end,
        },
        toggleShowCastBar = {
          name = "Show cast bar",
          type = "toggle",
          width = "double",
          order = 6,
          get = function() return not SingularityDB.hiddenBars["cast"] end,
          set = function()
            SingularityDB.hiddenBars["cast"] = not SingularityDB.hiddenBars["cast"]
            Singularity.loadSettings()
          end,
        },
        toggleShowShadowfriendBar = {
          name = "Show Shadowfriend bar",
          type = "toggle",
          width = "double",
          order = 6,
          get = function() return not SingularityDB.hiddenBars[34433] end,
          set = function()
            SingularityDB.hiddenBars[34433] = not SingularityDB.hiddenBars[34433]
            Singularity.loadSettings()
          end,
        },
        toggleDoTs = {
          name = "Show DoT bars",
          type = "toggle",
          width = "double",
          order = 6,
          get = function() return SingularityDB.showDoTBars end,
          set = function()
            SingularityDB.showDoTBars = not SingularityDB.showDoTBars
            Singularity.loadSettings()
          end,
        },
        fontGroup = {
          type = "group",
          name = "Font options",
          inline = true,
          args = {
            font = {
              name = "Font",
              type = "select",
              order = 0,
              values = AceGUIWidgetLSMlists.font,
              dialogControl = "LSM30_Font",
              get = function() return getHandle("font", SingularityDB.font[1]) end,
              set = function(i, key)
                SingularityDB.font[1] = sm:Fetch("font", key)
                Singularity.loadSettings()
              end,
            },
            iconTextFontSize = {
              name = "Size",
              type = "input",
              order = 1,
              get = function() return tostring(SingularityDB.font[2]) end,
              set = function(i, value)
                SingularityDB.font[2] = value
                Singularity.loadSettings()
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
                local s = SingularityDB.font[3]
                return s:find(key) and true or false
              end,
              set = function(s, flag, enable)
                local s = SingularityDB.font[3]
                local isMonochrome = s:find("MONOCHROME") ~= nil
                if flag ~= "MONOCHROME" then
                  s = enable and flag or ""
                  if isMonochrome then
                    s = s .. "MONOCHROME"
                  end
                else
                  s = enable and s .. flag or s:gsub(flag, "")
                end
                SingularityDB.font[3] = s
                Singularity.loadSettings()
              end,
            },
          },
        },
        barColor = {
          name = "Bar color",
          type = "color",
          order = 5,
          hasAlpha = true,
          get = function()
            return unpack(SingularityDB.barColor)
            end,
          set = function(i, r, g, b, a)
            SingularityDB.barColor = {r, g, b, a}
            Singularity.loadSettings()
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
          get = function() return SingularityDB.barMaxTime end,
          set = function(i, value) SingularityDB.barMaxTime = value end,
        },
        barTexture = {
          name = "Bar texture",
          type = "select",
          order = 1,
          width = "double",
          values = AceGUIWidgetLSMlists.statusbar,
          dialogControl = "LSM30_Statusbar",
          get = function()
            return getHandle("statusbar", SingularityDB.barTexture) end,
          set = function(i, key)
            SingularityDB.barTexture = sm:Fetch("statusbar", key)
            Singularity.loadSettings()
          end,
        },
        barWidth = {
          name = "Bar width",
          type = "input",
          order = 5,
          get = function()
            return tostring(SingularityDB.barSize[1] + SingularityDB.iconSize[1])
          end,
          set = function(i, value)
            SingularityDB.barSize[1] = value - SingularityDB.iconSize[1]
            Singularity.loadSettings()
          end,
        },
        SingularityAnchorGroup = {
          name = "Anchor",
          type = "group",
          args = {
            -- Currently broken because of how Singularity.static positioning/sizing is done
            -- anchorFrom = {
            --   name = "Anchor from",
            --   type = "input",
            --   get = function()
            --     return tostring(SingularityDB.SingularityPoint[1])
            --   end,
            --   set = function(i, value)
            --     SingularityDB.SingularityPoint[1] = value
            --     Singularity.loadSettings()
            --   end,
            -- },
            anchorFrame = {
              name = "Anchor frame",
              type = "input",
              get = function()
                -- local frame = SingularityDB.SingularityPoint[2]
                return tostring(SingularityDB.SingularityPoint[2])
              end,
              set = function(i, value)
                SingularityDB.SingularityPoint[2] = value
                Singularity.loadSettings()
              end,
            },
            -- anchorTo = {
            --   name = "Anchor to",
            --   type = "input",
            --   get = function()
            --     return tostring(SingularityDB.SingularityPoint[3])
            --   end,
            --   set = function(i, value)
            --     SingularityDB.SingularityPoint[3] = value
            --     Singularity.loadSettings()
            --   end,
            -- },
            anchorX = {
              name = "Horizontal offset",
              type = "input",
              get = function() return tostring(SingularityDB.SingularityPoint[4]) end,
              set = function(i, value)
                SingularityDB.SingularityPoint[4] = value
                Singularity.loadSettings()
              end,
            },
            anchorY = {
              name = "Vertical offset",
              type = "input",
              get = function() return tostring(SingularityDB.SingularityPoint[5]) end,
              set = function(i, value)
                SingularityDB.SingularityPoint[5] = value
                Singularity.loadSettings()
              end,
            },
          },
        },
        backdropGroup = {
          name = "Textures",
          type = "group",
          inline = false,
          args = {
            backdropTexture = {
              name = "Backdrop texture",
              type = "select",
              order = 1,
              values = AceGUIWidgetLSMlists.background,
              dialogControl = "LSM30_Background",
              get = function() return getHandle("background", SingularityDB.backdrop.bgFile) end,
              set = function(i, value)
                SingularityDB.backdrop.bgFile = sm:Fetch("background", value)
                Singularity.loadSettings()
              end,
            },
            backdropColor = {
              name = "Backdrop color",
              type = "color",
              order = 0,
              hasAlpha = true,
              get = function()
                local c = SingularityDB.backdrop.color
                return SingularityDB.r, SingularityDB.g, SingularityDB.b, SingularityDB.a
              end,
              set = function(i, r, g, b, a)
                local c = SingularityDB.backdrop.color
                SingularityDB.r = r
                SingularityDB.g = g
                SingularityDB.b = b
                SingularityDB.a = a
                Singularity.loadSettings()
              end,
            },
            borderColor = {
              name = "Border color",
              type = "color",
              order = 2,
              hasAlpha = true,
              get = function()
                local c = SingularityDB.backdrop.borderColor
                return SingularityDB.r, SingularityDB.g, SingularityDB.b, SingularityDB.a
              end,
              set = function(i, r, g, b, a)
                local c = SingularityDB.backdrop.borderColor
                SingularityDB.r = r
                SingularityDB.g = g
                SingularityDB.b = b
                SingularityDB.a = a
                Singularity.loadSettings()
              end,
            },
            edgeTexture = {
              name = "Border texture",
              type = "select",
              order = 3,
              values = AceGUIWidgetLSMlists.border,
              dialogControl = "LSM30_Border",
              get = function() return getHandle("border", SingularityDB.backdrop.edgeFile) end,
              set = function(i, value)
                SingularityDB.backdrop.edgeFile = sm:Fetch("border", value)
                Singularity.loadSettings()
              end,
            },
            edgeSize = {
              name = "Edge size",
              type = "range",
              width = "double",
              order = 4,
              min = 0,
              softMin = 1,
              softMax = 16,
              max = 100,
              get = function() return SingularityDB.backdrop.edgeSize end,
              set = function(i, value)
                SingularityDB.backdrop.edgeSize = value
                Singularity.loadSettings()
              end,
            },
            shouldTile = {
              name = "Tile",
              type = "toggle",
              order = 6,
              get = function() return SingularityDB.backdrop.tile end,
              set = function()
                SingularityDB.backdrop.tile = not SingularityDB.backdrop.tile
                Singularity.loadSettings()
              end,
            },
            tileSize = {
              name = "Tile size",
              type = "input",
              order = 5,
              get = function() return tostring(SingularityDB.backdrop.tileSize) end,
              set = function(i, value)
                SingularityDB.backdrop.tileSize = value
                Singularity.loadSettings()
              end,
            },
            insetGroup = {
              name = "Border insets",
              type = "group",
              order = -1,
              inline = true,
              args = {
                insetLeft = {
                  order = 102,
                  name = "Left",
                  type = "input",
                  get = function() return tostring(SingularityDB.backdrop.insets.left) end,
                  set = function(i, value)
                    SingularityDB.backdrop.insets.left = value
                    Singularity.loadSettings()
                  end,
                },
                insetRight = {
                  order = 102,
                  name = "Right",
                  type = "input",
                  get = function() return tostring(SingularityDB.backdrop.insets.right) end,
                  set = function(i, value)
                    SingularityDB.backdrop.insets.right = value
                    Singularity.loadSettings()
                  end,
                },
                insetTop = {
                  order = 102,
                  name = "Top",
                  type = "input",
                  get = function() return tostring(SingularityDB.backdrop.insets.top) end,
                  set = function(i, value)
                    SingularityDB.backdrop.insets.top = value
                    Singularity.loadSettings()
                  end,
                },
                insetBottom = {
                  order = 102,
                  name = "Bottom",
                  type = "input",
                  get = function() return tostring(SingularityDB.backdrop.insets.bottom) end,
                  set = function(i, value)
                    SingularityDB.backdrop.insets.bottom = value
                    Singularity.loadSettings()
                  end,
                },
              },
            },
          },
        },
      },
    },
    staticBars = {
      name = "Static bar options",
      type = "group",
      args = {
        staticBarSize = {
          name = "Static bar height",
          type = "input",
          get = function()
            return tostring(SingularityDB.barSize[2])
          end,
          set = function(i, value)
            SingularityDB.barSize[2] = value
            SingularityDB.iconSize = {value, value}
            Singularity.loadSettings()
          end,
        },
        staticIconCoordsGroup = {
          name = "Icon texture oords",
          type = "group",
          order = -1,
          inline = true,
          args = {
            staticIconCoordLeft = {
              name = "Left",
              type = "input",
              get = function() return tostring(SingularityDB.dynTexCoords[1]) end,
              set = function(i, value)
                SingularityDB.dynTexCoords[1] = value
                Singularity.loadSettings()
              end,
            },
            staticIconCoordRight = {
              name = "Right",
              type = "input",
              get = function() return tostring(SingularityDB.dynTexCoords[2]) end,
              set = function(i, value)
                SingularityDB.dynTexCoords[2] = value
                Singularity.loadSettings()
              end,
            },
            staticIconCoordTop = {
              name = "Top",
              type = "input",
              get = function() return tostring(SingularityDB.dynTexCoords[3]) end,
              set = function(i, value)
                SingularityDB.dynTexCoords[3] = value
                Singularity.loadSettings()
              end,
            },
            staticIconCoordBottom = {
              name = "Bottom",
              type = "input",
              get = function() return tostring(SingularityDB.dynTexCoords[4]) end,
              set = function(i, value)
                SingularityDB.dynTexCoords[4] = value
                Singularity.loadSettings()
              end,
            },
          },
        },
      },
    },
    dynamicBars = {
      name = "Dynamic bar options",
      type = "group",
      args = {
        barRefreshColor = {
          name = "Refresh alert color",
          type = "color",
          hasAlpha = true,
          get = function()
            return unpack(SingularityDB.barRefreshColor)
            end,
          set = function(i, r, g, b, a)
            SingularityDB.barRefreshColor = {r, g, b, a}
            Singularity.loadSettings()
            end,
        },
        dynamicBarSize = {
          name = "Dynamic bar height",
          width = "double",
          type = "input",
          get = function()
            return tostring(SingularityDB.dynBarSize[2])
          end,
          set = function(i, value)
            SingularityDB.dynBarSize[2] = value
            SingularityDB.dynIconSize = {value, value}
            Singularity.loadSettings()
          end,
        },
        dynamicIconCoordsGroup = {
          name = "Icon texture coords",
          type = "group",
          order = -1,
          inline = true,
          args = {
            dynamicIconCoordLeft = {
              name = "Left",
              type = "input",
              get = function() return tostring(SingularityDB.dynTexCoords[1]) end,
              set = function(i, value)
                SingularityDB.dynTexCoords[1] = value
                Singularity.loadSettings()
              end,
            },
            dynamicIconCoordRight = {
              name = "Right",
              type = "input",
              get = function() return tostring(SingularityDB.dynTexCoords[2]) end,
              set = function(i, value)
                SingularityDB.dynTexCoords[2] = value
                Singularity.loadSettings()
              end,
            },
            dynamicIconCoordTop = {
              name = "Top",
              type = "input",
              get = function() return tostring(SingularityDB.dynTexCoords[3]) end,
              set = function(i, value)
                SingularityDB.dynTexCoords[3] = value
                Singularity.loadSettings()
              end,
            },
            dynamicIconCoordBottom = {
              name = "Bottom",
              type = "input",
              get = function() return tostring(SingularityDB.dynTexCoords[4]) end,
              set = function(i, value)
                SingularityDB.dynTexCoords[4] = value
                Singularity.loadSettings()
              end,
            },
          },
        },
      },
    },
  },
}

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

LibStub("AceConfig-3.0"):RegisterOptionsTable("Singularity", options, nil)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Singularity")

SLASH_SINGULARITY1, SLASH_SINGULARITY2 = "/singularity", "/sng"
function SlashCmdList.SINGULARITY()
  InterfaceOptionsFrame_OpenToCategory("Singularity")
end