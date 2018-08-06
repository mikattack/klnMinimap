---------------------------------------------------------------------
-- Overrides to Blizzard's minimap behavior
---------------------------------------------------------------------

local _, ns = ...
local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
local FONT = LSM:Fetch(LSM.MediaType.FONT, "Roboto Bold Condensed")

local DEFAULT_SIZE = 280
local DEFAULT_BUTTON_SIZE = 24


-- Raid difficulty
local rd = CreateFrame("Frame", nil, Minimap)
rd:SetSize(24, 8)

local rdt = rd:CreateFontString(nil, "OVERLAY")
rdt:SetPoint("BOTTOMRIGHT", Minimap.background, "BOTTOMRIGHT", -4, 6)
rdt:SetFont(FONT, 14, "OUTLINE")
rdt:SetJustifyH("RIGHT")
rdt:SetTextColor(.7,.7,.7)

rd:RegisterEvent("PLAYER_ENTERING_WORLD")
rd:RegisterEvent("CHALLENGE_MODE_START")
rd:RegisterEvent("CHALLENGE_MODE_COMPLETED")
rd:RegisterEvent("CHALLENGE_MODE_RESET")
rd:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
rd:RegisterEvent("GUILD_PARTY_STATE_UPDATED")
rd:RegisterEvent("ZONE_CHANGED_NEW_AREA")
rd:SetScript("OnEvent", function()
  local difficulty = select(3, GetInstanceInfo())
  local numplayers = select(9, GetInstanceInfo())
  local mplusdiff = select(1, C_ChallengeMode.GetActiveKeystoneInfo()) or "";

  if (difficulty == 1) then
    rdt:SetText("5")
  elseif difficulty == 2 then
    rdt:SetText("5H")
  elseif difficulty == 3 then
    rdt:SetText("10")
  elseif difficulty == 4 then
    rdt:SetText("25")
  elseif difficulty == 5 then
    rdt:SetText("10H")
  elseif difficulty == 6 then
    rdt:SetText("25H")
  elseif difficulty == 7 then
    rdt:SetText("LFR")
  elseif difficulty == 8 then
    rdt:SetText("M+"..mplusdiff)
  elseif difficulty == 9 then
    rdt:SetText("40")
  elseif difficulty == 11 then
    rdt:SetText("HScen")
  elseif difficulty == 12 then
    rdt:SetText("Scen")
  elseif difficulty == 14 then
    rdt:SetText("N:"..numplayers)
  elseif difficulty == 15 then
    rdt:SetText("H:"..numplayers)
  elseif difficulty == 16 then
    rdt:SetText("M")
  elseif difficulty == 17 then
    rdt:SetText("LFR:"..numplayers)
  elseif difficulty == 23 then
    rdt:SetText("M+")
  elseif difficulty == 24 then
    rdt:SetText("TW")
  else
    rdt:SetText("")
  end
end)

MinimapCluster:EnableMouse(false)
MiniMapInstanceDifficulty:ClearAllPoints()
MiniMapInstanceDifficulty:SetPoint("TOPRIGHT", Minimap.background, "TOPRIGHT", -2, -2)


-- Reparent and hide some buttons
GarrisonLandingPageMinimapButton:SetParent(Minimap)
QueueStatusMinimapButton:SetParent(Minimap)

local noShow = function() end
local frames = {
  "MiniMapVoiceChatFrame", -- Gone in BFA
  "MiniMapWorldMapButton",
  "MinimapZoneTextButton",
  "MiniMapMailBorder",
  "MiniMapInstanceDifficulty",
  "MinimapNorthTag",
  "MinimapZoomOut",
  "MinimapZoomIn",
  "MinimapBackdrop",
  "GameTimeFrame",
  "GuildInstanceDifficulty",
  "MiniMapChallengeMode",
  "MinimapBorderTop",
  "MinimapBorder",
  "MiniMapTracking",
}
for i = 1, #frames do
  if _G[frames[i]] then
    _G[frames[i]]:Hide()
    _G[frames[i]].Show = noShow
  else
    --print(frames[i])
  end
end


-- Handle mail
local mailupdate = CreateFrame("frame")
mailupdate:RegisterEvent("MAIL_CLOSED")
mailupdate:RegisterEvent("MAIL_INBOX_UPDATE")
mailupdate:SetScript("OnEvent", function(self, event)
  if (event == "MAIL_CLOSED") then
    CheckInbox();
  else
    InboxFrame_Update()
    OpenMail_Update()
  end
end)

MiniMapMailIcon:SetTexture(nil)

MiniMapMailFrame.mail = MiniMapMailFrame:CreateFontString(nil, "OVERLAY")
MiniMapMailFrame.mail:SetFont(FONT, 16)
MiniMapMailFrame.mail:SetText("M")
MiniMapMailFrame.mail:SetJustifyH("CENTER")
MiniMapMailFrame.mail:SetPoint("CENTER", MiniMapMailFrame, "CENTER",1,-1)

MiniMapMailFrame:RegisterEvent("UPDATE_PENDING_MAIL")
MiniMapMailFrame:RegisterEvent("MAIL_INBOX_UPDATE")
MiniMapMailFrame:RegisterEvent("MAIL_CLOSED")

MiniMapMailBorder:Hide()


-- Handle TimeManager
if not IsAddOnLoaded("Blizzard_TimeManager") then
  LoadAddOn('Blizzard_TimeManager')
end
select(1, TimeManagerClockButton:GetRegions()):Hide()
TimeManagerClockButton:ClearAllPoints()
TimeManagerClockButton:SetPoint("BOTTOMLEFT", Minimap.background,"BOTTOMLEFT", 5, -2)
TimeManagerClockTicker:SetFont(FONT, 16,"OUTLINE")
TimeManagerClockTicker:SetAllPoints(TimeManagerClockButton)
TimeManagerClockTicker:SetJustifyH('LEFT')
TimeManagerClockTicker:SetShadowColor(0,0,0,0)


-- Alter click behavior
function dropdownOnClick(self)
  GameTooltip:Hide()
  DropDownList1:ClearAllPoints()
  DropDownList1:SetPoint('TOPLEFT', Minimap.background, 'TOPRIGHT', 2, 0)
end

Minimap:EnableMouseWheel(true)
Minimap:SetScript('OnMouseWheel', function(self, delta)
  if delta > 0 then
    MinimapZoomIn:Click()
  elseif delta < 0 then
    MinimapZoomOut:Click()
  end
end)

Minimap:SetScript('OnMouseUp', function (self, button)
  if button == 'RightButton' then
    ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, Minimap.background, (Minimap:GetWidth()), (Minimap.background:GetHeight()-2))
    GameTooltip:Hide()
  elseif button == 'MiddleButton' then
    if not IsAddOnLoaded("Blizzard_Calendar") then
      LoadAddOn('Blizzard_Calendar')
    end
    Calendar_Toggle()
  else
    Minimap_OnClick(self)
  end
end)


-- Quest log
--[[
  This is somewhat ugly. I don't understand how to correctly
  call hooksecurefunc for SetPoint against the tracker.
  Furthermore, I don't understand how it's positioned, and
  what does it (though it seems to happen many times)

  However, based on a forum post, I can get close. This
  solution will ALWAYS assume you want the tracker on the
  right of the screen and that your minimap will be below it.

  If we really wanna make this configurable, we'd have to
  take the approach Zork does and just directly reposition it
  via drag-n-drop. Flexible, but not programmatic.

  Relevant forum link:
    https://us.battle.net/forums/en/wow/topic/15141304174#2
--]]
local questlog_positioner = CreateFrame("Frame")
questlog_positioner:RegisterEvent("PLAYER_LOGIN")
questlog_positioner:SetScript("OnEvent",function(self, event, addon)
  if IsAddOnLoaded("Blizzard_ObjectiveTracker") then
    local tracker = ObjectiveTrackerFrame
    local anchor  = "TOPRIGHT"
    local ox = -10
    local oy = -10

    tracker:ClearAllPoints()
    tracker:SetPoint(anchor, Minimap, attach, ox, oy)
    
    hooksecurefunc(tracker, "SetPoint", function(self, a, rt, x, y)
      if a ~= anchor and x ~= ox and y ~= oy then
        --print(a, rt, x, y)
        self:SetPoint(anchor, UIParent, ox, -DEFAULT_SIZE + -DEFAULT_BUTTON_SIZE + oy)
      end
    end)

    self:UnregisterEvent("ADDON_LOADED")
  else
    self:RegisterEvent("ADDON_LOADED")
  end
end)
