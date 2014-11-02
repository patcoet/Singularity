local options = {
  type = "group",
  args = {
    desaturateSWD = {
      name = "Desaturate Shadow Word: Death",
      desc = "Desaturates the Shadow Word: Death icon when your target is above 20% HP",
      type = "toggle",
      get = function() return SingularityDB.desaturateSWD end,
      set = function() SingularityDB.desaturateSWD = not SingularityDB.desaturateSWD end,
    },
    checkRange = {
      name = "Enable range display",
      desc = "Show the approximate range to your target",
      type = "toggle",
      get = function() return SingularityDB.checkRange end,
      set = function() SingularityDB.checkRange = not SingularityDB.checkRange end,
    },
    barColor = {
      name = "Bar container backdrop color",
      type = "group",
      args = {
        r = {
          name = "Red",
          type = "input",
          get = function() return "" .. SingularityDB.targetContainer.backdrop.color.r end,
          set = function(info, val) SingularityDB.targetContainer.backdrop.color.r = val Singularity_reloadBars() end,
        },
        g = {
          name = "Green",
          type = "input",
          get = function() return "" .. SingularityDB.targetContainer.backdrop.color.g end,
          set = function(info, val) SingularityDB.targetContainer.backdrop.color.g = val end,
        },
        b = {
          name = "Blue",
          type = "input",
          get = function() return "" .. SingularityDB.targetContainer.backdrop.color.b end,
          set = function(info, val) SingularityDB.targetContainer.backdrop.color.b = val end,
        },
        a = {
          name = "Alpha",
          type = "input",
          get = function() return "" .. SingularityDB.targetContainer.backdrop.color.a end,
          set = function(info, val) SingularityDB.targetContainer.backdrop.color.a = val end,
        },
      },
    },
  },
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Singularity", options, nil)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Singularity")