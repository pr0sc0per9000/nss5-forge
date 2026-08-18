' TFixture.GetFirstLegScore
' VA 0x004C470E   211 bytes   vtable slot 0x50   sig (*i,*i)i
' byte-identical vs NSS5.exe (211/211, original length from Ghidra's inventory)
' The two `*i` parameters were verified through the harness as `Int Ptr` (a scalar Var
' compiles identically to a Ptr), hence the a0[0]/a1[0] spelling below; the original
' source almost certainly wrote `Var` parameters and plain assignment.
' The early-return form is load-bearing: `If leg = 2 Then ... EndIf` wrapping the whole
' body is 6 bytes short (0F 85 near-jne instead of 74 0A over a mov eax,0 / jmp end).
' TCompetition.SelectById resolved to TCompetition+0x4C on both sides.
' harness mode=reloc: absolute data/class-table addresses differ by construction; code identical.

	Method GetFirstLegScore:Int(a0:Int Ptr, a1:Int Ptr)
		If leg <> 2 Then Return 0
		Local c:TCompetition = TCompetition.SelectById(compid)
		For Local f:TFixture = EachIn c.lfixturelist
			If f.round = round And f.leg = 1 And f.hometeam = awayteam And f.awayteam = hometeam Then
				a0[0] = f.score1
				a1[0] = f.score2
			EndIf
		Next
	End Method
