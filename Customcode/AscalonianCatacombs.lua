-- Custom Code for Ascalonian Catacombs Dungeon, meant to be played with 4-5 bots
dungeonAC = { }
dungeonAC.currentStep = 1

function dungeonAC.ModuleInit() 
	-- Registering our custom code within the wt_core_taskmanager.CustomLuaFunctions table in wt_core_taskmanager.lua	
	if (wt_core_taskmanager ~= nil and wt_core_taskmanager.CustomLuaFunctions ~= nil) then
		wt_debug("Adding Ascalonian Catacombs functions to list")
		table.insert(wt_core_taskmanager.CustomLuaFunctions,dungeonAC.OnUpdate)
	end
end

function dungeonAC.OnUpdate()	
	-- Here I would do conditional checks and add my Custom Tasks to wt_core_taskmanager.Customtask_list	
	if (Player:GetLocalMapID() == 33) then
		local mlist = MapMarkerList("isevent")
		if (mlist ~= nil) then	
			local i,event = next(mlist)
			if (i~=nil and event~=nil) then	
				wt_global_information.MaxAggroDistanceFar = 500
				--TODO: Add ReadyCheck
				if( event.eventID == 2606 and event.type == 159) then -- EventD = 1, charID=346					
					dungeonAC.Step1(event)
				elseif(event.eventID == 2607 and event.type == 159) then -- EventD = 0, charID=347					
					if ( dungeonAC.currentStep == 1 ) then
						dungeonAC.Step2OpenCoffins(event)						
					elseif ( dungeonAC.currentStep == 2) then
						dungeonAC.DeactivateTrap(event)
					elseif (dungeonAC.currentStep == 3 ) then
						dungeonAC.DeactivateTrap2(event)
					elseif (dungeonAC.currentStep == 4 ) then
						dungeonAC.OpenDoor(event)
					elseif (dungeonAC.currentStep == 5 ) then
						dungeonAC.KillGravelin(event)	
					elseif (dungeonAC.currentStep == 6 ) then
						dungeonAC.KillBoss(event)							
					end
				--elseif(event.eventID == 2605 and event.type == 163 event.C == 1) then
					
				end			
			end
		end
	end	
end


function dungeonAC.Step1(event)
	local newtask = inheritsFrom( wt_task )
    newtask.name = "AC Step1"
    newtask.priority = 50
    newtask.position = event.pos
    newtask.done = false
    newtask.last_execution = 0
    newtask.throttle = 500
	newtask.eventID = event.eventID
	newtask.NPC = event.characterID 
		 
    function newtask:execute()
        local mypos = Player.pos
        local distance =  Distance3D( newtask.position.x, newtask.position.y, newtask.position.z, mypos.x, mypos.y, mypos.z )
        if ( distance > 120 ) then                                             
			if ( (wt_global_information.Now - newtask.last_execution) > newtask.throttle ) then
                newtask.last_execution = wt_global_information.Now
				Player:MoveTo( newtask.position.x, newtask.position.y, newtask.position.z, 5 )                
            end
            newtask.name = "Walking to NPC, dist: "..(math.floor(distance))
        else
            if (CharacterList:Get(newtask.NPC) ~= nil ) then				
				if ( Player:GetTarget() ~= newtask.NPC) then
					Player:SetTarget(newtask.NPC)
				elseif(not Player:IsConversationOpen() ) then
					Player:Interact( newtask.NPC )
				elseif(Player:IsConversationOpen()) then
					local options = Player:GetConversationOptions()
					nextOption, entry  = next( options )
					local chosen = false
					while ( nextOption ~= nil and entry ~=nil) do
						if( entry == 13 ) then							
							Player:SelectConversationOption( 13 )
							chosen = true
							break
						elseif( entry == 6) then						
							Player:SelectConversationOption( 6 )
							chosen = true
							break
						end
						nextOption, entry  = next( options, nextOption )
					end
					if (chosen == false) then
						newtask.done = true
					end
				end
			end
            
        end
	end
		 
    function newtask:isFinished()
		if ( newtask.done ) then
			return true
		end
		return false
	end    

	wt_debug("AC Step1 Added..")
	wt_core_taskmanager:addCustomtask( newtask )
end

function dungeonAC.Step2OpenCoffins(event)
	local newtask = inheritsFrom( wt_task )
    newtask.name = "AC Step2 Coffins"
    newtask.priority = 500
    newtask.position = { x =-10568, y =-6930, z=-1950}
    newtask.done = false
    newtask.last_execution = 0	
    newtask.throttle = 500
	newtask.waitingTmr = 0
	newtask.MaxwaitingTmr = 5000
	newtask.eventID = event.eventID
	
    function newtask:execute()
        local target = nil
		local targetID = nil
		local gl = GadgetList("")
		if (gl ~= nil) then
			local i,g = next(gl)
			while (i~=nil and g~=nil) do
				if (g.health ~= nil and g.type == 14 and g.isselectable == 1 and g.distance < 5000) then
					target = g
					targetID = i
					break
				end			
				i,g = next(gl,i)
			end			
		end
		if (target ~= nil and target.pos ~= nil and targetID ~= nil) then
			newtask.waitingTmr = 0
			if ( target.distance > 120 ) then                                             
				if ( (wt_global_information.Now - newtask.last_execution) > newtask.throttle ) then
					newtask.last_execution = wt_global_information.Now
					local gpos = target.pos
					Player:MoveTo( gpos.x, gpos.y, gpos.z, 50 )                
				end
				newtask.name = "Walking to target, dist: "..(math.floor(target.distance))
			else
				if ( Player:GetTarget() ~= targetID ) then
					Player:SetTarget(targetID)
				else
					wt_debug("Opening target...")
					Player:Use(targetID)
					newtask.done = true
				end
			end
		else
			Player:MoveTo( newtask.position.x, newtask.position.y, newtask.position.z, 50 )
			local mypos = Player.pos
			local distance =  Distance3D( newtask.position.x, newtask.position.y, newtask.position.z, mypos.x, mypos.y, mypos.z )
			if ( distance < 150) then
				if ( newtask.waitingTmr == 0 ) then
					newtask.waitingTmr = wt_global_information.Now
				elseif ( newtask.waitingTmr ~= 0 and (wt_global_information.Now - newtask.waitingTmr) > newtask.MaxwaitingTmr ) then
					dungeonAC.currentStep = 2
					newtask.done = true
				end
			end
		end		
	end
		 
    function newtask:isFinished()
		if ( newtask.done ) then
			return true
		end
		return false
	end    

	wt_debug("AC Step2 opening coffins added..")
	wt_core_taskmanager:addCustomtask( newtask )
end

function dungeonAC.DeactivateTrap(event)
	local newtask = inheritsFrom( wt_task )
    newtask.name = "AC DeactivateTrap"
    newtask.priority = 500
    newtask.position = { x =-8877, y =-6361, z=-1787}
    newtask.done = false
    newtask.last_execution = 0
    newtask.throttle = 500
	newtask.eventID = event.eventID
	newtask.NPC = event.characterID 
		 
    function newtask:execute()
		local target = nil
		local targetID = nil
		local gl = GadgetList("")
		if (gl ~= nil) then
			local i,g = next(gl)
			while (i~=nil and g~=nil) do
				if (g.health == nil and g.type == 14 and g.isselectable == 1 and g.contentID == 89683 and g.los) then
					target = g
					targetID = i
					break
				end			
				i,g = next(gl,i)
			end			
		end
		if (target ~= nil and target.pos ~= nil and targetID ~= nil) then			
			if ( target.distance > 120 ) then                                             
				if ( (wt_global_information.Now - newtask.last_execution) > newtask.throttle ) then
					newtask.last_execution = wt_global_information.Now
					local gpos = target.pos
					Player:MoveTo( gpos.x, gpos.y, gpos.z, 5 )                
				end
				newtask.name = "Walking to Trap, dist: "..(math.floor(target.distance))
			else
				if ( Player:GetTarget() ~= targetID ) then
					Player:SetTarget(targetID)
				else
					wt_debug("Deactivating Trap...")
					Player:Use(targetID)
					newtask.done = true
				end
			end
		else
			Player:MoveTo( newtask.position.x, newtask.position.y, newtask.position.z, 50 )
			local mypos = Player.pos
			local distance =  Distance3D( newtask.position.x, newtask.position.y, newtask.position.z, mypos.x, mypos.y, mypos.z )
			if ( distance < 100) then
				dungeonAC.currentStep = 3
				newtask.done = true				
			end
		end		
	end
		 
    function newtask:isFinished()
		if ( newtask.done ) then
			return true
		end
		return false
	end    

	--Set correct Prio
	local target = nil
	local targetID = nil
	local gl = GadgetList("")
	if (gl ~= nil) then
		local i,g = next(gl)
		while (i~=nil and g~=nil) do
			if (g.health == nil and g.type == 14 and g.isselectable == 1 and g.contentID == 89683 and g.los) then
				target = g
				targetID = i
				break
			end			
			i,g = next(gl,i)
		end			
	end
	if (target ~= nil and target.pos ~= nil and targetID ~= nil) then	
		newtask.priority = 10500
	end
	
	wt_debug("AC DeactivateTrap Added..")
	wt_core_taskmanager:addCustomtask( newtask )
end

function dungeonAC.DeactivateTrap2(event)
	local newtask = inheritsFrom( wt_task )
    newtask.name = "AC DeactivateTrap2"
    newtask.priority = 500
    newtask.position = { x =-7661, y =-4261, z=-1885}
    newtask.done = false
    newtask.last_execution = 0
    newtask.throttle = 500
	newtask.eventID = event.eventID
	newtask.NPC = event.characterID 
		 
    function newtask:execute()
		local target = nil
		local targetID = nil
		local gl = GadgetList("")
		if (gl ~= nil) then
			local i,g = next(gl)
			while (i~=nil and g~=nil) do
				if (g.health == nil and g.type == 14 and g.isselectable == 1 and g.contentID == 89683 and g.los) then
					target = g
					targetID = i
					break
				end			
				i,g = next(gl,i)
			end			
		end
		if (target ~= nil and target.pos ~= nil and targetID ~= nil) then			
			if ( target.distance > 120 ) then                                             
				if ( (wt_global_information.Now - newtask.last_execution) > newtask.throttle ) then
					newtask.last_execution = wt_global_information.Now
					local gpos = target.pos
					Player:MoveTo( gpos.x, gpos.y, gpos.z, 5 )                
				end
				newtask.name = "Walking to Trap, dist: "..(math.floor(target.distance))
			else
				if ( Player:GetTarget() ~= targetID ) then
					Player:SetTarget(targetID)
				else
					wt_debug("Deactivating Trap...")
					Player:Use(targetID)
					newtask.done = true
				end
			end
		else
			Player:MoveTo( newtask.position.x, newtask.position.y, newtask.position.z, 50 )
			local mypos = Player.pos
			local distance =  Distance3D( newtask.position.x, newtask.position.y, newtask.position.z, mypos.x, mypos.y, mypos.z )
			if ( distance < 100) then
				dungeonAC.currentStep = 4
				newtask.done = true				
			end
		end		
	end
		 
    function newtask:isFinished()
		if ( newtask.done ) then
			return true
		end
		return false
	end    

	--Set correct Prio
	local target = nil
	local targetID = nil
	local gl = GadgetList("")
	if (gl ~= nil) then
		local i,g = next(gl)
		while (i~=nil and g~=nil) do
			if (g.health == nil and g.type == 7 and g.isselectable == 1 and g.contentID == 89683 and g.los) then
				target = g
				targetID = i
				break
			end			
			i,g = next(gl,i)
		end			
	end
	if (target ~= nil and target.pos ~= nil and targetID ~= nil) then	
		newtask.priority = 10500
	end
	
	wt_debug("AC DeactivateTrap2 Added..")
	wt_core_taskmanager:addCustomtask( newtask )
end

function dungeonAC.OpenDoor(event)
	local newtask = inheritsFrom( wt_task )
    newtask.name = "AC Open Door"
    newtask.priority = 500
    newtask.Boulderposition1 = { x =-7508, y =-4703, z=-1815}
	newtask.Boulderposition2 = { x =-8156, y =-4186, z=-1891}
	newtask.Platepos = { x =-6373, y =-6500, z=-1263}
    newtask.done = false
    newtask.last_execution = 0	
    newtask.throttle = 500
	newtask.waitingTmr = 0
	newtask.MaxwaitingTmr = 5000
	newtask.eventID = event.eventID
	
    function newtask:execute()		
		if (Player:GetSpellInfo(5).contentID == 206731) then
			--We have a boulder
			local mypos = Player.pos
			local distance =  Distance3D( newtask.Platepos.x, newtask.Platepos.y, newtask.Platepos.z, mypos.x, mypos.y, mypos.z )
			if ( distance < 15 ) then
				Player:SwapWeaponSet()
				dungeonAC.currentStep = 5
				newtask.done = true	
			elseif ( distance < 100 ) then
				Player:StopMoving()
				Player:Teleport(newtask.Platepos.x, newtask.Platepos.y, newtask.Platepos.z)							
			else
				Player:MoveTo( newtask.Platepos.x, newtask.Platepos.y, newtask.Platepos.z, 5 )
			end
		else
			--We need a boulder
			local mypos = Player.pos
			local distance =  Distance3D( newtask.Boulderposition1.x, newtask.Boulderposition1.y, newtask.Boulderposition1.z, mypos.x, mypos.y, mypos.z )
			if ( distance < 25 ) then
				local boulder = Player:GetInteractableTarget()
				if (boulder ~= nil and CharacterList:Get(boulder) == nil) then
					Player:PressF()					
				end
			else
				Player:MoveTo( newtask.Boulderposition1.x, newtask.Boulderposition1.y, newtask.Boulderposition1.z, 5 )
			end
		end
	end
		 
    function newtask:isFinished()
		if ( newtask.done ) then
			return true
		end
		return false
	end    

	wt_debug("AC Open Doors added..")
	wt_core_taskmanager:addCustomtask( newtask )
end

function dungeonAC.KillGravelin(event)
	local newtask = inheritsFrom( wt_task )
    newtask.name = "AC KillGravelin"
    newtask.priority = 500
    newtask.position = { x =-1897, y =-6828, z=-468}	
    newtask.done = false
    newtask.last_execution = 0	
    newtask.throttle = 500
	newtask.waitingTmr = 0
	newtask.MaxwaitingTmr = 5000
	newtask.eventID = event.eventID
	
    function newtask:execute()
       local target = nil
		local targetID = nil
		local gl = GadgetList("")
		if (gl ~= nil) then
			local i,g = next(gl)
			while (i~=nil and g~=nil) do
				if (g.health ~= nil and g.type == 1 ) then
					target = g
					targetID = i
					break
				end			
				i,g = next(gl,i)
			end			
		end
		if (target ~= nil and target.pos ~= nil and targetID ~= nil) then			
			if ( target.distance > 120 ) then                                             
				if ( (wt_global_information.Now - newtask.last_execution) > newtask.throttle ) then
					newtask.last_execution = wt_global_information.Now
					local gpos = target.pos
					Player:MoveTo( gpos.x, gpos.y, gpos.z, 5 )                
				end
				newtask.name = "Walking to Burrow, dist: "..(math.floor(target.distance))			
			end
		else
			Player:MoveTo( newtask.position.x, newtask.position.y, newtask.position.z, 50 )
			local mypos = Player.pos
			local distance =  Distance3D( newtask.position.x, newtask.position.y, newtask.position.z, mypos.x, mypos.y, mypos.z )
			if ( distance < 100) then
				dungeonAC.currentStep = 6
				newtask.done = true				
			end
		end		
	end
		 
    function newtask:isFinished()
		if ( newtask.done ) then
			return true
		end
		return false
	end    

	wt_debug("AC KillGravelin added..")
	wt_core_taskmanager:addCustomtask( newtask )
end

function dungeonAC.KillBoss(event)
	local newtask = inheritsFrom( wt_task )
    newtask.name = "AC KillBoss"
    newtask.priority = 500
    newtask.position = { x =1755, y =-5192, z=-1051}	
    newtask.done = false
    newtask.last_execution = 0	
    newtask.throttle = 500
	newtask.waitingTmr = 0
	newtask.MaxwaitingTmr = 5000
	newtask.eventID = event.eventID
	
    function newtask:execute()
		local mypos = Player.pos
        local distance =  Distance3D( newtask.position.x, newtask.position.y, newtask.position.z, mypos.x, mypos.y, mypos.z )
        if ( distance > 120 ) then                                             
			if ( (wt_global_information.Now - newtask.last_execution) > newtask.throttle ) then
                newtask.last_execution = wt_global_information.Now
				Player:MoveTo( newtask.position.x, newtask.position.y, newtask.position.z, 50 )                
            end
            newtask.name = "Walking to Boss, dist: "..(math.floor(distance))
		end
	end
		 
    function newtask:isFinished()
		if ( newtask.done ) then
			return true
		end
		return false
	end    

	wt_debug("AC KillBoss added..")
	wt_core_taskmanager:addCustomtask( newtask )
end


function dungeonAC.OpenChest(event)
	local newtask = inheritsFrom( wt_task )
    newtask.name = "AC OpenChest"
    newtask.priority = 500
    newtask.position = { x =3895, y =-2129, z=-1730}
    newtask.done = false
    newtask.last_execution = 0
    newtask.throttle = 500
	newtask.eventID = event.eventID
	newtask.NPC = event.characterID 
		 
    function newtask:execute()
		local target = nil
		local targetID = nil
		local gl = GadgetList("")
		if (gl ~= nil) then
			local i,g = next(gl)
			while (i~=nil and g~=nil) do
				if (g.health == nil and g.type == 2 and g.isselectable == 1) then
					target = g
					targetID = i
					break
				end			
				i,g = next(gl,i)
			end			
		end
		if (target ~= nil and target.pos ~= nil and targetID ~= nil) then			
			if ( target.distance > 120 ) then                                             
				if ( (wt_global_information.Now - newtask.last_execution) > newtask.throttle ) then
					newtask.last_execution = wt_global_information.Now
					local gpos = target.pos
					Player:MoveTo( gpos.x, gpos.y, gpos.z, 5 )                
				end
				newtask.name = "Walking to Chest, dist: "..(math.floor(target.distance))
			else
				if ( Player:GetTarget() ~= targetID ) then
					Player:SetTarget(targetID)
				else
					wt_debug("OpenChest ...")
					Player:Use(targetID)
					newtask.done = true
				end
			end
		else
			Player:MoveTo( newtask.position.x, newtask.position.y, newtask.position.z, 50 )
			local mypos = Player.pos
			local distance =  Distance3D( newtask.position.x, newtask.position.y, newtask.position.z, mypos.x, mypos.y, mypos.z )
			if ( distance < 100) then
				dungeonAC.currentStep = 8
				newtask.done = true				
			end
		end		
	end
		 
    function newtask:isFinished()
		if ( newtask.done ) then
			return true
		end
		return false
	end 
	wt_debug("AC OpenChest Added..")
	wt_core_taskmanager:addCustomtask( newtask )
end


RegisterEventHandler("Module.Initalize",dungeonAC.ModuleInit)