' TAchievement.WriteData
' VA 0x0058D4D3   263 bytes
' byte-identical vs NSS5.exe (263/263, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_achievements:TList
'!Global g_profile:TProfile
WriteLine(a0, "id~tsortindex~tdate")
For Local a:TAchievement = EachIn g_achievements
	If a.id > 0 Then
		Local s:String = String(a.id)
		s :+ "~t" + String(a.index)
		s :+ "~t" + String(g_profile.achievements[a.id - 1])
		WriteLine(a0, s)
	End If
Next
WriteLine(a0, "//")
