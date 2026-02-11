print("Crosshair_Scream.lua LOADED")

local ADDON = ...
local f = CreateFrame("Frame")

local DEFAULTS = {
  enabled = true,
  combatOnly = true,
  size = 64,
  thickness = 3,
  length = 50,
  alpha = 0.9,
  strata = "TOOLTIP",
  level = 9999,
  color = {1, 1, 1},
  pos = {0, 0}, -- offset x,y
}

local crosshair, h, v, dot

local function CopyDefaults(dst, src)
  for k, val in pairs(src) do
    if type(val) == "table" then
      dst[k] = dst[k] or {}
      CopyDefaults(dst[k], val)
    elseif dst[k] == nil then
      dst[k] = val
    end
  end
end

local function CreateCrosshair()
  crosshair = CreateFrame("Frame", nil, UIParent)
  crosshair:Hide()

  h = crosshair:CreateTexture(nil, "OVERLAY")
  v = crosshair:CreateTexture(nil, "OVERLAY")
  dot = crosshair:CreateTexture(nil, "OVERLAY")
end

local function ApplySettings()
  local db = CrosshairScreamDB
  if not crosshair or not db then return end

  crosshair:ClearAllPoints()
  crosshair:SetPoint("CENTER", UIParent, "CENTER", db.pos[1], db.pos[2])
  crosshair:SetSize(db.size, db.size)
  crosshair:SetFrameStrata(db.strata)
  crosshair:SetFrameLevel(db.level)

  h:SetPoint("CENTER")
  h:SetSize(db.length, db.thickness)
  h:SetColorTexture(db.color[1], db.color[2], db.color[3], db.alpha)

  v:SetPoint("CENTER")
  v:SetSize(db.thickness, db.length)
  v:SetColorTexture(db.color[1], db.color[2], db.color[3], db.alpha)

  dot:SetPoint("CENTER")
  dot:SetSize(db.thickness, db.thickness)
  dot:SetColorTexture(1, 0, 0, 1)
end

local function InCombat()
  return InCombatLockdown() or UnitAffectingCombat("player")
end

local function ApplyVisibility()
  local db = CrosshairScreamDB
  if not crosshair or not db then return end
  if not db.enabled then crosshair:Hide(); return end
  if db.combatOnly and not InCombat() then crosshair:Hide(); return end
  crosshair:Show()
end

-- API für UI-Datei:
_G.CrosshairScream = _G.CrosshairScream or {}
_G.CrosshairScream.GetDB = function() return CrosshairScreamDB end
_G.CrosshairScream.Apply = function()
  ApplySettings()
  ApplyVisibility()
end
_G.CrosshairScream.SetPos = function(x, y)
  CrosshairScreamDB.pos[1] = x
  CrosshairScreamDB.pos[2] = y
  _G.CrosshairScream.Apply()
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    CrosshairScreamDB = CrosshairScreamDB or {}
    CopyDefaults(CrosshairScreamDB, DEFAULTS)
    CreateCrosshair()
    ApplySettings()
    ApplyVisibility()
    return
  end
  ApplyVisibility()
end)
