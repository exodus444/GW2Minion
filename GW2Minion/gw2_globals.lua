local GetGameState = GetGameState
local BehaviorManager = BehaviorManager
local PvPManager = PvPManager
local Inventory = Inventory
local table = table
local GW2 = GW2

ml_global_information = ml_global_information or {}
ml_global_information.Path = GetStartupPath()
ml_global_information.Lasttick = -3000
ml_global_information.Running = false
ml_global_information.MAX_SKILLBAR_SLOTS = 20

ml_global_information.ConditionsEnum = {
	[736]		= "Bleeding",
	[720]		= "Blind",
	[737]		= "Burning",
	[722]		= "Chilled",
	[861]		= "Confusion",
	[721]		= "Crippled",
	[791]		= "Fear",
	[727]		= "Immobilized",
	[738]		= "Vulnerability",
	[742]		= "Weakness",
	[723]		= "Poison",
	[27705]		= "Taunt",
	[26766]		= "Slow",
	[19426]		= "Torment",
};

ml_global_information.BoonsEnum = {
	[743]		= "Aegis",
	[17675]		= "Aegis",
	[725]		= "Fury",
	[740]		= "Might",
	[717]		= "Protection",
	[1187]		= "Quickness",
	[718]		= "Regeneration",
	[17674]		= "Regeneration",
	[26980]		= "Resistance",
	[873]		= "Retaliation",
	[1122]		= "Stability",
	[719]		= "Swiftness",
	[726]		= "Vigor",
	[762]		= "Determined",
};

ml_global_information.SpeedBoons = {
	[719]		= "Swiftness",
	[5974]		= "Super Speed",
	[5543]		= "Mist form",
	[12542]		= "Signet of the Hunt",
	[13060]		= "Signet of Shadows",
	[5572]		= "Signet of Air",
	[10612]		= "Signet of the Locust",
	[33843]		= "Leader of the Pact I",
	[32675]		= "Leader of the Pact II",
	[33611]		= "Leader of the Pact III",
}

ml_global_information.SlowConditions = {
	[721]		= "Cripple",
	[722]		= "Chill",
	[18621]		= "Ichor",
}

ml_global_information.ImmobilizeConditions = {
	[727]		= "Immobilize",
	[791]		= "Fear",
	[872]		= "Stun",
	[833]		= "Daze",
	[27705]		= "Taunt",
	[15090]		= "Petrified 1",
	[16963]		= "Petrified 2",
	[25181]		= "Trapped",
	[37211]		= "Frostbite"
}

ml_global_information.InvulnerabilityConditions = {
	[762]		= "Determined",
	[895]		= "Determined (no icon)",
	[11641]		= "Determined (no icon)",
	[757]		= "Invulnerable",
	[903]		= "Righteous Indignation",
	[36143]		= "Destruction Immunity",
	[29065]		= "Tough Hide"
}

-- These are MapMarker - ContentIDs
ml_global_information.VendorSell = {
	GW2.MAPMARKER.Merchant,
	GW2.MAPMARKER.Armorsmith,
	GW2.MAPMARKER.Weaponsmith,
	GW2.MAPMARKER.Repair,
	GW2.MAPMARKER.ItzelVendor,
	GW2.MAPMARKER.ExaltedVendor,
	GW2.MAPMARKER.NuhochVendor,
	--305607,  -- Priory Historian Bandit Chest Seller (Vendors in forts do not have sell option)
	887588, -- Gathering Merchant
}

ml_global_information.VendorBuy = {
	GW2.MAPMARKER.Merchant,
	GW2.MAPMARKER.ItzelVendor,
	GW2.MAPMARKER.ExaltedVendor,
	GW2.MAPMARKER.NuhochVendor
}

ml_global_information.VendorRepair = {
	GW2.MAPMARKER.Repair
}

local mlgi = ml_global_information

-- Moved this here so it's easier to look at and easier to copy paste
function ml_global_information.OnUpdate(_,ticks)
	mlgi.GameState = GetGameState()

	if(TimeSince(mlgi.Lasttick) > BehaviorManager:GetTicksThreshold()) then
		mlgi.Lasttick = ticks

		local player = Player

		if Player then
			local gw2_datamanager = gw2_datamanager

			mlgi.Player_ID = player.id or 0
			mlgi.Player_Name = player.name or ""
			mlgi.Player_Health = player.health or { current = 0, max = 0, percent = 0 }
			mlgi.Player_Profession = player.profession or 0
			mlgi.Player_ProfessionName = table.invert(GW2.CHARCLASS)[mlgi.Player_Profession] or "NoClass"
			mlgi.Player_Power = player.power or 0
			mlgi.Player_Endurance = player.endurance or 0
			mlgi.Player_InCombat = player.incombat or false
			mlgi.Player_Position = player.pos
			mlgi.Player_Level = player.level
			mlgi.Player_OnMesh = player.onmesh or false
			mlgi.Player_Alive = player.alive or false
			mlgi.Player_IsMoving = player:IsMoving() or false
			mlgi.Player_CanMove = player:CanMove() or false
			mlgi.Player_MovementDirections = player:GetMovement() or { forward=false, backward=false, left=false, right=false }
			mlgi.Player_Inventory_SlotsFree = Inventory.freeslotcount or 0
			mlgi.Player_HealthState = player.healthstate or 0
			mlgi.Player_SwimState = player.swimming or 0
			mlgi.Player_MovementState = player:GetMovementState() or 1
			mlgi.Player_Party = player:GetParty() or nil
			mlgi.Player_CastInfo = player.castinfo or nil
			mlgi.Player_Buffs = player.buffs or {}
			mlgi.Player_InPVPMatch = PvPManager:IsInMatch()
			mlgi.Player_InPVPLobby = PvPManager:IsInPvPLobby()
			mlgi.Player_InPVPArea = mlgi.Player_InPVPMatch or mlgi.Player_InPVPLobby
			mlgi.CurrentMapID = player:GetLocalMapID() or 0

			if (gw2_datamanager and mlgi.CurrentMapID ~= 0) then
				mlgi.CurrentMapName = gw2_datamanager.GetMapName(mlgi.CurrentMapID)
			else
				mlgi.CurrentMapName = ""
			end

			mlgi.Player_CurrentWeaponSet = player:GetCurrentWeaponSet() or 0	-- 0 Aqua1, 1 Aqua2, 2 Engikit, 3 Necro Lich Form/ranger astralform,  4 Weapon1, 5 Weapon2
			mlgi.Player_TransformID = player:GetTransformID() or 0 -- 1-4 attunement, 5 deathshroud, 9 rangernormal, 10 rangerastralform
		end
	end
end
RegisterEventHandler("Gameloop.Draw", ml_global_information.OnUpdate, "ml_global_information.OnUpdate")

function ml_global_information.Start()
	gw2_unstuck.Start()
end

function ml_global_information.Stop()	
	Player:StopMovement() -- this function is overrwitten in gw2_navigation.lua (on the bottom). It stops the player, clearls the path and resets OMCs.
	gw2_unstuck.Stop()
end

-- Waits xxx seconds before running the next pulse
function ml_global_information.Wait( mseconds )
	BehaviorManager:SetLastTick( (BehaviorManager:GetLastTick()  or ml_global_information.Now) + mseconds )
end