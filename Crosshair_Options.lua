-- Crosshair_Options.lua
local ui

local cbEnabled, cbCombat, cbLock
local slLength, slThickness, slAlpha, slX, slY
local nudgeBtns = {}

local function Apply()
  if _G.CrosshairScream and _G.CrosshairScream.Apply then
    _G.CrosshairScream.Apply()
  end
end

local function GetDB()
  return _G.CrosshairScream and _G.CrosshairScream.GetDB and _G.CrosshairScream.GetDB() or nil
end

local function MakeCheckbox(parent, text, x, y, onClick)
  local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  c:SetPoint("TOPLEFT", x, y)
  c.Text:SetText(text)
  c:SetScript("OnClick", onClick)
  return c
end

local function MakeSlider(parent, name, x, y, minV, maxV, step, fmt)
  local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", x, y)
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step)
  s:SetObeyStepOnDrag(true)

  s.Text:SetText(name)
  s.Low:SetText(tostring(minV))
  s.High:SetText(tostring(maxV))

  local val = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  val:SetPoint("TOPLEFT", x + 170, y - 2)

  s._setValText = function(_, v)
    if fmt then val:SetText(string.format(fmt, v))
    else val:SetText(string.format("%.0f", v)) end
  end


  return s
end

local function MakeButton(parent, text, x, y, w, h, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetPoint("BOTTOMLEFT", x, y)
  b:SetSize(w, h)
  b:SetText(text)
  b:SetScript("OnClick", onClick)
  return b
end

local function PickerGetRGB()
  if ColorPickerFrame and ColorPickerFrame.GetColorRGB then
    return ColorPickerFrame:GetColorRGB()
  end
  local cp = ColorPickerFrame and ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker
  if cp and cp.GetColorRGB then
    return cp:GetColorRGB()
  end
  return 1, 1, 1
end

local function OpenColorPicker(getColor, setColor)
  local r, g, b = getColor()
  local pr, pg, pb = r, g, b

  if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
    local info = {
      r = r, g = g, b = b,
      hasOpacity = false,
      swatchFunc = function()
        local nr, ng, nb = PickerGetRGB()
        setColor(nr, ng, nb)
        Apply()
      end,
      cancelFunc = function()
        setColor(pr, pg, pb)
        Apply()
      end,
    }
    ColorPickerFrame:SetupColorPickerAndShow(info)
    return
  end

  ColorPickerFrame.hasOpacity = false
  ColorPickerFrame.func = function()
    local nr, ng, nb = PickerGetRGB()
    setColor(nr, ng, nb)
    Apply()
  end
  ColorPickerFrame.cancelFunc = function()
    setColor(pr, pg, pb)
    Apply()
  end
  if ColorPickerFrame.SetColorRGB then
    ColorPickerFrame:SetColorRGB(r, g, b)
  end
  ColorPickerFrame:Show()
end

local function SetMoveControlsEnabled(enabled)
  -- Slider “deaktivieren”
  slX:EnableMouse(enabled); slX:SetAlpha(enabled and 1 or 0.35)
  slY:EnableMouse(enabled); slY:SetAlpha(enabled and 1 or 0.35)

  for _, b in ipairs(nudgeBtns) do
    b:SetEnabled(enabled)
    b:SetAlpha(enabled and 1 or 0.35)
  end
end

local function RefreshControls()
  local db = GetDB()
  if not db then return end

  ui._refreshing = true

  cbEnabled:SetChecked(db.enabled)
  cbCombat:SetChecked(db.combatOnly)
  cbLock:SetChecked(db.lockPos)

  slLength:SetValue(db.length);        slLength:_setValText(db.length)
  slThickness:SetValue(db.thickness);  slThickness:_setValText(db.thickness)
  slAlpha:SetValue(db.alpha);          slAlpha:_setValText(db.alpha)

  slX:SetValue(db.pos[1]);             slX:_setValText(db.pos[1])
  slY:SetValue(db.pos[2]);             slY:_setValText(db.pos[2])

  SetMoveControlsEnabled(not db.lockPos)

  ui._refreshing = false
end

local function Nudge(dx, dy)
  local db = GetDB(); if not db then return end
  if db.lockPos then return end

  local x = db.pos[1] + dx
  local y = db.pos[2] + dy

  -- gleiche Range wie Slider
  if x < -500 then x = -500 elseif x > 500 then x = 500 end
  if y < -500 then y = -500 elseif y > 500 then y = 500 end

  db.pos[1] = x
  db.pos[2] = y
  Apply()
  RefreshControls()
end

local function EnsureUI()
  if ui then return end

  ui = CreateFrame("Frame", "CrosshairScreamConfigUI", UIParent, "BackdropTemplate")
  ui:SetSize(470, 360)
  ui:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
  ui:SetFrameStrata("DIALOG")
  ui:SetMovable(true)
  ui:EnableMouse(true)
  ui:RegisterForDrag("LeftButton")
  ui:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  ui:Hide()

  ui:SetClampedToScreen(true)
  tinsert(UISpecialFrames, "CrosshairScreamConfigUI")

  ui:SetScript("OnDragStart", function() ui:StartMoving() end)
  ui:SetScript("OnDragStop", function() ui:StopMovingOrSizing() end)

  local title = ui:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Crosshair Config")

  local hint = ui:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", 16, -44)
  hint:SetText("Open with /xhair. While open, crosshair is shown out of combat.")

  -- Toggles
  cbEnabled = MakeCheckbox(ui, "Enabled", 16, -72, function()
    local db = GetDB(); if not db then return end
    db.enabled = cbEnabled:GetChecked() and true or false
    Apply()
  end)

  cbCombat = MakeCheckbox(ui, "Combat only", 120, -72, function()
    local db = GetDB(); if not db then return end
    db.combatOnly = cbCombat:GetChecked() and true or false
    Apply()
  end)

  cbLock = MakeCheckbox(ui, "Lock position", 230, -72, function()
    local db = GetDB(); if not db then return end
    db.lockPos = cbLock:GetChecked() and true or false
    SetMoveControlsEnabled(not db.lockPos)
    Apply()
  end)

  -- Sliders left
  slLength = MakeSlider(ui, "Length", 16, -120, 10, 200, 1)
  slLength:SetScript("OnValueChanged", function(_, v)
    slLength:_setValText(v)
    if ui._refreshing then return end
    local db = GetDB(); if not db then return end
    db.length = math.floor(v + 0.5)
    Apply()
  end)

  slThickness = MakeSlider(ui, "Thickness", 16, -170, 1, 20, 1)
  slThickness:SetScript("OnValueChanged", function(_, v)
    slThickness:_setValText(v)
    if ui._refreshing then return end
    local db = GetDB(); if not db then return end
    db.thickness = math.floor(v + 0.5)
    Apply()
  end)

  slAlpha = MakeSlider(ui, "Alpha", 16, -220, 0.1, 1.0, 0.05, "%.2f")
  slAlpha:SetScript("OnValueChanged", function(_, v)
    slAlpha:_setValText(v)
    if ui._refreshing then return end
    local db = GetDB(); if not db then return end
    db.alpha = math.floor(v * 100 + 0.5) / 100
    Apply()
  end)

  -- Sliders right
  slX = MakeSlider(ui, "X Offset", 230, -120, -500, 500, 1)
  slX:SetScript("OnValueChanged", function(_, v)
    slX:_setValText(v)
    if ui._refreshing then return end
    local db = GetDB(); if not db then return end
    if db.lockPos then return end
    db.pos[1] = math.floor(v + 0.5)
    Apply()
  end)

  slY = MakeSlider(ui, "Y Offset", 230, -200, -500, 500, 1)
  slY:SetScript("OnValueChanged", function(_, v)
    slY:_setValText(v)
    if ui._refreshing then return end
    local db = GetDB(); if not db then return end
    if db.lockPos then return end
    db.pos[2] = math.floor(v + 0.5)
    Apply()
  end)

     -- NUDGE Rows (sauber: eigene Row + genug Abstand zum Slider)
  local function MakeNudgeRow(anchorSlider, axis) -- axis: "x" oder "y"
    local row = CreateFrame("Frame", nil, ui)
    row:SetSize(160, 20)

    -- WICHTIG: deutlich weiter unter den Slider, damit es nicht "reinläuft"
    row:SetPoint("TOP", anchorSlider, "BOTTOM", 0, -14)

    local values = { -5, -1, 1, 5 }
    local prev

    for _, val in ipairs(values) do
      local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
      b:SetSize(36, 20)
      b:SetText(val > 0 and ("+"..val) or tostring(val))

      b:SetScript("OnClick", function()
        if axis == "x" then
          Nudge(val, 0)
        else
          Nudge(0, val)
        end
      end)

      if not prev then
        b:SetPoint("LEFT", row, "LEFT", 0, 0)
      else
        b:SetPoint("LEFT", prev, "RIGHT", 4, 0)
      end

      prev = b
      table.insert(nudgeBtns, b)
    end

    return row
  end

  local nudgeRowX = MakeNudgeRow(slX, "x")
  local nudgeRowY = MakeNudgeRow(slY, "y")



    -- Bottom right row: Close anchored to the right, others chained to it
  local btnClose = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
  btnClose:SetSize(70, 24)
  btnClose:SetText("Close")
  btnClose:SetPoint("BOTTOMRIGHT", ui, "BOTTOMRIGHT", -16, 16)
  btnClose:SetScript("OnClick", function() ui:Hide() end)

  local btnDot = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
  btnDot:SetSize(90, 24)
  btnDot:SetText("Dot Color")
  btnDot:SetPoint("RIGHT", btnClose, "LEFT", -8, 0)
  btnDot:SetScript("OnClick", function()
    local db = GetDB(); if not db then return end
    OpenColorPicker(function()
      local c = db.dotColor or {1, 0, 0}
      return c[1], c[2], c[3]
    end, function(r, g, b)
      db.dotColor = {r, g, b}
    end)
  end)

  local btnLine = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
  btnLine:SetSize(90, 24)
  btnLine:SetText("Line Color")
  btnLine:SetPoint("RIGHT", btnDot, "LEFT", -8, 0)
  btnLine:SetScript("OnClick", function()
    local db = GetDB(); if not db then return end
    OpenColorPicker(function()
      local c = db.color or {1, 1, 1}
      return c[1], c[2], c[3]
    end, function(r, g, b)
      db.color = {r, g, b}
    end)
  end)



  MakeButton(ui, "Reset All", 16, 44, 90, 24, function()
    local db = GetDB(); if not db then return end
    db.enabled = true
    db.combatOnly = true
    db.thickness = 3
    db.length = 50
    db.alpha = 0.9
    db.color = {1, 1, 1}
    db.dotColor = {1, 0, 0}
    db.pos = {0, 0}
    db.lockPos = true
    Apply()
    RefreshControls()
  end)

  btnCenterX = MakeButton(ui, "Center X", 16, 16, 90, 24, function()
    local db = GetDB(); if not db then return end
    if db.lockPos then return end
    db.pos[1] = 0
    Apply()
    RefreshControls()
  end)

  
  -- Preview an/aus + refresh
  ui:SetScript("OnShow", function()
    local db = GetDB()
    if not db then return end

    db.pos = db.pos or {0, 0}
    db.color = db.color or {1, 1, 1}
    db.dotColor = db.dotColor or {1, 0, 0}
    if db.lockPos == nil then db.lockPos = true end

    if _G.CrosshairScream and _G.CrosshairScream.SetConfigOpen then
      _G.CrosshairScream.SetConfigOpen(true)
    end

    RefreshControls()
    Apply()
  end)

  ui:SetScript("OnHide", function()
    if _G.CrosshairScream and _G.CrosshairScream.SetConfigOpen then
      _G.CrosshairScream.SetConfigOpen(false)
    end
    Apply()
  end)
end

SLASH_XHAIR1 = "/xhair"
SlashCmdList["XHAIR"] = function()
  EnsureUI()
  if ui:IsShown() then ui:Hide() else ui:Show() end
end
