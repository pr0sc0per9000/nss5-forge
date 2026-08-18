' TProfile.TooSoonSinceLastContract
' VA 0x0056ceeb   77 bytes   vtable slot 0x148   sig ()i
' byte-identical vs NSS5.exe (77/77, original length from Ghidra's inventory)
' assumes module global:  Global g_profile:TProfile
' the explicit Return True / Return False form is required (7 bytes shorter without it)
' renamed g_contractoffer_tplayer -> g_profile. Same slot (0x00C6F028), same
' type (TProfile -- this file's typing was the CORRECT side of the conflict); the old
' name encoded the disproved TPlayer guess and split one Global into two in assembly.
' g_profile is what 6 other files already call 0x00C6F028.

	Method TooSoonSinceLastContract:Int()
		'!Global g_profile:TProfile
		If date.sdate < 84 Or date.sdate < g_profile.lasttransferdate + 84
			Return True
		EndIf
		Return False
	End Method
