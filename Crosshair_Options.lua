UIErrorsFrame:AddMessage("OPTIONS FILE LOADED", 0, 1, 0, 1)

print("Crosshair_Options.lua LOADED")

local ui
local function EnsureUI()
  if ui then return end

  ui = CreateFrame("Frame", "CrosshairScreamConfigUI", UIParent, "BackdropTemplate")
  ui:SetSize(260, 140)
  ui:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
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

  local title = ui:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Crosshair Config")

  local hint = ui:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", 16, -44)
  hint:SetText("Drag: move crosshair\nMousewheel: size")

  local btnCombat = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
  btnCombat:SetSize(110, 24)
  btnCombat:SetPoint("BOTTOMLEFT", 16, 16)
  btnCombat:SetText("Combat Only")

  local btnReset = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
  btnReset:SetSize(110, 24)
  btnReset:SetPoint("BOTTOMRIGHT", -16, 16)
  btnReset:SetText("Reset")

  local function RefreshButton()
    local db = _G.CrosshairScream.GetDB()
    btnCombat:SetText(db.combatOnly and "Combat: ON" or "Combat: OFF")
  end

  -- Drag bewegt das Crosshair (nicht das Fenster)
  ui:SetScript("OnDragStart", function()
    ui:StartMoving()
  end)

  ui:SetScript("OnDragStop", function()
    ui:StopMovingOrSizing()
  end)

  -- Crosshair drag via mouse over window: left click + drag
  ui:SetScript("OnMouseDown", function(_, button)
    if button ~= "LeftButton" then return end
    ui._dragging = true
    ui._startX, ui._startY = GetCursorPosition()
    local db = _G.CrosshairScream.GetDB()
    ui._baseX, ui._baseY = db.pos[1], db.pos[2]
  end)

  ui:SetScript("OnMouseUp", function(_, button)
    if button ~= "LeftButton" then return end
    ui._dragging = false
  end)

  ui:SetScript("OnUpdate", function()
    if not ui._dragging then return end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local dx = (x - ui._startX) / scale
    local dy = (y - ui._startY) / scale
    _G.CrosshairScream.SetPos(math.floor(ui._baseX + dx + 0.5), math.floor(ui._baseY + dy + 0.5))
  end)

  -- Mausrad = Size ändern
  ui:EnableMouseWheel(true)
  ui:SetScript("OnMouseWheel", function(_, delta)
    local db = _G.CrosshairScream.GetDB()
    db.size = math.max(16, math.min(200, db.size + (delta * 2)))
    _G.CrosshairScream.Apply()
  end)

  btnCombat:SetScript("OnClick", function()
    local db = _G.CrosshairScream.GetDB()
    db.combatOnly = not db.combatOnly
    _G.CrosshairScream.Apply()
    RefreshButton()
  end)

  btnReset:SetScript("OnClick", function()
    local db = _G.CrosshairScream.GetDB()
    db.pos[1], db.pos[2] = 0, 0
    db.size = 64
    db.length = 50
    db.thickness = 3
    db.alpha = 0.9
    db.color = {1, 1, 1}
    _G.CrosshairScream.Apply()
    RefreshButton()
  end)

  ui:SetScript("OnShow", function()
    RefreshButton()
    -- beim Öffnen Crosshair sichtbar machen, damit du was siehst:
    local db = _G.CrosshairScream.GetDB()
    db.enabled = true
    db.combatOnly = false
    _G.CrosshairScream.Apply()
  end)
end

SLASH_XHAIR1 = "/xhair"
SlashCmdList["XHAIR"] = function()
  EnsureUI()
  if ui:IsShown() then
    ui:Hide()
    -- zurück zu combatOnly (optional)
    local db = _G.CrosshairScream.GetDB()
    db.combatOnly = true
    _G.CrosshairScream.Apply()
  else
    ui:Show()
  end
end
