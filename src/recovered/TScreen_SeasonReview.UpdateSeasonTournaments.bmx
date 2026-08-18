' TScreen_SeasonReview.UpdateSeasonTournaments
' VA 0x005606C9   205 bytes
' byte-identical vs NSS5.exe (205/205, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_sr_table:TTable             ' 0x00C687D4
'!Global g_profile:TProfile
g_sr_table.ClearItems()
For Local h:THistory = EachIn g_profile.history
	If h.year = g_profile.date.GetYear() - 1
		g_sr_table.AddItem([h.text], "", "")
	End If
Next
