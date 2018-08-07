---------------------------------------------------------------------
-- General minimap positioning and behavior
---------------------------------------------------------------------

local _, ns = ...
local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)

local FONT = LSM:Fetch(LSM.MediaType.FONT, "Roboto Bold Condensed")
local TEXTURE = LSM:Fetch(LSM.MediaType.STATUSBAR, "Flat")

local DEFAULT_SIZE = 280
local DEFAULT_BUTTON_POSITION = "Bottom"


-- Override some defaults
Minimap:EnableMouse(true)
Minimap:SetMaskTexture("Interface\\Addons\\klnMinimap\\rectangle.tga")
Minimap:SetArchBlobRingScalar(0);
Minimap:SetQuestBlobRingScalar(0);
Minimap:ClearAllPoints()
Minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, 0)

-- Attempt to prevent minimap shape overrides from elsewhere
function GetMinimapShape() return "SQUARE" end

Minimap:RegisterEvent("ADDON_LOADED")
Minimap:RegisterEvent("PLAYER_ENTERING_WORLD")
Minimap:RegisterEvent("LOADING_SCREEN_DISABLED")
Minimap:HookScript("OnEvent", function()
  function GetMinimapShape() return "SQUARE" end
  return
end)

-- Coordinates (nod to xcoords)
local klnCoords = CreateFrame("frame", nil, WorldMapFrame)
klnCoords.text = klnCoords:CreateFontString(nil, "OVERLAY")
klnCoords.text:SetFont(FONT, 16)
klnCoords.text:SetAllPoints()
klnCoords.text:SetJustifyH("CENTER")
klnCoords:SetPoint("BOTTOM", WorldMapFrame, "BOTTOM")
klnCoords:SetFrameStrata("TOOLTIP")
klnCoords:SetSize(300, 40)

-- Override general minimap positioning
function Minimap:Update()
  -- Configuration values are currently fixed. User overrides
  -- may be allowed eventually.
  local shape   = "Rectangle"
  local size    = DEFAULT_SIZE
  local buttons = DEFAULT_BUTTON_POSITION

  if shape == "Rectangle" then
    Minimap:SetMaskTexture("Interface\\Addons\\klnMinimap\\rectangle.tga")
    Minimap.background:SetSize(size, size * .75)
    Minimap:SetSize(size, size)
    Minimap:SetHitRectInsets(0, 0, size / 8, size / 8)
    Minimap:SetClampRectInsets(0, 0, -size / 4, size / 4)
  else
    Minimap:SetMaskTexture(TEXTURE)
    Minimap.background:SetSize(size, size)
    Minimap:SetSize(size, size)
    Minimap:SetHitRectInsets(0, 0, 0, 0)
    Minimap:SetClampRectInsets(0, 0, 0, 0)
  end

  if (buttons == "Disable") then
    Minimap.buttonFrame:ClearAllPoints()
    Minimap.buttonFrame:Hide()
  else 
    Minimap.buttonFrame:ClearAllPoints()

    if (buttons == "Top") then
      Minimap.buttonFrame:SetPoint("BOTTOMLEFT", Minimap.background, "TOPLEFT", 2, 4)
      Minimap.buttonFrame:SetPoint("TOPRIGHT", Minimap.background, "TOPRIGHT", -2, 28)
    elseif (buttons == "Right") then
      Minimap.buttonFrame:SetPoint("TOPLEFT", Minimap.background, "TOPRIGHT", 4, -2)
      Minimap.buttonFrame:SetPoint("BOTTOMRIGHT", Minimap.background, "BOTTOMRIGHT", 28, 2)
    elseif (buttons == "Bottom") then
      Minimap.buttonFrame:SetPoint("TOPLEFT", Minimap.background, "BOTTOMLEFT", 2, -4)
      Minimap.buttonFrame:SetPoint("BOTTOMRIGHT", Minimap.background, "BOTTOMRIGHT", -2, -28)
      
      if klnXP and klnXP:IsShown() then
        Minimap.buttonFrame:SetPoint("TOPLEFT", klnXP, "BOTTOMLEFT", 0, -6)
        Minimap.buttonFrame:SetPoint("BOTTOMRIGHT", klnXP, "BOTTOMRIGHT", 0, -30)
      end
    elseif (buttons == "Left") then
      Minimap.buttonFrame:SetPoint("TOPRIGHT", Minimap.background, "TOPLEFT", -4, -2)
      Minimap.buttonFrame:SetPoint("BOTTOMLEFT", Minimap.background, "BOTTOMLEFT", -28, 2)
    end
  end
end
klnCore.events:Trigger("reconfigure", function() Minimap:Update() end)
klnCore.events:Trigger("minimap_reconfigure", function() Minimap:Update() end)


-- Finally, update the minimap
Minimap:Update()
