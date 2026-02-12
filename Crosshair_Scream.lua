local ADDON = ...
local f = CreateFrame("Frame")

local configOpen = false -- Preview: wenn true => out of combat sichtbar

local DEFAULTS = {
  enabled   = true,
  combatOnly = true,
  thickness = 3,
  length    = 50,
  alpha     = 0.9,
  color     = {1, 1, 1},
  dotColor  = {1, 0, 0},
  pos       = {0, 0},
  lockPos   = true,   -- NEU: Position lock
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
  crosshair:SetPoint("CENTER")
  crosshair:SetFrameStrata("MEDIUM")
  crosshair:SetFrameLevel(50)
  crosshair:Hide()

  h   = crosshair:CreateTexture(nil, "OVERLAY")
  v   = crosshair:CreateTexture(nil, "OVERLAY")
  dot = crosshair:CreateTexture(nil, "OVERLAY")
end

local function ApplySettings()
  local db = CrosshairScreamDB
  if not crosshair or not db then return end

  crosshair:ClearAllPoints()
  crosshair:SetPoint("CENTER", UIParent, "CENTER", db.pos[1], db.pos[2])

  -- Damit das Frame “greifbar” ist und immer eine sinnvolle Fläche hat:
  local s = math.max(db.length, db.thickness) + 12
  crosshair:SetSize(s, s)

  h:SetPoint("CENTER")
  h:SetSize(db.length, db.thickness)

  v:SetPoint("CENTER")
  v:SetSize(db.thickness, db.length)

  dot:SetPoint("CENTER")
  dot:SetSize(db.thickness, db.thickness)

  local lc = db.color or {1, 1, 1}
  h:SetColorTexture(lc[1], lc[2], lc[3], db.alpha)
  v:SetColorTexture(lc[1], lc[2], lc[3], db.alpha)

  local dc = db.dotColor or {1, 0, 0}
  dot:SetColorTexture(dc[1], dc[2], dc[3], 1)
end

local function InCombat()
  return InCombatLockdown() or UnitAffectingCombat("player")
end

local function ApplyVisibility()
  local db = CrosshairScreamDB
  if not crosshair or not db then return end

  -- Preview: nur combatOnly ignorieren, aber "enabled" respektieren
  if configOpen then
    if db.enabled then crosshair:Show() else crosshair:Hide() end
    return
  end

  if not db.enabled then crosshair:Hide(); return end
  if db.combatOnly and not InCombat() then crosshair:Hide(); return end
  crosshair:Show()
end

-- API für Options-UI
_G.CrosshairScream = _G.CrosshairScream or {}
_G.CrosshairScream.GetDB = function() return CrosshairScreamDB end
_G.CrosshairScream.Apply = function()
  ApplySettings()
  ApplyVisibility()
end
_G.CrosshairScream.SetConfigOpen = function(open)
  configOpen = open and true or false
  ApplyVisibility()
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

  -- nur Sichtbarkeit prüfen (cheap)
  ApplyVisibility()
end)
