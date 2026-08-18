' TScreen_Stats.UpdateHistoryTable
' VA 0x00552117   269 bytes   vtable slot 0x40
' byte-identical vs NSS5.exe (269/269, original length from Ghidra's inventory, mode=reloc)
'
' g_table:TTable is the Global at 0x00C679B8, g_profile:TProfile at 0x00C6F028.
' `_bbArrayNew1D("$",3)` followed by three stores at +0x18/+0x1c/+0x20 is the literal
' String array `[nm, s, h.text]` -- data begins at +0x18 (11.1).
	Function UpdateHistoryTable:Int()
		'!Global g_table:TTable
		'!Global g_profile:TProfile
		g_table.ClearItems()
		For Local h:THistory = EachIn g_profile.history
			Local s:String = String(h.year)
			Local nm:String = ""
			If h.clubid > 0 Then nm = TClub.SelectById(h.clubid).labelname
			If h.nationid > 0 Then nm = TNation.SelectById(h.nationid).labelname
			g_table.AddItem([nm, s, h.text], "", "")
		Next
	End Function
