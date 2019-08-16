gw2_repair_manager = gw2_repair_manager or {}
gw2_repair_manager.damagedLimit = 4
gw2_repair_manager.brokenLimit = 1

gw2_repair_manager.lastVendorID = nil
gw2_repair_manager.VendorRepairHistroy = {}

function gw2_repair_manager.getClosestRepairMarker(nearby)
	local closestLocation = nil
	local listArg = (nearby == true and ",maxdistance=4000" or "")
	local markers = gw2_repair_manager.getMarkerList(listArg)
	if(table.valid(markers)) then
		for _,repair in pairs(markers) do
			if (closestLocation == nil or closestLocation.distance > repair.distance) then
				if (nearby == true and repair.pathdistance < 4000) then
					closestLocation = repair
				elseif (nearby ~= true) then
					closestLocation = repair
				end
			end
		end
	end
	return closestLocation
end


function gw2_repair_manager.getMarkerList(filter)
	filter = filter or ""
	local markers = MapMarkerList("onmesh,contentID="..GW2.MAPMARKER.Repair..filter..",exclude_characterid="..gw2_blacklistmanager.GetExcludeString(GetString("vendorsrepair")))
	if(table.valid(markers)) then
		return markers
	end
	
	return nil
end

function gw2_repair_manager.NeedToRepair(nearby)
	local damaged = 0
	local broken = 0
	for i=0,7 do 
		local equipedItem = Inventory:GetEquippedItemBySlot(i)
		if (equipedItem) then
			local durability = equipedItem.durability 
			if (durability == GW2.ITEMDURABILITY.Broken) then broken = broken + 1 damaged = damaged + 1 end
			if (durability == GW2.ITEMDURABILITY.Damaged) then damaged = damaged + 1 end
		end
	end
	
	if (nearby) then
		return broken > 0 or damaged > 0
	end
	
	return broken >= gw2_repair_manager.brokenLimit or damaged >= gw2_repair_manager.damagedLimit
end

function gw2_repair_manager.RepairAtVendor(repair)
	if (gw2_repair_manager.lastVendorID == nil or gw2_buy_manager.lastVendorID ~= repair.id ) then
		gw2_repair_manager.lastVendorID = repair.id
		gw2_repair_manager.VendorBuyHistroy = {}
		gw2_repair_manager.VendorBuyHistroy.interactcount = 0
	end
	
	if(gw2_repair_manager.VendorBuyHistroy.interactcount > 15) then
		d("Repair blacklisted: Tried interacting multiple times.")
		gw2_blacklistmanager.AddBlacklistEntry(GetString("Vendor repair"), repair.id, repair.name, true)			
	end
	
	if (Player:IsConversationOpen() == false) then
		ml_log("Opening Repair... ")
		Player:Interact(repair.id)
		gw2_repair_manager.VendorBuyHistroy.interactcount = gw2_repair_manager.VendorBuyHistroy.interactcount + 1
		ml_global_information.Wait(math.random(1500,1700))
		return true
	else
		local result = gw2_common_functions.handleConversation("repair")
		if (result == false) then
			d("Repair blacklisted: Can not handle conversation.")
			gw2_blacklistmanager.AddBlacklistEntry(GetString("Vendor repair"), repair.id, repair.name, true)
			return false
		end
		gw2_repair_manager.VendorBuyHistroy.interactcount = 0
		ml_global_information.Wait(math.random(520,1200))
		if(Player:IsConversationOpen()) then
			local options = Player:GetConversationOptions()
			local n_options = table.size(options)
			if(options and n_options > 0) then
				Player:SelectConversationOptionByIndex(n_options-1)
			end
		end
		
		return true
	end	
	return false
end