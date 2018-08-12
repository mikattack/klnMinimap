---------------------------------------------------------------------
-- XP/Reputation tracking bar
---------------------------------------------------------------------

local _, ns = ...
local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)

local FONT = LSM:Fetch(LSM.MediaType.FONT, "Roboto Bold Condensed")
local TEXTURE = LSM:Fetch(LSM.MediaType.STATUSBAR, "Flat")


local bar = CreateFrame("frame", "klnXP", UIParent)
bar:SetPoint("TOPLEFT", Minimap.background, "BOTTOMLEFT", 2, 0)
bar:SetPoint("BOTTOMRIGHT", Minimap.background, "BOTTOMRIGHT", -2, -20)
bar:SetFrameStrata("LOW")
bar:SetFrameLevel(6)
kln.frames.setBackdrop(bar)

-- Override 1px "border" because big'n'chunky looks good here
bar.background:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
bar.background:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2)

-- XP
bar.xp = CreateFrame('StatusBar', nil, bar)
bar.xp:SetAllPoints(bar)
bar.xp:SetStatusBarTexture(TEXTURE)
bar.xp:SetValue(0)

-- Rested
bar.rxp = CreateFrame('StatusBar', nil, bar)
bar.rxp:SetAllPoints(bar)
bar.rxp:SetStatusBarTexture(TEXTURE)
bar.rxp:SetValue(0)
bar.rxp:SetStatusBarColor(.2, .4, 0.8, 1)
bar.rxp:SetAlpha(0.4)
bar.rxp:Hide()

bar:SetScript("OnEnter", function() bar.xp.text:SetAlpha(1) end)
bar:SetScript("OnLeave", function() bar.xp.text:SetAlpha(0) end)

bar.bg = bar:CreateTexture("bg", 'BORDER')
bar.bg:SetAllPoints(bar)
bar.bg:SetTexture(TEXTURE)
bar.bg:SetVertexColor(0, 0, 0, 1)
    
bar.xp.text = bar.xp:CreateFontString("XP_Text")
bar.xp.text:SetAllPoints()
bar.xp.text:SetJustifyH("CENTER")
bar.xp.text:SetJustifyV("CENTER")
bar.xp.text:SetFont(FONT, 14, "OUTLINE")
bar.xp.text:SetAlpha(0)

bar:RegisterEvent("PLAYER_XP_UPDATE")
bar:RegisterEvent("PLAYER_LEVEL_UP")
bar:RegisterEvent("PLAYER_ENTERING_WORLD")
bar:RegisterEvent("UPDATE_FACTION")
bar:SetScript("OnEvent", function(self,event)
  xp  = UnitXP("player")
  mxp = UnitXPMax("player")
  rxp = GetXPExhaustion("player")
  name, standing, minrep, maxrep, value = GetWatchedFactionInfo()
  
  bar:Show()
  bar.xp:SetMinMaxValues(0,mxp)
  if UnitLevel("player") == MAX_PLAYER_LEVEL or IsXPUserDisabled == true then
    -- Show progress for a selected faction if at max level
    if name then
      local mx = 0.3
      local color = FACTION_BAR_COLORS[standing]
      bar.xp:SetStatusBarColor(color.r, color.g, color.b, 1)
      bar.xp:SetMinMaxValues(minrep,maxrep)
      bar.xp:SetValue(value)
      bar.xp.text:SetText(value-minrep.." / "..maxrep-minrep.." - "..floor(((value-minrep)/(maxrep-minrep))*1000)/10 .."% - ".. name)
      bar.bg:SetVertexColor(color.r * mx, color.g * mx, color.b * mx, 1)
    else
      bar:Hide()
    end
  else
    -- Show XP progress
    bar.xp:SetStatusBarColor(.4, .1, 0.6, 1)
    bar.xp:SetValue(xp)
    if rxp then
      bar.xp.text:SetText(kln.si(xp).." / "..kln.si(mxp).." - "..floor((xp / mxp)*1000)/10 .."%" .. " (+"..kln.si(rxp)..")")
      bar.xp:SetMinMaxValues(0,mxp)
      bar.rxp:SetMinMaxValues(0, mxp)
      bar.xp:SetStatusBarColor(.2, .4, 0.8, 1)
      bar.xp:SetValue(xp)
      if rxp + xp >= mxp then
        bar.rxp:SetValue(mxp)
      else
        bar.rxp:SetValue(xp + rxp)
      end
      bar.rxp:Show()
    elseif xp > 0 and mxp > 0 then
      bar.xp.text:SetText(kln.si(xp).." / "..kln.si(mxp).." - "..floor((xp/mxp)*1000)/10 .."%")
      bar.rxp:Hide()
    end
  end
end)
