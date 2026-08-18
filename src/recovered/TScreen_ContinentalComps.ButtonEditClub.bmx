' TScreen_ContinentalComps.ButtonEditClub
' VA 0x005342D7   98 bytes
' byte-identical vs NSS5.exe (98/98, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_cc_table:TTable
Local id:Int = Int(g_cc_table.GetSelectedText(0))
LogLine("ButtonEditClub:" + id)
If id <> 0 Then TScreen_EditClubs.SetUpScreen(id, "continentalcomps")
