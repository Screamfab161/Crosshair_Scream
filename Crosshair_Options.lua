-- Crosshair_Options.lua

local ui

local function Apply()
  if _G.CrosshairScream and _G.CrosshairScream.Apply then
    _G.CrosshairScream.Apply()
  end
end

local function GetDB()
  return _G.CrosshairScream and _G.CrosshairScream.GetDB and _G.CrosshairScream.GetDB() or nil
end

local function MakeCheckbox(parent, text, x, y, get, set)
  local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  c:SetPoint("TOPLEFT", x, y)
  c.Text:SetText(text)

  c:SetScript("OnShow", function() c:SetChecked(get()) end)
  c:SetScript("OnClick", function()
    set(c:GetChecked() and true or false)
    Apply()
  end)

  return c
end

local function MakeSlider(parent, name, x, y, minV, maxV, step, get, set, fmt)
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

  local function setValText(v)
    if fmt then val:SetText(string.format(fmt, v))
    else val:SetText(string.format("%.0f", v)) end
  end

  s:SetScript("OnShow", function()
    local v = get()
    s:SetValue(v)
    setValText(v)
  end)

  s:SetScript("OnValueChanged", function(_, v)
    set(v)
    setValText(v)
    Apply()
  end)

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
  ColorPickerFrame.previousValues = { pr, pg, pb }
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

local function EnsureUI()
  if ui then return end

  ui = CreateFrame("Frame", "CrosshairScreamConfigUI", UIParent, "BackdropTemplate")
  ui:SetSize(420, 300)
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

  ui:SetScript("OnDragStart", function() ui:StartMoving() end)
  ui:SetScript("OnDragStop", function() ui:StopMovingOrSizing() end)

  local title = ui:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Crosshair Config")

  local hint = ui:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", 16, -44)
  hint:SetText("Open with /xhair. While open, crosshair is shown out of combat.")

  -- Toggles
  MakeCheckbox(ui, "Enabled", 16, -72,
    function() return GetDB().enabled end,
    function(v) GetDB().enabled = v end
  )

  MakeCheckbox(ui, "Combat only", 120, -72,
    function() return GetDB().combatOnly end,
    function(v) GetDB().combatOnly = v end
  )

  -- Sliders left
  MakeSlider(ui, "Length", 16, -120, 10, 200, 1,
    function() return GetDB().length end,
    function(v) GetDB().length = math.floor(v + 0.5) end
  )

  MakeSlider(ui, "Thickness", 16, -170, 1, 20, 1,
    function() return GetDB().thickness end,
    function(v) GetDB().thickness = math.floor(v + 0.5) end
  )

  MakeSlider(ui, "Alpha", 16, -220, 0.1, 1.0, 0.05,
    function() return GetDB().alpha end,
    function(v) GetDB().alpha = math.floor(v * 100 + 0.5) / 100 end,
    "%.2f"
  )

  -- Sliders right: X/Y
  MakeSlider(ui, "X Offset", 230, -120, -500, 500, 1,
    function() return (GetDB().pos and GetDB().pos[1]) or 0 end,
    function(v)
      local db = GetDB()
      db.pos = db.pos or {0, 0}
      db.pos[1] = math.floor(v + 0.5)
    end
  )

  MakeSlider(ui, "Y Offset", 230, -170, -500, 500, 1,
    function() return (GetDB().pos and GetDB().pos[2]) or 0 end,
    function(v)
      local db = GetDB()
      db.pos = db.pos or {0, 0}
      db.pos[2] = math.floor(v + 0.5)
    end
  )

  -- Colors
  MakeButton(ui, "Line Color", 250, 80, 150, 24, function()
    OpenColorPicker(function()
      local c = GetDB().color or {1, 1, 1}
      return c[1], c[2], c[3]
    end, function(r, g, b)
      GetDB().color = {r, g, b}
    end)
  end)

  MakeButton(ui, "Dot Color", 250, 50, 150, 24, function()
    OpenColorPicker(function()
      local c = GetDB().dotColor or {1, 0, 0}
      return c[1], c[2], c[3]
    end, function(r, g, b)
      GetDB().dotColor = {r, g, b}
    end)
  end)

  -- Bottom buttons
  MakeButton(ui, "Center X", 16, 16, 90, 24, function()
    local db = GetDB()
    db.pos = db.pos or {0, 0}
    db.pos[1] = 0
    Apply()
  end)

  MakeButton(ui, "Reset All", 112, 16, 90, 24, function()
    local db = GetDB()
    db.enabled = true
    db.combatOnly = true
    db.length = 50
    db.thickness = 3
    db.alpha = 0.9
    db.color = {1, 1, 1}
    db.dotColor = {1, 0, 0}
    db.pos = {0, 0}
    Apply()
  end)

  MakeButton(ui, "Close", 320, 16, 70, 24, function() ui:Hide() end)

  -- Preview: zeigen solange UI offen ist (ohne db.combatOnly zu ändern)
  ui:SetScript("OnShow", function()
    local db = GetDB()
    db.pos = db.pos or {0, 0}
    db.dotColor = db.dotColor or {1, 0, 0}
    db.color = db.color or {1, 1, 1}

    if _G.CrosshairScream and _G.CrosshairScream.SetConfigOpen then
      _G.CrosshairScream.SetConfigOpen(true)
    end
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
