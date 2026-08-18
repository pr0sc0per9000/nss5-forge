' TEngine.ForcePositionResetAll
' VA 0x004d771c   76 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (76/76, original length from Ghidra's inventory)
' ASSUMPTION: module Globals at 0x00c5b218 / 0x00c5b21c declared :TTeam (load-bearing --
' selects slot 0x70 = UpdatePlayerDestinations and 0x84 = ForcePositionReset).
	Function ForcePositionResetAll()
		'!Global g_homeTeam:TTeam
		'!Global g_awayTeam:TTeam
		g_homeTeam.UpdatePlayerDestinations()
		g_awayTeam.UpdatePlayerDestinations()
		g_homeTeam.ForcePositionReset()
		g_awayTeam.ForcePositionReset()
	End Function
