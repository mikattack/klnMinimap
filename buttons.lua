---------------------------------------------------------------------
-- Manage collection and display of minimap buttons
---------------------------------------------------------------------

local _, ns = ...
local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)

local FONT = LSM:Fetch(LSM.MediaType.FONT, "Roboto Bold Condensed")
local TEXTURE = LSM:Fetch(LSM.MediaType.STATUSBAR, "Flat")

local DEFAULT_BUTTON_SIZE = 24
local DEFAULT_BUTTON_POSITION = "Bottom"
local DEFAULT_MOUSEOVER_BUTTON_FRAME = true


-- Add a border to the minimap.
-- This is done early so that frames may be positioned against it.
Minimap.background = CreateFrame("frame", "klnMinimap", UIParent)
Minimap.background:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
Minimap.background:SetBackdrop({
  bgFile   = TEXTURE,
  edgeFile = TEXTURE,
  edgeSize = 2,
})
Minimap.background:SetBackdropColor(0,0,0,0)
Minimap.background:SetBackdropBorderColor(0,0,0,1)


-- Target existing frames/textures for manipulation
local ignoredFrames = {}
local hideTextures  = {}
local manualTarget  = {}

manualTarget['MiniMapMailFrame'] = true

ignoredFrames['MinimapBackdrop'] = true
ignoredFrames['GameTimeFrame'] = true
ignoredFrames['MinimapVoiceChatFrame'] = true
ignoredFrames['TimeManagerClockButton'] = true

hideTextures['Interface\\Minimap\\MiniMap-TrackingBorder'] = true
hideTextures['Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight'] = true
hideTextures['Interface\\Minimap\\UI-Minimap-Background'] = true


-- Create a frame for storing minimap buttons
Minimap.buttonFrame = CreateFrame("frame", nil, Minimap)
Minimap.buttonFrame:SetHeight(DEFAULT_BUTTON_SIZE + 10)
Minimap.buttonFrame:SetPoint("TOPLEFT", Minimap.background, "BOTTOMLEFT", 2, -4)
Minimap.buttonFrame:SetPoint("BOTTOMRIGHT", Minimap.background, "BOTTOMRIGHT", 0, -28)
Minimap.buttonFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
Minimap.buttonFrame:RegisterEvent("GARRISON_UPDATE")
Minimap.buttonFrame:RegisterEvent("PLAYER_XP_UPDATE")
Minimap.buttonFrame:RegisterEvent("PLAYER_LEVEL_UP")
Minimap.buttonFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
Minimap.buttonFrame:RegisterEvent("UPDATE_FACTION")


-- Create a minimap button for kln-related configuration
local klnConfigButton = CreateFrame("button","klnCore_config_button", Minimap.buttonFrame)
klnConfigButton.text = klnConfigButton:CreateFontString(nil, "OVERLAY")
klnConfigButton.text:SetFont(FONT, 14)
klnConfigButton.text:SetTextColor(.4, .6, 1)
klnConfigButton.text:SetText("kln")
klnConfigButton.text:SetJustifyH("CENTER")
klnConfigButton.text:SetPoint("CENTER", klnConfigButton, "CENTER", 1, -1)
klnConfigButton:SetScript("OnEnter", function(self) 
  self.text:SetTextColor(.6,.8,1) 
  ShowUIPanel(GameTooltip)
  GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 6)
  GameTooltip:AddLine("KLN Configuration (eventually)")
  GameTooltip:Show()
end)
klnConfigButton:SetScript("OnLeave", function(self) 
  self.text:SetTextColor(.4, .6, 1) 
  GameTooltip:Hide()
end)
klnConfigButton:SetScript("OnClick", function()
  kln.events:Trigger("show_configuration")
end)


-- Show/hide button container on mouseover
local function MinimapMouseover()
  local mouseoverButtonFrame = DEFAULT_MOUSEOVER_BUTTON_FRAME
  if not mouseoverButtonFrame then
    Minimap.buttonFrame:Show();
    return true
  end

  local over = false
  if Minimap:IsMouseOver() then over = true end
  if Minimap.background:IsMouseOver() then over = true end
  if Minimap.buttonFrame:IsMouseOver() then over = true end
  if klnXP and klnXP:IsMouseOver() then over = true end
  if klnAP and klnAP:IsMouseOver() then over = true end
  
  if (over) then 
    Minimap.buttonFrame:Show()
  else
    Minimap.buttonFrame:Hide()
  end
  
  return over
end

-- Begin polling for mouseover
local mtotal = 0
Minimap:HookScript("OnUpdate",function(self, elapsed)
  mtotal = mtotal + elapsed
  if mtotal > .05 then
    mtotal = 0;
    MinimapMouseover()
  end
end)


-- Collect minimap buttons and place them into a frame
local function collectMinimapButtons()
  if (InCombatLockdown()) then return end

  local buttons = DEFAULT_BUTTON_POSITION
  if buttons == "Disable" then return end

  -- Stick our "button that does nothing for now" into the collection
  ignoredFrames["klnCore_config_button"] = nil
  klnConfigButton:Show()
  
  local c = {Minimap.buttonFrame:GetChildren()}
  local d = {Minimap:GetChildren()}

  for _, v in pairs(d) do table.insert(c,v) end
  table.insert(c, _G["DugisOnOffButton"])  -- Yay special case

  local button_size = DEFAULT_BUTTON_SIZE

  local last = nil
  for i = 1, #c do
    local f = c[i]
    local n = f:GetName() or "";
    local lc = string.lower(n)

    if (manualTarget[n] and f:IsShown()) or (
      f:GetName() and 
      f:IsShown() and 
      (strfind(lc, "libdb") or strfind(lc, "button") or strfind(lc, "btn")) and 
      not ignoredFrames[n]
    ) then
      if not f.skinned then
        f:SetSize(button_size, button_size)
        f:SetParent(Minimap.buttonFrame)

        local r = {f:GetRegions()}
        for o = 1, #r do
          if r[o].GetTexture and r[o]:GetTexture() then
            local tex = r[o]:GetTexture()
            r[o]:SetAllPoints(f)
            if hideTextures[tex] then
              r[o]:Hide()
            elseif not strfind(tex,"WHITE8x8") then
              local coord = table.concat({r[o]:GetTexCoord()})
              if (coord == "00011011") then
                r[o]:SetTexCoord(0.3, 0.7, 0.3, 0.7)
                if (n == "DugisOnOffButton") then
                  r[o]:SetTexCoord(0.25, 0.75, 0.2, 0.7)                
                end
              end
            end
          end
        end
        
        f.klnBackground = f.klnBackground or CreateFrame("frame",nil,f)
        f.klnBackground:SetAllPoints(f)
        f.klnBackground:SetFrameStrata("BACKGROUND")
        klnCore.frames.setBackdrop(f.klnBackground)
        f:SetHitRectInsets(0, 0, 0, 0)

        local oldscript = 
        f:HookScript("OnEnter",function(self)
          local newlines = {}
          for l = 1, 10 do
            local line = _G["GameTooltipTextLeft"..l]
            if line and line:GetText() then
              newlines[line:GetText()] = true
            end
          end
          
          GameTooltip:Hide()
          GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 6)
          for k, v in pairs(newlines) do
            GameTooltip:AddLine(k)
          end
          GameTooltip:Show()
        end)

        f.skinned = true
      end

      f:ClearAllPoints()
      if buttons == "Top" or buttons == "Bottom" then
        if last then
          f:SetPoint("LEFT", last, "RIGHT", 6, 0)   
        else
          f:SetPoint("TOPLEFT", Minimap.buttonFrame, "TOPLEFT", 0, 0)
        end
      end
      if (buttons == "Right" or buttons == "Left") then
        if (last) then
          f:SetPoint("TOP", last, "BOTTOM", 0, -6)    
        else
          f:SetPoint("TOPLEFT", Minimap.buttonFrame, "TOPLEFT", 0, 0)
        end
      end

      last = f
    end
  end
end

-- Begin polling for minimap button collection
local ctotal = 0
Minimap.buttonFrame:SetScript("OnEvent",moveMinimapButtons)
Minimap.buttonFrame:SetScript("OnUpdate",function(self,elapsed)
  ctotal = ctotal + elapsed
  if ctotal > .5 then
    ctotal = 0
    if not InCombatLockdown() then
      collectMinimapButtons()
    end
  end
end)
