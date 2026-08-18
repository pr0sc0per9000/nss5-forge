' TContractOffer.EraseInterestedClubs
' VA 0x00571dc9   48 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (48/48, original length from Ghidra's inventory)
' assumes module global:  Global g_profile:TProfile
' global 0x00c6f028 is a TProfile (fields 0x1a4/0x1a8/0x1bc), not TPlayer as inferred
' The name is g_profile, not g_contractoffer_tplayer: same slot (0x00C6F028), and the
' latter name encodes the disproved TPlayer guess and splits one Global into two in
' assembly. g_profile is what 6 other files call 0x00C6F028.

	Function EraseInterestedClubs:Int()
		'!Global g_profile:TProfile
		For Local i:Int = 0 To 4
			g_profile.interestedclubs[i] = 0
		Next
	End Function
