local f = CreateFrame("FRAME")
local firstkill = 0
local lastkill = 0
local t = {}
local startmoney = 0
local endmoney = 0
local startvendorpricebag = 0
local lookupEvent = {}
local lookupParam = {}

-- convert total amount of money in unit copper to other units
local function ConvertToGold(totalCopper) return floor(abs(totalCopper/10000)) end
local function ConvertToSilver(totalCopper) return floor(abs(mod(totalCopper/100,100))) end
local function ConvertToCopper(totalCopper) return floor(abs(mod(totalCopper,100))) end



-- event functions
-- lookup[] =

-- Slash CMD functions
lookupParam["test"] = function()
	-- print("\124cffff9933Superverkaufomat 680\124r")
	-- print("Drachenodemchili")
	-- print("Scharfe Wolfrippchen")
	-- print("Eigenartiger Eintopf")
	-- print("Mageres Wolfsteak")
	-- print("")
	-- print("\124cffff9933Kaufotron 1000\124r")
	-- print("Schwerer Kodoeintopf")
	-- print("Mageres Wildbret")
end

local function GetPriceForItemsInBags()
-- iterate through bags, get the vendor price for each item and multiply by count of items
-- return value is in copper
	local result = 0
	for b=4,0,-1 do
		local numberOfSlots = GetContainerNumSlots(b)
		if numberOfSlots > 0 then
			for i=numberOfSlots,1,-1 do
				local itemID = GetContainerItemID(b,i)
				if itemID ~= nil then
					-- GetContainerItemInfo() returns: texture, itemCount, locked, quality, readable, lootable, itemLink1
					local itemCount = select(2, GetContainerItemInfo(b,i))
					-- GetItemInfo() returns: itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, invTexture, itemSellPrice
					local itemSellPrice = select(11, GetItemInfo(itemID))
					result = result + (itemSellPrice * itemCount)
				end
			end
		end
	end
	return result
end


SLASH_MOOFARM1 = "/moofarm";
function SlashCmdList.MOOFARM(msg, editbox)
    if msg == "" then print("\124cffff9933MooFarm Version: " .. GetAddOnMetadata("MooFarm", "Version") .. "\124r") end
	
	if msg == "reset" then
		firstkill, lastkill, t, startmoney, endmoney, startvendorpricebag = 0, 0, {}, GetMoney(), 0, GetPriceForItemsInBags()
		print("Zählerstand zurückgesetzt")
	end
	
	if msg == "show" then
		for k,v in pairs(t) do
			print(k..": "..v.." Kill(s)")
		end
		
		print("Zeit: "..floor((lastkill - firstkill)/60).." Minute(n)")
		
		local diffmoney = endmoney - startmoney
		if diffmoney < 0 then
			print("Noch kein Gold geplündert")
		else
			print("Geplündert: "..ConvertToGold(diffmoney).." Gold, "..ConvertToSilver(diffmoney).." Silber, "..ConvertToCopper(diffmoney).." Kupfer")
		end
		
		local diffvendor = GetPriceForItemsInBags() - startvendorpricebag
		if diffvendor < 0 then
			print("Noch kein Gold für den VendorPrice berechnet.")
		else
			print("Vendor Preis: "..ConvertToGold(diffvendor).." Gold, "..ConvertToSilver(diffvendor).." Silber, "..ConvertToCopper(diffvendor).." Kupfer")
		end

	end

	lookupParam[msg]()
end



-----------------------------------------------------------------------

local MooFarm_Frame = CreateFrame("Frame", "MooFarm_Frame", UIParent, "BasicFrameTemplateWithInset")
MooFarm_Frame:SetSize(300, 360) -- width, height
MooFarm_Frame:SetPoint("CENTER", UIParent, "RIGHT", -400, 0)

MooFarm_Frame.title = MooFarm_Frame:CreateFontString(nil, "OVERLAY")
MooFarm_Frame.title:SetFontObject("GameFontHighlight")
MooFarm_Frame.title:SetPoint("Left", MooFarm_Frame.TitleBg, "LEFT", 5, 0)
MooFarm_Frame.title:SetText("MooFarm")

MooFarm_Frame.showBtn = CreateFrame("Button", nil, MooFarm_Frame, "GameMenuButtonTemplate")
MooFarm_Frame.showBtn:SetPoint("CENTER", MooFarm_Frame, "TOP", 0, -70)
MooFarm_Frame.showBtn:SetSize(140, 40)
MooFarm_Frame.showBtn:SetText("Apply")
MooFarm_Frame.showBtn:SetNormalFontObject("GameFontNormalLarge")
MooFarm_Frame.showBtn:SetHighlightFontObject("GameFontHighlightLarge")

MooFarm_Frame.checkBtn = CreateFrame("CheckButton", nil, MooFarm_Frame, "UICheckButtonTemplate")
MooFarm_Frame.checkBtn:SetPoint("TOPLEFT", MooFarm_Frame.showBtn, "BOTTOMLEFT", 0, -20)
MooFarm_Frame.checkBtn.text:SetText("AutoRepair")

-----------------------------------------------------------------------

f:RegisterEvent("COMBAT_LOG_EVENT")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("LOOT_READY")


f:SetScript("OnEvent", function(self, event, ...)
	if event == "COMBAT_LOG_EVENT" then
		
		local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
		if subevent=="PARTY_KILL" and sourceName==GetUnitName("PLAYER") then
			if t[destName] == nil then
				t[destName] = 1
			else
				t[destName] = t[destName] + 1
			end

			if firstkill==0 and lastkill==0 then
				firstkill = timestamp
				lastkill = timestamp
			else
				lastkill = timestamp
			end			
		end
	end

	if event == "PLAYER_ENTERING_WORLD" then
		startmoney = GetMoney()
		startvendorpricebag = GetPriceForItemsInBags()
	end
	
	if event == "PLAYER_MONEY" then endmoney = GetMoney() end

	if event=="LOOT_READY" then
	end
	
	
	
	
	--local itemSellPrice = select(11, GetItemInfo(lootInfo[i].item))
	--print(itemSellPrice)
	-- mit loot ready event den von mir geplünderten loot table bauen
	-- dann anhand des tables einen get sell price and stack count ermittel und so den gesamten vendor preis
	-- print loot cmd
	-- print kills cmd
	-- print fish caught
	-- print money looted
	-- print vendor price for loot
	-- print time
	-- mooauction erstellen und dort alles zu auction query und sort rein


end)

