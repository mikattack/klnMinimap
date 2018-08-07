---------------------------------------------------------------------
-- Make Order Hall bar display show only on mouseover
---------------------------------------------------------------------

-- UIFrameFadeIn(frame, timeToFade, startAlpha, endAlpha)
-- UIFrameFadeOut(frame, timeToFade, startAlpha, endAlpha)

local function onMouseOver(self)
  -- Instant fade-in, otherwise there's flickering when mousing
  -- over pictures or things underneath.
  UIFrameFadeIn(OrderHallCommandBar, 0.0, 0.0, 1.0)
end

local function onMouseLeave(self)  
  if OrderHallCommandBar:IsMouseOver() then
    UIFrameFadeOut(OrderHallCommandBar, 0.0, 1.0, 1.0)
  else
    UIFrameFadeOut(OrderHallCommandBar, 0.35, 1.0, 0)
  end
end


local OrderHallMouseOver = CreateFrame("Frame", "ohmo", UIParent)
OrderHallMouseOver:SetPoint("TOP", "UIParent", "TOP", 0, 0)
OrderHallMouseOver:SetSize(
   UIParent:GetWidth(),
  (UIParent:GetHeight() / 40)
)


OrderHallMouseOver:EnableMouse(true)
OrderHallMouseOver:SetScript("OnEnter", onMouseOver)
OrderHallMouseOver:SetScript("OnLeave", onMouseLeave)


OrderHallMouseOver:RegisterEvent("ADDON_LOADED")
OrderHallMouseOver:SetScript("OnEvent", function(self, event, addon)
  if addon == "Blizzard_OrderHallUI" then
    OrderHallCommandBar:EnableMouse(false)
    UIFrameFadeOut(OrderHallCommandBar, 0.0, 1.0, 0)
    OrderHallMouseOver:UnregisterAllEvents()
  end
end)
