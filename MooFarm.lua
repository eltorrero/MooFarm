local f = CreateFrame("FRAME")
local firstkill = 0
local lastkill = 0
local t = {}
local startmoney = 0
local endmoney = 0
local startvendorpricebag = 0

-- convert total amount of money in unit copper to other units
local function ConvertToGold(totalCopper) return floor(abs(totalCopper/10000)) end
local function ConvertToSilver(totalCopper) return floor(abs(mod(totalCopper/100,100))) end
local function ConvertToCopper(totalCopper) return floor(abs(mod(totalCopper,100))) end

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

local function MyAuctionQuery()
	-- query the item mouse is over in auction house
	-- Returns the name of the frame under the mouse, if it's named
	local frame = GetMouseFocus()
	if frame then
		local name = frame:GetName() -- or tostring(frame)
		local bagInd, itemInd = string.match(name, 'ContainerFrame(%d)Item(%d+)$')
		-- Frame name and GetContainerItemID zählen anders daher umrechnen
		bagInd = tonumber(bagInd)-1
		local numberOfSlots = GetContainerNumSlots(bagInd);
		itemInd = (numberOfSlots+1)-tonumber(itemInd)
		local itemID = GetContainerItemID(bagInd,itemInd)
		local itemName = select(1, GetItemInfo(itemID))
		print("QueryAuctionItems -> "..itemName)
		QueryAuctionItems(itemName)
	end
end

local function MyAuctionSort(reversed)
	-- clear any existing criteria
	SortAuctionClearSort("list")
	-- then, apply some criteria of our own
	SortAuctionSetSort("list", "buyout")
	SortAuctionSetSort("list", "quantity", reversed)
	-- apply the criteria to the server query
	SortAuctionApplySort("list")
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
	
	if msg=="query" then
		MyAuctionSort(false)
		MyAuctionQuery()
	end
	
	if msg=="queryreversed" then
		MyAuctionSort(true)
		MyAuctionQuery()
	end
	
	if msg=="priceperitem" then
		local index = GetSelectedAuctionItem("list")
		local aItemInfo = {GetAuctionItemInfo("list", index)}
		local aItemName = aItemInfo[1]
		local aItemCount = aItemInfo[3]
		local aItemBuyout = aItemInfo[10]
		print("1 x "..aItemName..": "..ConvertToGold(aItemBuyout/aItemCount).." Gold, "..ConvertToSilver(aItemBuyout/aItemCount).." Silber, "..ConvertToCopper(aItemBuyout/aItemCount).." Kupfer")
	end
	
	if msg=="test" then
		print(GetPriceForItemsInBags())
	end
end

f:RegisterEvent("COMBAT_LOG_EVENT")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

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
	
	if event == "PLAYER_MONEY" then endmoney = GetMoney(); print(select(1,...)); end

end)

