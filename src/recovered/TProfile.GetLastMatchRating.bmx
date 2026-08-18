' TProfile.GetLastMatchRating
' VA 0x00569c39   197 bytes   vtable slot 0x9c   sig (i)i
' byte-identical vs NSS5.exe (197/197, original length from Ghidra's inventory)
' ASSUMPTIONS: TProfile slot 0x90 = GetStats(i,i,i):TList (called with a0,0,0 -- Ghidra
' shows only one argument). The +0x4c field of TStats_Team is "form" (Int[]); the array
' header reads at +0x14/+0x18 in the decompilation are Length and element 0.
' FUN_005b9690 is _bbFloatToInt, i.e. the Int() truncation bcc emits, not a call to write.
' The divisor is a masked .data Float address; its VALUE is not proven.
' harness mode=reloc, 6 addresses masked.
	Method GetLastMatchRating:Int(a0:Int)
		Local l:TList = GetStats(a0, 0, 0)
		If l.IsEmpty() Then Return 5
		Local s:TStats_Team = TStats_Team(l.RemoveLast())
		If s.form.Length = 0
			If l.IsEmpty() Then Return 5
			s = TStats_Team(l.RemoveLast())
			If s.form.Length = 0 Then Return 5
		End If
		Return Int(s.form[s.form.Length - 1] / 10.0)
	End Method
