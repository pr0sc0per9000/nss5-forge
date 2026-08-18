' TProfile.GetAverageForm
' VA 0x00569B04   309 bytes   vtable slot 0x98   sig (i,i,i)f
' byte-identical vs NSS5.exe (309/309, original length from Ghidra's inventory, mode=reloc)
' assumptions: slot 0x90 on TProfile is GetStats(i,i,i):TList and the downcast class table
' 0x00C6AC0C is TStats_Team, whose Field form:Int[] sits at +0x4C. TList slots 0x38=IsEmpty
' and 0x54=RemoveLast come from vtable_map.tsv. The three early returns each load a separate
' .rdata Float 5.0 (0x00C8E8D4 / D8 / DC -- bcc does not pool duplicate constants) and the
' final divisor at 0x00C8E8E4 is 10.0. The array is `New Int[5]`: bbArrayNew is called with
' the C type string "i" and 5.
'
' `s.form.Length = 0` reads [eax+0x14] (scales[0]), so the .Length spelling is required here
' -- the opposite of TCompetition.CreateTeamPool, which reads +0x10 (11.1).
' The /5 is INTEGER division (cdq/idiv) and only the quotient is widened (fild [ebp-4]),
' so the parentheses around it are load-bearing.
	Method GetAverageForm:Float(a0:Int, a1:Int, a2:Int)
		Local l:TList = Self.GetStats(a0, a1, 0)
		If l.IsEmpty() Then Return 5.0
		Local s:TStats_Team = TStats_Team(l.RemoveLast())
		If s.form.Length = 0
			If l.IsEmpty() Then Return 5.0
			s = TStats_Team(l.RemoveLast())
			If s.form.Length = 0 Then Return 5.0
		EndIf
		Local f:Int[] = New Int[5]
		For Local v:Int = EachIn s.form
			f[0] = f[1]
			f[1] = f[2]
			f[2] = f[3]
			f[3] = f[4]
			f[4] = v
		Next
		For Local i:Int = 0 To 4
			If f[i] = 0 Then f[i] = 60
		Next
		Return ((f[0] + f[1] + f[2] + f[3] + f[4]) / 5) / 10.0
	End Method
