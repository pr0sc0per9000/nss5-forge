' TScreen_BlackJack.Tie
' VA 0x00576b52   37 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (37/37, original length from Ghidra's inventory)
' Assumes two module Globals (original names unrecoverable):
'   g_profile:TProfile (0x00c6f028) -- type fixed by vtable slot 0xfc = TProfile.UpdateBank(i)i
'   g_stake:Int        (0x00c6b85c)
	Function Tie:Int()
		'!Global g_profile:TProfile
		'!Global g_stake:Int
		g_profile.UpdateBank(g_stake)
	End Function
