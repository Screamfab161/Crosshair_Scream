-- FabCrosshair.lua
-- Ziel: 0 Performance-Last: Frame + Texturen 1x erstellen, im Combat nur Show/Hide.

local f = CreateFrame("Frame")
local crosshair

local function CreateCrosshair()
  crosshair = CreateFrame("Frame", nil, UIParent)
  crosshair:SetSize(32, 32)
  crosshair:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  crosshair:Hide()

  local thickness = 2
  local length = 24
  local alpha = 0.9

  local function makeLine(w, h)
    local t = crosshair:CreateTexture(nil, "OVERLAY")
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetVertexColor(1, 1, 1, alpha)
    t:SetSize(w, h)
    t:SetPoint("CENTER")
    return t
  end

  makeLine(length, thickness)  -- horizontal
  makeLine(thickness, length)  -- vertical

  local dot = crosshair:CreateTexture(nil, "OVERLAY")
  dot:SetTexture("Interface\\Buttons\\WHITE8X8")
  dot:SetVertexColor(1, 1, 1, 1)
  dot:SetSize(thickness, thickness)
  dot:SetPoint("CENTER")
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_DISABLED") -- combat start
f:RegisterEvent("PLAYER_REGEN_ENABLED")  -- combat end

f:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    CreateCrosshair()
    return
  end

  if not crosshair then return end

  if event == "PLAYER_REGEN_DISABLED" then
    crosshair:Show()
  elseif event == "PLAYER_REGEN_ENABLED" then
    crosshair:Hide()
  end
end)
