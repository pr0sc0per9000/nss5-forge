' TScreen_Roulette.IncreaseBet
' VA 0x00575027   175 bytes   vtable slot 0x40   sig (*i)i
' byte-identical vs NSS5.exe (175/175, original length from Ghidra's inventory, mode=reloc)
' Assumptions: a0 is an Int Ptr (sig *i), so the stake is read/written through a0[0].
'   The ladder is a Select, not If/ElseIf: all seven compares are emitted back to back
'   with every target past the last one (If/ElseIf comes out at 174 with interleaved
'   bodies). The subject must be the raw a0[0] expression, NOT a named Local -- with a
'   Local the subject and the result share a register (ebx) and the original keeps the
'   subject in eax.  Global 0x00C6F028 = TProfile (bank at +0x28).
'   PTR_FUN_00C6BBB0 = TScreen_Roulette classtable + 0x4c = sibling Function GetBetTotal().
'   PTR_FUN_00C61CC0 = TScreen classtable + 0x94 = TScreen.DoMessage($,i,i).
	Function IncreaseBet:Int(a0:Int Ptr)
		'!Global g_profile:TProfile
		Local b:Int
		Select a0[0]
			Case 0
				b = 50
			Case 50
				b = 100
			Case 100
				b = 250
			Case 250
				b = 500
			Case 500
				b = 1000
			Case 1000
				b = 2500
			Case 2500
				b = 5000
			Default
				Return 0
		End Select
		If GetBetTotal() > g_profile.bank
			TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"),0,0)
			Return 0
		Else
			a0[0] = b
		EndIf
	End Function
