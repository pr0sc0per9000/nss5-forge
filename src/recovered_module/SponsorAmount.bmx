' SponsorAmount  -- module-level Function (no Type)
' VA 0x00507d1a   167 bytes   sig (i)i
' byte-identical vs NSS5.exe (167/167, original length from Ghidra's inventory, mode=reloc)
'
' NAME AND GLOBAL NAME ARE OURS. Returns the cash value of a sponsor tier, or 0 if the
' player already has a sponsorship running. Gates 2 workset functions.
'
' The guard reads the profile Global at 0x00C6F028 (typed TProfile in globals_final.tsv,
' type_source=construction, 3 sites) and tests element 0 of its `sponsor_amount:Int[]`
' field at +0xFC -- the array data starts at +0x18, so `[edx+0x18]` is `sponsor_amount[0]`.
'
' The tier table is a Select, not an If/ElseIf cascade: every Case compare is emitted back
' to back with all targets past the last one (section 10.2). There is no Default -- the
' no-match jmp lands on the `Return 0` that follows End Select.
'!Global g_profile:TProfile
	Function SponsorAmount:Int(a0:Int)
		If g_profile.sponsor_amount[0] > 0 Then Return 0
		Select a0
			Case 1
				Return 500
			Case 2
				Return 1000
			Case 3
				Return 1500
			Case 4
				Return 2000
			Case 5
				Return 2500
			Case 6
				Return 3000
			Case 7
				Return 4000
			Case 8
				Return 6000
			Case 9
				Return 8000
			Case 10
				Return 10000
		End Select
		Return 0
	End Function
