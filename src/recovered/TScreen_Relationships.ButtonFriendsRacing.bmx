' TScreen_Relationships.ButtonFriendsRacing
' VA 0x00540da5   160 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (160/160, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C6F028 = TProfile.  TProfile slot 0xc0 = UpdateRelationship(i,i),
'   slot 0x100 = UpdateEnergy(f).  PTR_FUN_00C6E23C = TScreen_Stable classtable + 0x34 =
'   TScreen_Stable.SetUpScreen(i).  ram0x00C876F8 is a float literal in .rdata; its value
'   is not byte-observable (masked fld operand), 20.0 is the natural reading of the
'   -20.0 energy spend that follows.
' NOTE ON THE GUARD: bcc emits the NEGATION of the source condition as the setcc, then
'   "jne" to SKIP the block. The original's "setae" therefore means the source wrote
'   "energy < 20.0"; writing "energy >= 20.0" with the arms swapped emits "setb" and is
'   a different 162-byte function.
	Function ButtonFriendsRacing:Int()
		'!Global g_profile:TProfile
		If g_profile.energy < 20.0
			TScreen.DoMessage(GetText("CMESSAGE_NORACINGTIRED"),0,0)
			Return 0
		EndIf
		g_profile.lastspendtimefriends = g_profile.date.sdate
		g_profile.UpdateRelationship(4,5)
		g_profile.UpdateEnergy(-20.0)
		TScreen_Stable.SetUpScreen(0)
	End Function
