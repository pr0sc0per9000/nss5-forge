' TContractOffer.CheckClubCanAffordPlayer
' VA 0x00572e4d   250 bytes   vtable slot 0x68   sig (:TClub)i
' byte-identical vs NSS5.exe (250/250, original length from Ghidra's inventory, mode=reloc)
' Assumptions: module Global 0x00C6F028 is :TProfile (globals_final.tsv, high
' confidence, 3 construction sites). PTR_FUN_00C6B81C is TContractOffer + 0x64 =
' GetPlayerValueStatus(), a sibling Function so it is written unqualified.
' FUN_00505F90 is the verified module ClampFloat(*f,f,f) -- Var, so Varptr at the call.
' The literal at 0x00C8FC3C is a Float 15.0 read out of the image. a0.strength is
' inherited from TBase_Team.
' BOTH comparisons needed their operand order taken from the disassembly, not Ghidra:
'   `date.sdate > contractexpires`  (39 42 08 / 7E), one byte off the other way round
'   `a0.strength < f - 15.0` with the Return 0 branch FIRST (setae / jne)
	Function CheckClubCanAffordPlayer:Int(a0:TClub)
		'!Global g_profile:TProfile
		If g_profile.date.sdate > g_profile.contractexpires
			Return 1
		Else
			Local f:Float = GetPlayerValueStatus()
			ClampFloat(Varptr f,10.0,90.0)
			LogLine("Value:"+g_profile.GetValue())
			LogLine("Status:"+f)
			LogLine("ClubStrength:"+a0.strength)
			If a0.strength < f - 15.0
				Return 0
			Else
				Return 1
			EndIf
		EndIf
	End Function
